# Non-Fungible Tokens for image collectibles

This repo provides the reference codes for implementation of NFT smart-contracts that govern the behavior of collectible units.

# Structure

- [ImagesNFT.sol](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFT.sol) - this is an old version of the contract. It is kept for documentation purposes and it will be removed in the future

- [ImagesNFTv2.sol](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol) - this is a relevant implementation based on [CallistoNFT](https://github.com/Dexaran/CallistoNFT) and [Classified CallistoNFT](https://github.com/Dexaran/CallistoNFT/blob/main/Extensions/ClassifiedNFT.sol) extension.

- [Proxy.sol](https://github.com/Dexaran/ImageNFT/blob/main/Proxy.sol) - upgradeable proxy to keep contracts upgradeable during the development process.

# Deployment

Solidity version 0.8.0. These contracts are designed to work with Ethereum Virtual Machine and therefore the contracts can be compiled and deployed to any chain that supports EVM including Binance Smart Chain, Ethereum CLassic, TRX, Callisto Network, PIRL etc.

Deployment process must be as follows:

1. Pick a contract and compile it (ImagesNFTv2.sol) - the relevant contract is [contract ArtefinNFT](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1011-L1064). Deploy the bytecode of the contract to a desired network (mainnet or testnet).
2. Compile the Proxy.sol - the relevant contract is [NFTUpgradeableProxy](https://github.com/Dexaran/ImageNFT/blob/main/Proxy.sol#L458-L463)
3. Deploy the compiled Proxy contract and assign constructor parameters - `admin` is the owner address, `logic` is the address of the ImagesNFTv2 contract created at step 1, `data` is a special value that encodes the initialization call, data must be `b119490e000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000074172746566696e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034152540000000000000000000000000000000000000000000000000000000000` in case of this particular contracts. The proxy contract automatically calls [initialize()](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1013-L1022) upon creation.
