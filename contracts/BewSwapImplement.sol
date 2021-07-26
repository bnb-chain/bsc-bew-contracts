pragma solidity ^0.8.0;

import "./interfaces/IUniRouter.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";

contract BewSwap is Context, Initializable {

    using SafeERC20 for IERC20;

    uint256 constant feePctScale = 1e6;

    uint256 private _feePct;

    address private _owner;

    address payable private _feeAccount;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeePctUpdated(uint256 indexed previousFeePct, uint256 indexed newFeePct);
    event FeeAccountUpdated(address indexed previousFeeAccount, address indexed newFeeAccount);


    constructor() public {
    }



    function initialize(address owner, address payable feeAccount, uint256 feePct) public initializer {
        _owner = owner;
        _feePct = feePct;
        _feeAccount = feeAccount;

        emit OwnershipTransferred(address(0), owner);
        emit FeePctUpdated(0, feePct);
        emit FeeAccountUpdated(address(0), feeAccount);
    }


    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "BewSwap: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "BewSwap: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function feePct() public view returns (uint256) {
        return _feePct;
    }

    function updateFeePct(uint256 newFeePct) public onlyOwner {
        require(newFeePct != _feePct, "BewSwap: new fee pct is the same as the current fee pct");
        emit FeePctUpdated(_feePct, newFeePct);
        _feePct = newFeePct;
    }

    function feeAccount() public view returns (address) {
        return _feeAccount;
    }

    function updateFeeAccount(address payable newFeeAccount) public onlyOwner {
        require(newFeeAccount != address(0), "BewSwap: new fee account is the zero address");
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
        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        toToken.safeTransfer(_feeAccount, feeAmount);
        toToken.safeTransfer(to, remainAmount);
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
        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        toToken.safeTransfer( _feeAccount, feeAmount);
        toToken.safeTransfer(to, remainAmount);

        // return remain from tokens
        uint256 fromTokenBalance = fromToken.balanceOf(address(this));
        fromToken.safeTransfer(to, fromTokenBalance);
    }

    function swapExactETHForTokens(
        IUniRouter router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(amountOutMin, path, address(this), deadline);

        IERC20 toToken = IERC20(path[path.length-1]);
        uint256 toTokenBalance = toToken.balanceOf(address(this));
        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        toToken.safeTransfer(_feeAccount, feeAmount);
        toToken.safeTransfer(to, remainAmount);
    }

    function swapTokensForExactETH(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address payable to, uint deadline
    ) external {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);

        router.swapTokensForExactETH(amountOut, amountInMax, path, address(this), deadline);

        uint256 ethBalance = address(this).balance;
        uint256 feeAmount = (ethBalance * _feePct) / feePctScale;
        uint256 remainAmount = ethBalance - feeAmount;

        // charge fee and transfer balance to to address
        _feeAccount.transfer(feeAmount);
        to.transfer(remainAmount);

        // return remain from tokens
        uint256 fromTokenBalance = fromToken.balanceOf(address(this));
        fromToken.safeTransfer(to, fromTokenBalance);
    }

    function swapExactTokensForETH(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);

        uint256 ethBalance = address(this).balance;
        uint256 feeAmount = (ethBalance * _feePct) / feePctScale;
        uint256 remainAmount = ethBalance - feeAmount;

        // charge fee and transfer balance to to address
        _feeAccount.transfer(feeAmount);
        to.transfer(remainAmount);
    }

    function swapETHForExactTokens(
        IUniRouter router,
        uint amountOut,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external payable {
        router.swapETHForExactTokens{value: msg.value}(amountOut, path, address(this), deadline);

        IERC20 toToken = IERC20(path[path.length-1]);
        uint256 toTokenBalance = toToken.balanceOf(address(this));
        uint256 feeAmount = (toTokenBalance * _feePct) / feePctScale;
        uint256 remainAmount = toTokenBalance - feeAmount;

        // charge fee and transfer balance to to address
        toToken.safeTransfer(_feeAccount, feeAmount);
        toToken.safeTransfer(to, remainAmount);

        // return remain eth
        uint256 ethBalance = address(this).balance;
        to.transfer(ethBalance);
    }
}