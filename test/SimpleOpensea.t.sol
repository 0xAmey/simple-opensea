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

    function testNonOwnerCannotCreateSale() public {
        assertEq(nft.ownerOf(nftId), address(this));

        vm.prank(address(user));
        vm.expectRevert("WRONG_FROM");

        opensea.list(nft, nftId, 1 ether);

        assertEq(nft.ownerOf(nftId), address(this));
    }

    function testCannotListWhenTokenIsNotApproved() public {
        assertEq(nft.ownerOf(nftId), address(this));
        nft.setApprovalForAll(address(opensea), false);

        vm.expectRevert("NOT_AUTHORIZED");
        opensea.list(nft, nftId, 1 ether);

        assertEq(nft.ownerOf(nftId), address(this));
    }

    function testCanCancelSale() public {
        uint256 listingId = opensea.list(nft, nftId, 1 ether);
        (, , address creator, ) = opensea.getListing(listingId);
        assertEq(creator, address(this));
        assertEq(nft.ownerOf(nftId), address(opensea));

        vm.expectEmit(true, true, false, true);
        emit ListingRemoved(
            Opensea.Listing({
                tokenContract: nft,
                tokenId: nftId,
                askPrice: 1 ether,
                creator: address(this)
            })
        );
        opensea.cancelListing(listingId);

        (, , address newCreator, ) = opensea.getListing(listingId);
        assertEq(newCreator, address(0));
    }

    function testNonOwnerCannotCancelSale() public {
        uint256 listingId = opensea.list(nft, nftId, 1 ether);
        (, , address creator, ) = opensea.getListing(listingId);
        assertEq(creator, address(this));

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("Opensea__Unauthorized()"));
        opensea.cancelListing(listingId);

        assertEq(nft.ownerOf(nftId), address(opensea));

        (, , address newCreator, ) = opensea.getListing(listingId);
        assertEq(newCreator, address(this));
    }

    function testCannotBuyNonExistingValue() public {
        vm.expectRevert(abi.encodeWithSignature("Opensea__ListingNotFound()"));
        opensea.buyListing(1);
    }

    function testCannotBuyWithWrongValue() public {
        uint256 listingId = opensea.list(nft, nftId, 1 ether);

        vm.expectRevert(abi.encodeWithSignature("Opensea__WrongValueSent()"));
        opensea.buyListing{value: 0.1 ether}(listingId);

        assertEq(nft.ownerOf(nftId), address(opensea));
    }

    function testCanBuyListing() public {}
}
