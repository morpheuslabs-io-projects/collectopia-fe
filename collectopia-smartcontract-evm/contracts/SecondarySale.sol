// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INFT.sol";

contract NFTSale is ERC721Holder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;


    uint256 public nativePrice;

    address payable public  fundHolder;

    address public immutable COLLECTION;
    
    address public operator;

    bool public isPaused;

    event SetFundHolderEvent(address fundHolder);
    event UpdateSaleEvent(uint256 nativePrice);
    event PauseSaleEvent();
    event UnpauseSaleEvent();
    event PurchaseWithNativeEvent(address _beneficiary, uint256 tokenId_, uint256 amount);
    event PurchaseWithFiatEvent(address _beneficiary, uint256 tokenId_);

    constructor(address _collection, 
                address _whitelistSmc, 
                address  _fundHolder, 
                uint256 _nativePrice
                ) Ownable() {
        COLLECTION = _collection;
        fundHolder = payable(_fundHolder);
        nativePrice = _nativePrice;
        operator = _msgSender();
    }

    modifier inSale(){ 
        require(isPaused == false, "Sale has paused");
        _; 
    }

    modifier isAbleToBuy(){ 
        require(isPaused == false, "Sale has paused");
        // Holder can mint first
        _; 
    }

    
    modifier onlyOperator() {
        require(_msgSender() == operator, "Only Operator can do this action");
        _;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setFundHolder(address _fundHolder) public onlyOwner {
        require(_fundHolder != address(0), "_fundHolder = ZeroAddress");

        fundHolder = payable(_fundHolder);

        emit SetFundHolderEvent(_fundHolder);
    }

    function updateSale(uint256 _nativePrice) external onlyOwner(){
        require(_nativePrice > 0, "Price could not be zero");

        nativePrice = _nativePrice;

        emit UpdateSaleEvent(nativePrice);
    }

    function pauseSale() external onlyOwner(){
        isPaused = true;

        emit PauseSaleEvent();
    }

    function unpauseSale() external onlyOwner(){
        isPaused = false;

        emit UnpauseSaleEvent();
    }

    function _mintToken(address _beneficiary, uint _tokenId) private returns (uint256){

        INFT(COLLECTION).safeMint(_beneficiary, _tokenId);

        return (_tokenId);
    }

    function _getTheListOfTokenIds(address _beneficiary) internal view returns(uint256[] memory) {
        uint256 balance_ = INFT(COLLECTION).balanceOf(_beneficiary);
        uint256[] memory listOfTokenIds = new uint256[](balance_);

        for(uint256 i = 0; i < balance_; i++){
            listOfTokenIds[i] = INFT(COLLECTION).tokenOfOwnerByIndex(_beneficiary, i);
        }

        return listOfTokenIds;
    }


    // Operator can mint token at anytime 
    function mintWithFiatPurchase(address _beneficiary, uint256 _tokenId) external nonReentrant onlyOperator inSale {
        
        uint256 tokenId_;
        
        tokenId_ = _mintToken(_beneficiary, _tokenId);

        emit PurchaseWithFiatEvent(_beneficiary, tokenId_);
    }

    // Need to check starting block for public mint
    function purchaseWithNative(bytes32[] memory _proof, uint256 _tokenId) nonReentrant inSale payable external{
      
        uint256 amount = msg.value;
        require(amount >= nativePrice, "Not enough money");
        (bool sent, bytes memory data) = fundHolder.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _mintToken(msg.sender, _tokenId);

        emit PurchaseWithNativeEvent(msg.sender, _tokenId, amount);
    }

    
    function getSaleInfo() public view returns (address, uint256, bool ) {
        return (COLLECTION, nativePrice, isPaused);
    }

}
