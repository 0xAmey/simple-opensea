// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

//----------------------------------//
//               Errors             //
//----------------------------------//

error Opensea__Unauthorized();
error Opensea__WrongValueSent();
error Opensea__ListingNotFound();

contract Opensea {
    //----------------------------------//
    //             Events               //
    //----------------------------------//
    event NewListing(Listing listing);
    event ListingRemoved(Listing listing);
    event ListingBought(address indexed buyer, Listing listing);

    //----------------------------------//
    //             Variables            //
    //----------------------------------//
    uint256 internal saleCounter = 1;
    struct Listing {
        ERC721 tokenContract;
        uint256 tokenId;
        address creator;
        uint256 askPrice;
    }
    mapping(uint256 => Listing) public getListing;

    //----------------------------------//
    //             Functions            //
    //----------------------------------//
    function list(
        ERC721 tokenContract,
        uint256 tokenId,
        uint256 askPrice
    ) public payable returns (uint256) {
        Listing memory listing = Listing({
            tokenContract: tokenContract,
            tokenId: tokenId,
            askPrice: askPrice,
            creator: msg.sender
        });

        getListing[saleCounter] = listing;

        emit NewListing(listing);

        listing.tokenContract.transferFrom(
            msg.sender,
            address(this),
            listing.tokenId
        );

        return saleCounter++;
    }

    function cancelListing(uint256 listingId) public payable {
        Listing memory listing = getListing[listingId];

        if (listing.creator != msg.sender) revert Opensea__Unauthorized();

        delete getListing[listingId];

        emit ListingRemoved(listing);

        listing.tokenContract.transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
    }

    function buyListing(uint256 listingId) public payable {
        Listing memory listing = getListing[listingId];

        if (listing.creator == address(0)) revert Opensea__ListingNotFound();
        if (listing.askPrice != msg.value) revert Opensea__WrongValueSent();

        delete getListing[listingId];

        emit ListingBought(msg.sender, listing);

        SafeTransferLib.safeTransferETH(listing.creator, listing.askPrice);
        listing.tokenContract.transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
    }
}
