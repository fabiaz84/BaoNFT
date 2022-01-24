pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MerkleProof.sol";

contract BaoElder is ERC721Enumerable, Ownable {
	using Strings for uint256;
	using MerkleProof for bytes32[];

	uint256 public constant MAX_SUPPLY = 15;
	uint256 public constant MAX_PER_CALL = 1;

	bytes32 public merkleRoot;
	
	string public uri;
	string public suffix;

	mapping(address => bool) public whitelistClaimed;

	uint256 public whitelistSale;

	event BaoGMinted(uint256 indexed tokenId, address indexed receiver);

	constructor(uint256 _whitelistSale, bytes32 _root) ERC721("BaoElder", "BaoG") {
		whitelistSale = _whitelistSale;
		merkleRoot = _root;
	}

	function _baseURI() internal override view returns (string memory) {
		return uri;
	}

    	function tokenURI(uint256 tokenId) public view override returns (string memory) {
        	require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        	string memory baseURI = _baseURI();
        	return bytes(baseURI).length > 0
            	? string(abi.encodePacked(baseURI, suffix))
            	: '';
    	}

	function updateURI(string memory _newURI) public onlyOwner {
		uri = _newURI;
	}

	function updateWhitelistSale(uint256 _whitelistSale) public onlyOwner {
		whitelistSale = _whitelistSale;
	}

	function updateMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    	}

	function updateSuffix(string memory _suffix) public onlyOwner {
		suffix = _suffix;
	}

	function transferFrom(address from, address to, uint256 tokenId) public override {
		ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		ERC721.safeTransferFrom(from, to, tokenId, _data);
	}

	function mintBaoGWithSignature(bytes32[] calldata _proof) public {
		require(block.timestamp >= whitelistSale, "Public sale not ready");
		require(!whitelistClaimed[msg.sender], "Caller not part of tree");

		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require (MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");

		whitelistClaimed[msg.sender] = true;

    		uint256 supply = totalSupply();
    		require(supply + 1 <= MAX_SUPPLY, "Can't mint over limit");
   		_mint(msg.sender, supply + 1);
    		emit BaoGMinted(supply + 1, msg.sender);
 	}

	function fetchEther() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}
