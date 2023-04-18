//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;//_tokenIds variable has the most recent minted tokenId    
    Counters.Counter private _itemsSold;//Keeps track of the number of items sold on the marketplace
    address payable owner;//owner is the contract address that created the smart contract
    uint256 listPrice = 0.01 ether;//The fee charged by the marketplace to allow NFT to be listed

    //The structure to store info about a listed token
    struct StoreItem {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => StoreItem) private idToStoreItem;

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToStoreItem() public view returns (StoreItem memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToStoreItem[currentTokenId];
    }

    function getStoreItemForId(uint256 tokenId) public view returns (StoreItem memory) {
        return idToStoreItem[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    //The first time a token is created, it is listed here
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        //Increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        //Mint the NFT with tokenId newTokenId to the address who called createToken
        _safeMint(msg.sender, newTokenId);

        //Map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newTokenId, tokenURI);

        //Helper function to update Global variables and emit an event
        createStoreItem(newTokenId, price);

        return newTokenId;
    } 

    function createStoreItem(uint256 tokenId, uint256 price) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Hopefully sending the correct price");
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToStoreItem[tokenId] = StoreItem(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), tokenId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            true
        );
    }
    
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllNFTs() public view returns (StoreItem[] memory) {
        uint nftCount = _tokenIds.current();
        StoreItem[] memory tokens = new StoreItem[](nftCount);
        uint currentIndex = 0;
        uint currentId;
        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=0;i<nftCount;i++)
        {
            currentId = i + 1;
            StoreItem storage currentItem = idToStoreItem[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }
    
    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (StoreItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToStoreItem[i+1].owner == msg.sender || idToStoreItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        StoreItem[] memory items = new StoreItem[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToStoreItem[i+1].owner == msg.sender || idToStoreItem[i+1].seller == msg.sender) {
                currentId = i+1;
                StoreItem storage currentItem = idToStoreItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint price = idToStoreItem[tokenId].price;
        address seller = idToStoreItem[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        idToStoreItem[tokenId].currentlyListed = true;
        idToStoreItem[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();
        
        _transfer(address(this), msg.sender, tokenId);//Actually transfer the token from the contract to the new owner
        approve(address(this), tokenId);//approve the marketplace to sell NFTs on your behalf

        payable(owner).transfer(listPrice);//Transfer the listing fee to the marketplace creator
        payable(seller).transfer(msg.value);//Transfer the proceeds from the sale to the seller of the NFT
    }
}