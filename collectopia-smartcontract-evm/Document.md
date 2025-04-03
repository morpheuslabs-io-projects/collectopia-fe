# GOYA Special Collection and Sale Contracts

There are two contracts:
- `SpecialCollection`: the ERC-721 contract that handles:
    + Mint/Burn NFT using ERC-721 standard
    + Manage NFT's ownership
    + Transferable NFTs
    + Metadata accessibility via `tokenURI`
- `Sale`: handles sale events for multiple `Original NFT` concurrently

### Special Collection Contract

- Using `Ownable.sol` from Openzeppelin. This interface supports Royalty Fee can be set/adjusted on Opensea, Looksrare, Rarible, etc
- This contract has ONLY one `Owner` who has ability to:
    + Create and mint Original NFT. Original NFTs will be transferred to the Collection's Owner
    + Update a new `baseURI` for each of Original NFTs and its fragments
    + Set Minter role
    + Pause/Unpause (halt/unhalt on-chain operations)
    + Burn NFTs of others
    + Transfer Collection ownership to another address
- `tokenId` convention:
    + Original NFT can be assigned any numbers as `tokenId`, i.e. `tokenId = 10`, `tokenId = 12345`
    + Fragment NFTs must follow pre-defined convention: `original_token_id` + `row` (3 digits) + `column` (3 digits)
        - Example: `FragmentId = 19_001_999` -> `original_token_id = 19`, `row = 001` and `col = 999`
    + When Collection's Owner creates Original NFT, he/she must specify `numOfRow` and `numOfCol` of a fragmentation
- Each of Original NFTs and its fragments will share one `baseURI`
    + Example: `baseURI(original_token_id) = https://example.com/collection/original_nft_{#}/`
    + `original_token_id = 100` -> `tokenURI = https://example.com/collection/original_nft_#100/100`
    + `fragment_id = 100123012` -> `tokenURI = https://example.com/collection/original_nft_#100/100123012`
- `baseURI` can be updated independently.
- Only Minter role has authority to mint fragments. Minter role is an address:
    + External Owned Account (EOA)
    + Smart Contract (e.g. `Sale` contract)

### Sale Contract

- Using `Ownable.sol` from Openzeppelin. This contract also has ONLY one `Owner` who has ability to:
    + Set `Treasury` wallet to receive payments. This wallet could be:
        - External Owned Account (EOA)
        - Smart Contract (i.e. multi-sig or payment splitter)
    + Create Sale Event for each of Original NFTs 
        - One sale event per Original NFT 
        - Multiple events can be running concurrently
        - Sale event has no start/end time. Thus, `Owner` has an authority to terminate any events at any time
        - Terminated events can be re-opened
        - Each of Sale Events can be assigned different payment tokens
            + Example: `sale_id = 1` is configured `payment_token = ETH` and `fixed_price = 0.5 ETH`
            + `sale_id = 2` is configured `payment_token = USDT` and `fixed_price = 2,500 USDT`
        - `sale_id` is `token_id` of `Original NFT`
- Has a function to check `fixed_price` of a fragment
    + If `fragment_id` is not valid -> return `error_message`
    + If `fragment_id` is valid, but 
        - A sale has been terminated -> return `error_message`
        - A sale not yet created -> return `error_message`
    + If items have been sold -> return `error_message`
- Handle purchase fragment NFTs
    + Buyer sends a request to purchase a fragment -> specify `fragment_id`
    + Validate `fragment_id` -> check price -> return `fixed_price`
    + Make payment -> payment is transferred to `Treasury`
    + Call `SpecialCollection` to mint a fragment
    + Mark `fragment_id` as `sold`
    + Emit an event to finalize a request


<!-- 
npx hardhat verify 0x43389A4B0AD7Aa52FEc7145e053bC0E043e5aeB1  0x4398c86C2c4a954dFCEa9BCb1673Ac1Bede9D25F FRAGMENT FRAG  --network testnet

npx hardhat verify 0x3811EcFB648e22f0D0189a8E34BB46208045FD65  0x43389A4B0AD7Aa52FEc7145e053bC0E043e5aeB1 0x4398c86C2c4a954dFCEa9BCb1673Ac1Bede9D25F 0x4398c86C2c4a954dFCEa9BCb1673Ac1Bede9D25F  --network testnet


// COntract sales
https://mumbai.polygonscan.com/address/0x3811EcFB648e22f0D0189a8E34BB46208045FD65#code

// contract collection 
https://mumbai.polygonscan.com/address/0x43389A4B0AD7Aa52FEc7145e053bC0E043e5aeB1#code
-->
