
mythril:
	npm run flatten
	docker pull mythril/myth
	docker run -v $(shell pwd):/tmp mythril/myth analyze /tmp/contracts/flattened/BewSwap.sol --solv 0.6.4