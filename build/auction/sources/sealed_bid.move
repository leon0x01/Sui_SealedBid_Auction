module auction::sealed_bid {
    use sui::object::{Self as object, ID, UID};
    use std::option::{Self, Option};
    use sui::balance::{Self, Balance};
    use std::string::{Self, utf8, String};
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::tx_context::{Self, sender, TxContext};

    const EAuctionEnded: u64= 0;

    struct AuctionInfo has key, store {
        id: UID,
        auction_name: String,
        bidder: Table<address, vector<u8>>,
        start_time: u64, 
        end_time: u64,
        reveal_time: u64,
        auction_owner: address,
        winner: Option<address>,
        redeemable: Balance<SUI>,
    }

    struct InitialNFT has key, store { 
        id: UID, 
        name: String,
        description: String, 
        url: String,
        mode: String,
    }

    public fun create_auction(end_time: u64, reveal_time: u64, auction_name: String, coin: Coin<SUI>, clock: &Clock, ctx:&mut TxContext) {
        let auction_info = AuctionInfo {
            id: object::new(ctx), 
            auction_name, 
            bidder: table::new(ctx), 
            start_time: clock::timestamp_ms(clock),
            end_time,
            reveal_time,
            auction_owner: tx_context::sender(ctx), 
            winner: option::none(), 
            redeemable: coin::into_balance(coin),
        };
        transfer::public_share_object(auction_info);
    }

    public fun mint_normal_nft(name: String, description: String, url: String, ctx: &mut TxContext) {
        let initialNft = InitialNFT {
            id: object::new(ctx), 
            name,
            description,
            url, 
            mode: string::utf8(b"general"),
        };
        transfer::public_transfer(initialNft, tx_context::sender(ctx));
    }

    public fun bid(auction: &mut AuctionInfo, inital_nft: &mut InitialNFT, bid_commit_hash: vector<u8>, clock: &Clock, ctx: &mut TxContext){
        // need to check whether the timestamp is less than end_time
        // already bidded user 
        // handle the amount 
        // bidder need to refundable payment to get sure valid bidder
        assert!(clock::timestamp_ms(clock) < auction.end_time, EAuctionEnded);
        table::add(&mut auction.bidder, tx_context::sender(ctx), bid_commit_hash); 
    }


    // function reveal auction bid after the time ended 
    // asertiong timestamp must greater than end time
    // assertion timestamp must be less than reveal time 
    // commit hash and key and balance must be same and 
    // decide the winner 

    // reclaim money after the auction end 
    // public fun reclaim()
    // after the reveal time is over 
    // bidder can claim their money back
    //

    // winner can add rarity nft to their dynamic object field 





    //public fun bid()

    // create auction 
    
    // random user's come and bid the auction
    // higher bidder are eligible to add rarity NFT on it exisiting NFT for game 
}