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

    struct AuctionInfo has key, store {
        id: UID,
        auction_name: String,
        bidder: Table<address, vector<u8>>,
        start_time: u64, 
        end_time: u64,
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

    public fun create_auction(end_time: u64, auction_name: String, coin: Coin<SUI>, clock: &Clock, ctx:&mut TxContext) {
        let auction_info = AuctionInfo {
            id: object::new(ctx), 
            auction_name, 
            bidder: table::new(ctx), 
            start_time: clock::timestamp_ms(clock),
            end_time,
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

    //public fun bid()

    // create auction 
    
    // random user's come and bid the auction
    // higher bidder are eligible to add rarity NFT on it exisiting NFT for game 
}