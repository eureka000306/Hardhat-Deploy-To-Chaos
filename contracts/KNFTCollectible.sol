//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract KNFTCollectible is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _mergeIds;

    struct TimeStamp {
        uint256 start;
        uint256 duration;
    }
    
    mapping (uint256 => uint256) private tokenIds;
    mapping (uint256 => TimeStamp) public timestamps;
    
    uint public constant BUYING_PRICE = 0.5 ether;
    uint public constant TOTAL_SUPPLY = 6000;
    uint public constant QUARTER = TOTAL_SUPPLY / 4;
    uint public constant MERGE_INITIAL_VALUE = 6000;
    uint256 private constant DEFAULT_DURATION = 25920000;
    
    string public baseTokenURI;
    uint public SELLING_PRICE = 0.4 ether;
    
    constructor(string memory baseURI) ERC721("KNFT Collectible", "KNFTC") {
        setBaseURI(baseURI);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setTokenSellPrice(uint _sellPrice) public onlyOwner {
        SELLING_PRICE = _sellPrice;
    }

    function setTimeStamp(uint256 _tokenId) private {
        timestamps[_tokenId].start = block.timestamp;
        timestamps[_tokenId].duration = DEFAULT_DURATION;
    }

    function setDuration(uint256 _tokenId, uint256 _duration) public {
        timestamps[_tokenId].duration = _duration;
    }

    function buyNFT(uint256 _tokenType) public payable {
        require(_tokenType >= 0 && _tokenType < 4, "Invalid Token Type");
        require(tokenIds[_tokenType] <= QUARTER, "Not enough NFTs left!");
        require(isOnProgress(this.tokensOfOwner(msg.sender), _tokenType), "User hasn't purchased all 6 nfts of the type");
        require(msg.value >= BUYING_PRICE, "Not enough ether to purchase NFTs.");

        uint256 _tokenId = getCurrentIdOfType(_tokenType);
        _mintSingleNFT(_tokenId);
        tokenIds[_tokenType]++;
    }

    function getCurrentIdOfType(uint256 _tokenType) public view returns (uint256) {
        require(_tokenType >= 0 && _tokenType < 4, "Invalid Token Type");
        return QUARTER * _tokenType + tokenIds[_tokenType];
    }
    
    function _mintSingleNFT(uint256 _tokenId) private {
        require(_tokenId >= 0 && _tokenId < (TOTAL_SUPPLY + MERGE_INITIAL_VALUE / 6), "Invalid Token ID");
        _safeMint(msg.sender, _tokenId);
    }
    
    function isOnProgress(uint[] memory _tokens, uint256 _tokenType) private pure returns (bool) {
        uint[4] memory tokenTypes;
        for (uint i = 0; i < _tokens.length; i++) {
            uint tokenType = _tokens[i] / QUARTER;
            tokenTypes[tokenType]++;
        }
        for (uint i = 0; i < 4; i++) {
            if (tokenTypes[i] >= 1 && tokenTypes[i] < 6) {
                return i == _tokenType;
            }
        }
        return true;
    }

    function merge(uint256 _tokenType) public {
        uint newMergeId = _mergeIds.current() + MERGE_INITIAL_VALUE;
        require(isMergeable(_tokenType), "User hasn't purchased all 6 nfts of the type");

        // Mint new Merged Kingdom NFT
        _mintSingleNFT(newMergeId);
        // Burn 6 NFTs instead of newly merged kingdom NFT
        burnNFTs(_tokenType);

        setTimeStamp(newMergeId);

        _mergeIds.increment();
    }

    function isMergeable(uint256 _tokenType) private view returns (bool) {
        uint256[] memory tokens = this.tokensOfOwner(msg.sender);
        uint tokensPurchasedForGivenType = 0;

        for(uint i = 0; i < tokens.length; i ++) {
            if (tokens[i] / QUARTER == _tokenType) {
                tokensPurchasedForGivenType++;
            }
        }
        return tokensPurchasedForGivenType >= 6;
    }

    function burnNFTs(uint256 _tokenType) private {
        uint256[] memory tokens = this.tokensOfOwner(msg.sender);
        uint count = 0;
        
        for(uint i = 0; i < tokens.length; i ++) {
            if((tokens[i] >= (_tokenType*QUARTER)) && (tokens[i] < ((_tokenType+1)*QUARTER))) {
                if(count > 6) return;
                super._burn(tokens[i]);
                count ++;
            }
        }
    }

    function sellNFT(uint256 _tokenId) public payable {
        require(_tokenId >= 0 && _tokenId < TOTAL_SUPPLY, "Invalid Token ID");
        require(msg.sender == address(uint160(ownerOf(_tokenId))), "Sender is not the owner of the token");

        address payable seller = payable(address(uint160(ownerOf(_tokenId))));
        _transfer(seller, address(this), _tokenId);

        seller.transfer(SELLING_PRICE);
    }
    
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function swapToKT() external payable returns (uint256) {
        require(msg.value >= 10**15, "Not enough balance to swap");
        return msg.value / 10**15;
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}