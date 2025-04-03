// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface INFT {
    function safeMint(address, uint256) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256) external view returns(address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function batchSafeMint(address _to, uint256 _quantity) external;

    function getNextTokenId() view external returns(uint256);
}