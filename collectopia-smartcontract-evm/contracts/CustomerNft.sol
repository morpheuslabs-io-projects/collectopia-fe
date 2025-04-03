// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./INFT.sol";

contract CustomerNft is ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {
    
    // Address of the account allowed to mint new tokens
    address public minter;

    uint256 public nextTokenId;

    // Base URI for token metadata
    string baseURI;


    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        uint96 royaltyPercentage
    )
        ERC721(name, symbol)
    {   

        nextTokenId = 1;

        transferOwnership(initialOwner);
        minter = initialOwner;
        _setDefaultRoyalty(royaltyReceiver, royaltyPercentage);
    }

    // Timeout period for minting after a certain block number
    uint256 private constant TIME_OUT_AFTER_BLOCKS = 50;

    /**
     * @dev Modifier to restrict access to functions only for the minter or owner.
     */
    modifier onlyMinter(){
        require(msg.sender == minter || msg.sender == owner(), "Only minter can execute this");
        _;
    }

    // Event emitted when the minter is updated
    event EventUpdateMinter(address oldMinter, address newMinter);

    // Event emitted when the default royalty is set
    event SetDefaultRoyaltyEvent(address receiver, uint96 feeNumerator);

    // Event emitted when the token royalty is set
    event SetRoyaltyEvent(uint256 tokenId, address receiver, uint96 feeNumerator);

    // Event emitted when batch mint new NFT series
    event BatchSafeMintEvent(address beneficiary, uint256 quantity);

    /**
     * @dev Allows the owner to update the minter address.
     * @param _minter The new minter address.
     */
    function updateMinter(address _minter) external onlyOwner(){
        emit EventUpdateMinter(minter, _minter);
        minter = _minter;
    }

    /**
     * @dev Returns the current minter address.
     */
    function getMinter() external view returns (address){
        return minter;
    }

    /**
     * @dev Safely mints a new token to a specified address.
     * @param _to The address to receive the minted token.
     */
    function safeMint(address _to)
        public
        nonReentrant
        onlyMinter
    {
        _mintNft(_to);
    }

    /**
     * @dev Safely batch mints a new token to a specified address.
     * @param _to The address to receive the minted token.
     */
    function batchSafeMint(address _to, uint256 _quantity)
        public
        nonReentrant
        onlyMinter
        
    {
        uint256 i = 0;
        for (i; i < _quantity; i++){
            _mintNft(_to);
        }
        
    }


    /**
     * @dev Internal function to mint a new cover NFT.
     * @param _to The address to receive the minted token.
     */
    function _mintNft(address _to) internal {
        uint256 _tokenId = nextTokenId;
        _safeMint(_to, _tokenId);
        nextTokenId = nextTokenId + 1;
    }

    /**
     * @dev Allows the owner to set the base URI for token metadata.
     * @param _baseURI The new base URI to be set.
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Returns the token URI for a given token ID.
     * @param tokenId The token ID to fetch metadata for.
     * @return The token metadata URI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev Burns a token permanently, removing it from the supply.
     * @param tokenId The token ID to burn.
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721){
        super._burn(tokenId);
    }

    /**
     * @dev Sets the default royalty for token sales.
     * @param receiver The address to receive the royalty payments.
     * @param feeNumerator The percentage fee (in basis points) to set as royalty.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit SetDefaultRoyaltyEvent(receiver, feeNumerator);
    }

    /**
     * @dev Sets the default royalty for token sales.
     * @param receiver The address to receive the royalty payments.
     * @param feeNumerator The percentage fee (in basis points) to set as royalty.
     */
    function setRoyalty(uint256 tokenID, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenID, receiver, feeNumerator);
        emit SetRoyaltyEvent(tokenID, receiver, feeNumerator);
    }


    /**
     * @dev Checks if the contract supports a specific interface.
     * @param interfaceId The interface ID to check.
     * @return True if the interface is supported, otherwise false.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Burns a token permanently, called externally.
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function getNextTokenId() view external returns(uint256){
        return nextTokenId;
    }
}