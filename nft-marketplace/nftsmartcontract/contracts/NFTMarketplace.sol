//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// INTERNAL IMPORT FROM OPENZEPPLIN
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.0015 ether; // my fees

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() ERC721("NFT Metavarse Token", "MYNFT") {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "only the owner of marketplace can change the listing Price "
        );
        _;
    }

    function updateListingPrice(uint256 _listingPrice)
        public
        payable
        onlyOwner
    {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Create NFT TOken

    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1");
        require(
            msg.value == listingPrice,
            "value must be equal to listing Price"
        );

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        // _transfer(from , to , tokenId)

        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    // allow someone to resell token that he purcahsed (عرض للبيع)
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idMarketItem[tokenId].owner == msg.sender,
            "you must be the owner of token"
        );
        require(msg.value == listingPrice, "Price msut be equal listing price");

        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));
        idMarketItem[tokenId].sold = false;
        _itemsSold.decrement(); // resealing decrease sold items
        _transfer(msg.sender, address(this), tokenId);
    }

    // create item for selling

    function sellToken(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;
        require(price == msg.value, "please provide the item price");
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].seller = payable(address(0));

        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    // /* Returns all unsold market items ((Key is Owner should be contract address(this))) */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        // in order to create array , should create it with specific length
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();

        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        // loop into all NFT Market Items
        for (uint256 i = 0; i < itemCount; i++) {
            // get only Items that contract is the Owner(whcih is mean that it is not sold yet)
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Fetch MY PURCHASED NFT (Key is Owner should be msg.sender address)
    function fetchMyNFT() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        // in order to create array , should create it with specific length using loop by using msg.sender.

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += i;
            }
            MarketItem[] memory items = new MarketItem[](itemCount);
            for (uint256 i = 0; i < totalCount; i++) {
                if (idMarketItem[i + 1].owner == msg.sender) {
                    uint256 currentId = i + 1;
                    MarketItem storage currentItem = idMarketItem[currentId];
                    // first Item of Array should start with 0 , then increase it
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return items;
        }
    }

    //Fetch ListedItems(ما تم عرضه) , (key is the seller should be msg.sender)
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        // in order to create array , should create it with specific length using loop by using msg.sender.

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += i;
            }
            MarketItem[] memory items = new MarketItem[](itemCount);
            for (uint256 i = 0; i < totalCount; i++) {
                if (idMarketItem[i + 1].seller == msg.sender) {
                    uint256 currentId = i + 1;
                    MarketItem storage currentItem = idMarketItem[currentId];
                    // first Item of Array should start with 0 , then increase it
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return items;
        }
    }
}
