// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleOpensea.sol";
import "../lib/solmate/src/tokens/ERC721.sol";

contract TestNFT is ERC721("TestNFT", "TEST") {
    uint256 public tokenId = 1;

    function tokenURI(uint256) public pure override returns (string memory) {
        return "Test";
    }

    function mint() public payable returns (uint256) {
        _mint(msg.sender, tokenId);
        return tokenId++;
    }
}

contract OpenseaTest is Test {
    uint256 nftId;
    TestNFT internal nft;
    Opensea internal opensea;
    address user;

    event NewListing(Opensea.Listing listing);
    event ListingRemoved(Opensea.Listing listing);
    event ListingBought(address indexed buyer, Opensea.Listing listing);

    function setUp() public {
        user = address(0x1);
        opensea = new Opensea();
        nft = new TestNFT();
        nft.setApprovalForAll(address(opensea), true);
        nftId = nft.mint();
    }

    function testCanCreateSale() public {
        assertEq(nft.ownerOf(nftId), address(this));

        vm.expectEmit(true, true, true, true);
        emit NewListing(
            Opensea.Listing({
                tokenContract: nft,
                tokenId: nftId,
                creator: address(this),
                askPrice: 1 ether
            })
        );
        /*uint256 listingId =*/
        opensea.list(nft, nftId, 1 ether);
        // (
        //     ERC721 tokenContract,
        //     uint256 tokenId,
        //     address creator,
        //     uint256 askPrice
        // ) = opensea.getListing(listingId);
        // assertEq(address(tokenContract), address(nft));
        // assertEq(tokenId, nftId);
        // assertEq(creator, address(this));
        // assertEq(askPrice, 1 ether);
    }
}
