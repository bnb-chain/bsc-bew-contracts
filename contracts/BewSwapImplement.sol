pragma solidity ^0.8.0;

import "./interfaces/IUniRouter.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";

contract BewSwap is Context, ReentrancyGuard, Initializable {

    using SafeERC20 for IERC20;

    uint256 public constant feePctScale = 1e6;

    uint256 private _feePct;

    address private _owner;
    address private _pendingOwner;

    address payable private _feeAccount;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);
    event FeePctUpdated(uint256 indexed previousFeePct, uint256 indexed newFeePct);
    event FeeAccountUpdated(address indexed previousFeeAccount, address indexed newFeeAccount);
    event FeeReceived(address indexed token, uint256 indexed amount);


    constructor() public {
    }



    function initialize(address owner, address payable feeAccount, uint256 feePct) external initializer {
        require(feePct <= feePctScale, "BewSwap: fee pct is larger than fee pct scale");
        require(owner != address(0), "BewSwap: owner is the zero address");
        require(feeAccount != address(0), "BewSwap: fee account is the zero address");

        _owner = owner;
        _feePct = feePct;
        _feeAccount = feeAccount;

        emit OwnershipTransferred(address(0), owner);
        emit FeePctUpdated(0, feePct);
        emit FeeAccountUpdated(address(0), feeAccount);
    }


    fallback() external payable {}

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "BewSwap: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "BewSwap: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _pendingOwner = newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == _pendingOwner, "BewSwap: invalid new owner");
        emit OwnershipAccepted(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    function feePct() external view returns (uint256) {
        return _feePct;
    }

    function updateFeePct(uint256 newFeePct) external onlyOwner {
        require(newFeePct != _feePct, "BewSwap: new fee pct is the same as the current fee pct");
        require(newFeePct <= feePctScale, "BewSwap: new fee pct should larger than fee pct scale");
        emit FeePctUpdated(_feePct, newFeePct);
        _feePct = newFeePct;
    }

    function feeAccount() external view returns (address) {
        return _feeAccount;
    }

    function updateFeeAccount(address payable newFeeAccount) external onlyOwner {
        require(newFeeAccount != address(0), "BewSwap: new fee account is the zero address");
        require(newFeeAccount != _feeAccount, "BewSwap: new fee account is the same as current fee account");

        emit FeeAccountUpdated(_feeAccount, newFeeAccount);
        _feeAccount = newFeeAccount;
    }

    function swapExactTokensForTokens(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);

        IERC20 toToken = IERC20(path[path.length-1]);
        uint256 toTokenBalance = toToken.balanceOf(address(this));
        require(toTokenBalance >= amountOutMin, "BewSwap: get less to tokens than expected");

        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        toToken.safeTransfer(to, remainAmount);
        if (feeAmount != 0) {
            toToken.safeTransfer(_feeAccount, feeAmount);
            emit FeeReceived(address(toToken), feeAmount);
        }
    }

    function swapTokensForExactTokens(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);

        router.swapTokensForExactTokens(amountInMax, amountOut, path, address(this), deadline);

        IERC20 toToken = IERC20(path[path.length-1]);
        uint256 toTokenBalance = toToken.balanceOf(address(this));
        require(toTokenBalance >= amountOut, "BewSwap: get less to tokens than expected");

        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        toToken.safeTransfer(to, remainAmount);
        if (feeAmount != 0) {
            toToken.safeTransfer( _feeAccount, feeAmount);
            emit FeeReceived(address(toToken), feeAmount);
        }

        // return remain from tokens
        uint256 fromTokenBalance = fromToken.balanceOf(address(this));
        if (fromTokenBalance != 0) {
            fromToken.safeTransfer(to, fromTokenBalance);
        }
    }

    function swapExactETHForTokens(
        IUniRouter router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable nonReentrant {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(amountOutMin, path, address(this), deadline);

        IERC20 toToken = IERC20(path[path.length-1]);
        uint256 toTokenBalance = toToken.balanceOf(address(this));
        require(toTokenBalance >= amountOutMin, "BewSwap: get less to tokens than expected");

        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        toToken.safeTransfer(to, remainAmount);
        if (feeAmount != 0) {
            toToken.safeTransfer(_feeAccount, feeAmount);
            emit FeeReceived(address(toToken), feeAmount);
        }
    }

    function swapTokensForExactETH(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address payable to, uint deadline
    ) external nonReentrant {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);

        router.swapTokensForExactETH(amountOut, amountInMax, path, address(this), deadline);

        uint256 ethBalance = address(this).balance;
        require(ethBalance >= amountOut, "BewSwap: get less eth than expected");

        uint256 feeAmount = (ethBalance * _feePct) / feePctScale;
        uint256 remainAmount = ethBalance - feeAmount;

        // charge fee and transfer balance to to address
        _safeTransferETH(to, remainAmount);
        if (feeAmount != 0) {
            _safeTransferETH(_feeAccount, feeAmount);
            emit FeeReceived(address(0), feeAmount);
        }

        // return remain from tokens
        uint256 fromTokenBalance = fromToken.balanceOf(address(this));
        if (fromTokenBalance != 0) {
            fromToken.safeTransfer(to, fromTokenBalance);
        }
    }

    function swapExactTokensForETH(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external nonReentrant {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);

        uint256 ethBalance = address(this).balance;
        require(ethBalance >= amountOutMin, "BewSwap: get less eth than expected");

        uint256 feeAmount = (ethBalance * _feePct) / feePctScale;
        uint256 remainAmount = ethBalance - feeAmount;

        // charge fee and transfer balance to to address
        _safeTransferETH(to, remainAmount);
        if (feeAmount != 0) {
            _safeTransferETH(_feeAccount, feeAmount);
            emit FeeReceived(address(0), feeAmount);
        }
    }

    function swapETHForExactTokens(
        IUniRouter router,
        uint amountOut,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external payable nonReentrant {
        router.swapETHForExactTokens{value: msg.value}(amountOut, path, address(this), deadline);

        IERC20 toToken = IERC20(path[path.length-1]);
        uint256 toTokenBalance = toToken.balanceOf(address(this));
        require(toTokenBalance >= amountOut, "BewSwap: get less to tokens than expected");

        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        if (feeAmount != 0) {
            toToken.safeTransfer(_feeAccount, feeAmount);
            emit FeeReceived(address(0), feeAmount);
        }
        toToken.safeTransfer(to, remainAmount);

        // return remain eth
        uint256 ethBalance = address(this).balance;
        if (ethBalance != 0) {
            _safeTransferETH(to, ethBalance);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "BewSwap: transfer eth failed");
    }
}