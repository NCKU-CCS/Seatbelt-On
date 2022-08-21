// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts@4.5.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.5.0/utils/cryptography/MerkleProof.sol";

contract Test_RW is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public mintPrice = 0.01 ether;
    uint256 public maxBalance = 10;// max NFT for wallet
    uint256 public maxMint = 1;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;

    //Whitelist
    bytes32 public root;
    bool public _presale = true;

    //Counters.Counter private _tokenIdCounter;

    constructor(string memory initNotRevealedUri, bytes32 _root)
        ERC721("Test Reveal", "TR")//name, symbol
    {
        setNotRevealedURI(initNotRevealedUri);
        root = _root;
    }

    function mintMeta(uint256 tokenQuantity, bytes32[] memory proof) public payable {
        if(_presale) {
            require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Whitelist");
        }
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(_isSaleActive, "Sale must be active to mint Metas");
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            tokenQuantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");


        //uint256 tokenId = _tokenIdCounter.current();
        //_tokenIdCounter.increment();
        _mintMeta(tokenQuantity);
    }

    function _mintMeta(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (_revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal(string memory _newBaseURI) public onlyOwner {
        _revealed = !_revealed;
        baseURI = _newBaseURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function flipPresale() public onlyOwner {
        _presale = !_presale;
    }

    function blendNFT(uint256 t1, uint256 t2, uint256 t3) public {
        require(!_presale, "Still in presale");
        require(ownerOf(t1) == msg.sender && ownerOf(t2) == msg.sender && ownerOf(t3) == msg.sender, "Not owner of token(s)");
        _mintMeta(1);
    }
}