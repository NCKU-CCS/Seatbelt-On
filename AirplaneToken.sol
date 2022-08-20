// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/Strings.sol";
import "@openzeppelin/Ownable.sol";
import "@openzeppelin/MerkleProof.sol";
import "erc721a/ERC721A.sol";


contract Airplane is  ERC721A, Ownable {
    using Strings for uint256;

    string public baseTokenURI;
    string public baseExtension = ".json";

    uint256 public _price= 0.0003 ether;
    uint256 private _reserved = 50;
    uint256 public constant maxSupply=100;
    uint constant maxPurchase=10;

    bytes32 private _merkleRoot;

    bool public publicMintPaused = false;
    bool public whitelistMintPaused = false;
    bool public openblindbox=false;
    mapping(address => uint256) public walletCount;

    constructor(string memory _initBaseURI,bytes32 _root) ERC721A("Airplane", "AIR") {
        baseTokenURI=_initBaseURI;
        _merkleRoot=_root;
    }

    //change state
    function publicMintPause(bool _state) public onlyOwner {
        publicMintPaused = _state;
    }
    
    function whitelistMintPause(bool _state) public onlyOwner {
        whitelistMintPaused = _state;
    }

    //mint token
    function mintAir(uint _num)public payable{
        uint256 totalSupply = totalSupply();
        require(publicMintPaused,"The activity is close");
        require(_num<=maxPurchase,"Can only mint 10 token at a time");
        require((totalSupply+_num) <= (maxSupply-_reserved),"Purchase would exceed the supply of nfts");
        if(walletCount[_msgSender()]+_num>1){
            require(msg.value >= _price * (walletCount[_msgSender()]+_num-1), "Ether sent is not correct");
        }
        walletCount[_msgSender()] += _num;
        _safeMint(_msgSender(), _num);

    }

    //group mint
    function groupMint(address _to, uint256 _num) external payable onlyOwner {
        require(_num <= _reserved, "Exceeds reserved supply");
         _safeMint(_to, _num);
        _reserved -= _num;
    }

    //whitelist mint
    function whitelistMint(uint256 _num,bytes32[] memory proof)external payable{
        require(whitelistMintPaused, "The activity is close");
        uint256 totalSupply = totalSupply();
        require(_num<=maxPurchase,"Can only mint 10 token at a time");
        require((totalSupply+_num) <= (maxSupply-_reserved),"Purchase would exceed the supply of nfts");
        require(msg.value >= _price * _num, "Ether sent is not correct");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(proof, _merkleRoot, leaf),
        "Address is not whitelisted"
        );

        walletCount[_msgSender()] += _num;
        _safeMint(_msgSender(), _num);
    }

    //blind box
    function setBlindBox(bool status)public onlyOwner{
        openblindbox=status;
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

    string memory currentBaseURI = _baseURI();
    if(openblindbox){
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }
    else return currentBaseURI;
  }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        require(openblindbox,"The activity is close");
        baseTokenURI = _baseTokenURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

}
