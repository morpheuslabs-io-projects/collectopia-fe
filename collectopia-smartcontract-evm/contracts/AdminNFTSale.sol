// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INFT.sol";

contract AdminSale is ERC721Holder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct SaleInfo{
        uint256 tokenId;
        uint256 price;
    }

    uint256 public constant BIG_NUMBER = 1000000000000000000000;

    uint256 public constant MAX_BATCH = 512;

    address payable public  fundHolder;

    address public immutable COLLECTION;
    
    address public operator;

    bool public isPaused;

    uint256[] public saleList;
    
    mapping(uint256 => uint256) public tokenPriceMap;

    event SetFundHolderEvent(address fundHolder);
    event AdjustSaleByIndexEvent(uint256 index, uint256 price);
    event PauseSaleEvent();
    event UnpauseSaleEvent();
    event PurchaseWithNativeEvent(address _beneficiary, uint256 tokenId_, uint256 amount);
    event PurchaseWithFiatEvent(address _beneficiary, uint256 tokenId_);
    event BatchSaleListingEvent(uint256 _tokenId, uint256 _tokenPrice);


    constructor(address _collection, 
                address  _fundHolder
                ) Ownable() {
        COLLECTION = _collection;
        fundHolder = payable(_fundHolder);
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
        require(_msgSender() == operator || _msgSender() == owner(), "Only Operator can do this action");
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


    function pauseSale() external onlyOwner(){
        isPaused = true;

        emit PauseSaleEvent();
    }

    function unpauseSale() external onlyOwner(){
        isPaused = false;

        emit UnpauseSaleEvent();
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
    function adjustSaleByIndex(uint256 _index, uint256 _price) external onlyOperator inSale {
        require(saleList.length > _index && saleList[_index] > 0, "Not a correct index");
        tokenPriceMap[saleList[_index]] = _price;
        emit AdjustSaleByIndexEvent(_index, _price);
    }

    // Operator can mint token at anytime 
    function batchSaleListing(uint256 _quantity, uint256 _price) external onlyOperator inSale {
        require(_quantity > 0 || _quantity <= MAX_BATCH, "Need > 0 and < MAX_BATCH");
        // Minting token to this address and sale
        uint256 i = 0;

        uint256 beginId_;
        
        beginId_ = INFT(COLLECTION).getNextTokenId();
    
        INFT(COLLECTION).batchSafeMint(address(this), _quantity);

        for(i = 0; i < _quantity; i++){
            // Put into sale list
            saleList.push(beginId_ + i);
            tokenPriceMap[beginId_ + i] = _price;

            emit BatchSaleListingEvent(beginId_ + i,  _price);
        }
    }

    function purchaseWithNativeByIndex(uint256 _index) nonReentrant inSale payable external{
        
        require(saleList.length > _index && saleList[_index] > 0, "Not a correct index");
        uint256 amount = msg.value;
        require(amount >= tokenPriceMap[saleList[_index]], "Not enough money");
        (bool sent, bytes memory data) = fundHolder.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _nftTransferByIndex(_index, msg.sender);

        emit PurchaseWithNativeEvent(msg.sender, saleList[_index], amount);
    }

    function purchaseWithFiatByIndex(uint256 _index, address _beneficiary) nonReentrant inSale onlyOperator payable external{
        
        require(saleList.length > _index && saleList[_index] > 0, "Not a correct index");

        _nftTransferByIndex(_index, _beneficiary);

        emit PurchaseWithFiatEvent(_beneficiary, saleList[_index]);
    }

    function purchaseWithNativeById(uint256 _id) nonReentrant inSale payable external{
    
        uint256 amount = msg.value;
        require(amount >= tokenPriceMap[_id], "Not enough money");
        (bool sent, bytes memory data) = fundHolder.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _nftTransferById(_id, msg.sender);

        emit PurchaseWithNativeEvent(msg.sender, _id, amount);
    }

    function purchaseWithFiatById(uint256 _id, address _beneficiary) nonReentrant inSale onlyOperator payable external{

        _nftTransferById(_id, _beneficiary);

        emit PurchaseWithFiatEvent(_beneficiary, _id);
    }

    function _nftTransferById(uint256 _id, address _beneficiary) internal{

        uint256 _index = BIG_NUMBER;

        uint256 i = 0;

        for(i = 0; i < saleList.length; i++){
            if(saleList[i] == _id){
                _index = i;
                break;
            }
        }
        require(_index != BIG_NUMBER, "Dont have that token ID for purchasing");

        INFT(COLLECTION).safeTransferFrom(address(this), _beneficiary, saleList[_index]);
        _removeElement(_index);
    }

    function _nftTransferByIndex(uint256 _index, address _beneficiary) internal{
        INFT(COLLECTION).safeTransferFrom(address(this), _beneficiary, saleList[_index]);
        _removeElement(_index);
    }

    function getSaleSize() view external returns(uint256){
        return  saleList.length;
    }

    function  getSaleList(uint256 _beginIndex, uint256 _size) view external returns(SaleInfo[] memory){
        SaleInfo[] memory tempList_ = new SaleInfo[](_size);
        uint256 i;
        uint256 length_ = saleList.length;
        require(_beginIndex + _size <= length_,  "Out of index");

        for(i = 0; i < _size; i++){
            tempList_[i] = SaleInfo(saleList[_beginIndex + i], tokenPriceMap[saleList[_beginIndex + i]]);
        }
        return tempList_;
    }

    // Remove an element at a specific index
    function _removeElement(uint _index) internal  {
        require(_index < saleList.length, "Index out of bounds");

        // Shift elements to the left
        for (uint i = _index; i < saleList.length - 1; i++) {
            saleList[i] = saleList[i + 1];
        }
        saleList.pop();
    }
    
    function getSaleInfo() public view returns (address, bool ) {
        return (COLLECTION, isPaused);
    }

}
