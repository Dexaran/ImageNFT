# Non-Fungible Tokens for image collectibles

This repo provides the reference codes for implementation of NFT smart-contracts that govern the behavior of collectible units.

This contracts represent a set of NFTs that contain recorded data in JSON format on-chain. NFTs can be grouped in "classes" to refer to class-related metadata which is shared among the NFTs belonging to one class (this optimizes on-chain data usage). User can also record his own metadata in text format to his owned NFT.

Owner of the contract can create new classes at the contract and assign them to an Auction. Auctions sell NFTs according to the chosen rules. There can be two types of auctions - Linear and Biddable.

Linear auctions allow users to buy NFTs at a fixed price stright from the contract.

Biddable auctions allow users to bid on NFTs and the highest bid wins after fixed time period.

# Structure

- [ImagesNFT.sol](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFT.sol) - this is an old version of the contract. It is kept for documentation purposes and it will be removed in the future

- [ImagesNFTv2.sol](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol) - this is a relevant implementation based on [CallistoNFT](https://github.com/Dexaran/CallistoNFT) and [Classified CallistoNFT](https://github.com/Dexaran/CallistoNFT/blob/main/Extensions/ClassifiedNFT.sol) extension.

- [Proxy.sol](https://github.com/Dexaran/ImageNFT/blob/main/Proxy.sol) - upgradeable proxy to keep contracts upgradeable during the development process.

# Deployment (contracts)

Solidity version 0.8.0. These contracts are designed to work with Ethereum Virtual Machine and therefore the contracts can be compiled and deployed to any chain that supports EVM including Binance Smart Chain, Ethereum CLassic, TRX, Callisto Network, PIRL etc.

Deployment process must be as follows:

1. Pick a contract and compile it (ImagesNFTv2.sol) - the relevant contract is [contract ArtefinNFT](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1011-L1064). Deploy the bytecode of the contract to a desired network (mainnet or testnet).
2. Compile the Proxy.sol - the relevant contract is [NFTUpgradeableProxy](https://github.com/Dexaran/ImageNFT/blob/main/Proxy.sol#L458-L463)
3. Deploy the compiled Proxy contract and assign constructor parameters - `admin` is the owner address, `logic` is the address of the ImagesNFTv2 contract created at step 1, `data` is a special value that encodes the initialization call, data must be `b119490e000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000074172746566696e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034152540000000000000000000000000000000000000000000000000000000000` in case of this particular contracts. The proxy contract automatically calls [initialize()](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1013-L1022) upon creation.

# Deployment (auctions)

1. Replace the [hardcoded address of the revenue receiver](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1241) with your address.
2. Compile [Linear Auction code](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1081) or [Biddable Auction code](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1201)
3. Deploy the compiled code to the desired network.
4. `Auction contract:` Configure the NFT contract with the [setNFTContract](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1261-L1266) function.
5. `NFT contract:` In order to be allowed to create NFTs the auction contract must be assigned the "Minter Role". Assign the minter permissions to the Auction contract address created at step 3 with the [setMinterRole](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L131-L134) function at the NFT contract.
6. `NFT contract:` Create a new NFT class that will represent a group of assets that can be sold at the auction contract with [addNewTokenClass()](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L933) function at the NFT contract.
7. `NFT contract:` (OPTIONAL) Assign class properties with [addTokenClassProperties](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L939) function.
8. `NFT contract:` (OPTIONAL) Configure the content of token properties with the [modifyClassProperty](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L947) function. NOTE: Properties can not be removed in the current implementation of the contract. However the owner can `modify` a token property to make it empty.
9. `Auction contract:` Assign a new auction at the auction contract with the [createNFTAuction](https://github.com/Dexaran/ImageNFT/blob/main/ImagesNFTv2.sol#L1111) function. `uint256 _classID` parameter must be the ID of created class at the auction contract. Auction can only sell assets of a created class. NOTE: One class can be only assigned to one type of auction. This contracts are not designed to allow one class of NFTs to be tradeable on multiple auctions at the same time.
