module auction::sealed_bid {
    use sui::object::{Self as object, ID, UID};
    use std::option::{Self, Option};
    use sui::balance::{Self, Balance};
    use std::string::{Self, utf8, String};
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use std::hash;
    use std::vector;
    use sui::event;
    use sui::package;
    use sui::display;
    use sui::dynamic_field as dfield;
    use sui::dynamic_object_field as dofield;
    use sui::tx_context::{Self, TxContext};

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                        ERRORS                              */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Thrown when an Auction Time has Ended
    const EAuctionEnded: u64= 0;
    
    /// @dev Thrown when a call for reveal function has ended the reveal Time
    const EAuctionRevealedTimeEnded: u64 = 1;

    /// @dev Thrown when the computed hash and provided bid hash mismatch
    const EIncorrectHash: u64 = 2;

    /// @dev Thrown when the winner trying to mint the auction nft before the reveal time period
    const EAuctionRevealedIsNotEnded: u64 = 3;

    /// @dev Thrown when invalid user trying to mint the nft 
    const EInvalidWinner: u64 = 4;

    /// @dev Thrown when the winner pay the less amount than the max bid amount at the end of the auction
    const ENotEnoughMaxBidSupply: u64 = 5;

    /// @dev Thrown when the bidder bid the less than Auction max amount
    const ELessThanAuctionMaxAmount: u64 = 6;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    SHARE OBJECT                            */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Struct contains the Auction Info which is the share object
    struct AuctionInfo<phantom T> has key, store {
        id: UID,
        // name of the Auction
        auction_name: String,
        // mapping between bidder address and committed hash i.e encrypted bid amount
        bidder: Table<address, vector<u8>>,
        // bidder bids which consist the max bid only updated after bidder reveal their bids
        max_bid: u64,
        // initial amount for bidding
        max_amount: u64,
        // auction start timestamp 
        start_time: u64, 
        // auction end timestamp
        end_time: u64,
        // auction reveal timestamp
        reveal_time: u64,
        // Auction creator address
        auction_owner: address,
        // Auction winner 
        winner: Option<address>,
        // auction winner need to pay for rarity NFT
        final_amount: Balance<T>,
        // bidder charges which is refundable after auction end
        redeemable: Table<address, Balance<T>>,
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    OWNED OBJECT                            */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    // @dev minted when bidder initally bid and it is the Initial Nova character
    // mandatory to have intial Nova NFT 
    struct NovaNFT has key, store {
        id: UID, 
        // name of the Nova character NFT
        name: String, 
        // description of the Nova Character
        description: String, 
        // image url link 
        url: String, 
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                   DYNAMIC LINK OBJECT                      */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    struct UpgradedNFT has key, store { 
        id: UID, 
        // name of the Upgrade Nova Character NFT 
        name: String,
        // description of the upgraded NFT 
        description: String, 
        // image url of the Upgrade Nova character
        url: String,
        // mode of Nova character presence and rarity 
        mode: String,
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                           EVENTS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/
    
    /// @dev emitted when the NovaNFT minted
    struct NovaNFTEvent has copy, drop {
        object_id: ID, 
        // creator of the nova nft 
        creator: address, 
        // name of the nova nft
        name: String,
    }

    // @dev one time witness of sealed bid module
    struct SEALED_BID has drop {}
    

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                       CONSTRUCTOR                          */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev initialized the dispaly properties for both Nova NFT 
    /// Upgraded NFT 
    fun init(
        otw: SEALED_BID, 
        ctx: &mut TxContext
    ) {
        let keys_1 = vector[
            utf8(b"name"),
            utf8(b"description"), 
            utf8(b"url"),
        ];
        let values_1 = vector[
            utf8(b"{name}"), 
            utf8(b"{description}"),
            utf8(b"{url}"), 
        ];
        let keys_2 = vector[
            utf8(b"name"),
            utf8(b"description"),
            utf8(b"url"), 
            utf8(b"mode"), 
        ];
        let values_2 = vector[
            utf8(b"{name}"), 
            utf8(b"{description}"), 
            utf8(b"{url}"),
            utf8(b"{mode}"), 
        ]; 
        let publisher = package::claim(otw, ctx); 
        let display_1 = display::new_with_fields<NovaNFT>(
            &publisher, keys_1, values_1, ctx
        );
        let display_2 = display::new_with_fields<UpgradedNFT>(
            &publisher, keys_2, values_2, ctx
        );
        display::update_version(&mut display_1);
        display::update_version(&mut display_2);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display_1, tx_context::sender(ctx));
        transfer::public_transfer(display_2, tx_context::sender(ctx));
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                     CREATE AUCTION                         */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev makes AuctionInfo object as Share Object which holds every details of Auction
    /// @param end_time Auction End TimeStamp
    /// @param reveal_time Auction Reveal TimeStamp
    /// @param auction initial amount, it increased after bidder bid 
    /// @param auction name Name of the Auction
    /// @param clock provided the current timestamp
    public fun create_auction<T>(end_time: u64,  reveal_time: u64, max_amount: u64, auction_name: String, clock: &Clock, ctx:&mut TxContext) {
        let empty_table: Table<address, Balance<T>> = table::new(ctx);
        let auction_info = AuctionInfo {
            id: object::new(ctx), 
            auction_name, 
            bidder: table::new(ctx), 
            max_bid: 0u64,
            max_amount,
            start_time: clock::timestamp_ms(clock),
            end_time,
            reveal_time,
            auction_owner: tx_context::sender(ctx), 
            winner: option::none(), 
            final_amount: balance::zero<T>(),
            redeemable: empty_table,
        };
        transfer::public_share_object(auction_info);
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                             BID                            */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/
   
     #[allow(lint(self_transfer))]
    /// @dev bid where user bid with encrypted way and commited hash is stored in auction bidder field
    /// @param auction Share Object of auction which holds auction details 
    /// @param bid commit hash Bidder Amount Hash representation
    /// @param clock provide the present timestamp

    public fun bid<T>(auction: &mut AuctionInfo<T>, bid_commit_hash: vector<u8>, clock: &Clock, ctx: &mut TxContext){ 
        assert!(clock::timestamp_ms(clock) < auction.end_time, EAuctionEnded);
        table::add(&mut auction.bidder, tx_context::sender(ctx), bid_commit_hash); 
        let nova_nft = NovaNFT {
            id: object::new(ctx), 
            name: string::utf8(b"Inital Nova NFT"), 
            description: string::utf8(b"Level up your utilization and aim for the ultimate upgrade!"),
            url: string::utf8(b"https://cdn.leonardo.ai/users/2a94d3f8-f33a-4347-9c27-e30dca807179/generations/c3d3625a-c35a-4709-9db9-dca69f71eeee/Default_Zoria_the_YoungWoman_Human_with_Light_Brown_Eyes_She_i_2.jpg?w=512"),
        };
        let sender = tx_context::sender(ctx);
        event::emit(NovaNFTEvent {
            object_id: object::uid_to_inner(&nova_nft.id),
            creator: sender, 
            name: nova_nft.name,
        });
        transfer::public_transfer(nova_nft, sender);
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                     REVEAL AUCTION                         */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev User reveal their bid_amount by themselves and check whether user are highes bidder or not highest bidder win the auction
    /// highest bid is disclosed after the auction reveal timestamp ended.
    /// @param auction AuctionInfo Shared Object which holds auction details 
    /// @param bid_amount user placed bid_amount
    /// @param salt secret to encrypted the bid_amount and finally computed hash in sha256
    public fun reveal_auction<T>(auction: &mut AuctionInfo<T>, clock: &Clock, bid_amount: u64, salt: vector<u8>, ctx: &mut TxContext) {
        let present_time = clock::timestamp_ms(clock);
        let sender = tx_context::sender(ctx);
        assert!(present_time > auction.end_time && present_time < auction.reveal_time, EAuctionRevealedTimeEnded);
        let get_hash = hash(bid_amount, salt); 
        assert!(*table::borrow(&auction.bidder, sender) == get_hash, EIncorrectHash);
        assert!(bid_amount > auction.max_amount, ELessThanAuctionMaxAmount);
        auction.max_amount = bid_amount;
        auction.winner = option::some(sender);
        auction.max_bid = bid_amount;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                        HASH                                */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/
    
    /// @dev SHA256 hash of bid amount with salt for hiding the bid amount 
    /// @param bid_amount user bid amount 
    /// @param salt secret key used represent as vector<u8>
    /// @return sah256 hash of bid_amount and salt embbedded hash
    fun hash(bid_amount: u64, salt: vector<u8>): vector<u8> {
        let data = salt;
        //vector::append(&mut data, bcs::to_bytes(&salt));
        let round_bytes: vector<u8> = vector[0, 0, 0, 0, 0, 0, 0, 0];
        let i = 7;
        while (i > 0) {
            let curr_byte = bid_amount % 0x100;
            let curr_element = vector::borrow_mut(&mut round_bytes, i);
            *curr_element = (curr_byte as u8);
            bid_amount = bid_amount >> 8;
            i = i - 1;
        };
        vector::append(&mut data, round_bytes);
        let hash_data = hash::sha2_256(data);
        hash_data
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                  MINT / UPGRADED NFT                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev user can upgraded the NOVA NFT after being auction winner and make nft composable for further use
    /// @param auction AuctionInfo SharedObject which holds auction details
    /// @param nft which is initial Nova NFT character
    /// @param clock provided the present timestamp
    /// @param coin the max bid amount the winner need to pay to upgrade the NovaNFT character and make composable
    public fun mint<T>(auction: &mut AuctionInfo<T>, nft: &mut NovaNFT, clock: &Clock, coin: Coin<T>, ctx: &mut TxContext) {
        assert!(clock::timestamp_ms(clock) > auction.reveal_time, EAuctionRevealedIsNotEnded);
        let winner = tx_context::sender(ctx);
        assert!(auction.winner == option::some(winner), EInvalidWinner); 
        assert!(auction.max_bid == coin::value(&coin), ENotEnoughMaxBidSupply);
        coin::put<T>(&mut auction.final_amount, coin);
        dfield::add<String, String>(&mut nft.id, string::utf8(b"upgrade"), string::utf8(b"level_upgraded"));
        nft.url = string::utf8(b"https://cdn.leonardo.ai/users/8230297a-cf09-47f2-9443-b31c0f80d47e/generations/86b0cade-119a-4a82-a37a-8a5c3a13b41e/Default_Zoria_the_YoungWoman_Human_with_Light_Brown_Eyes_She_i_0.jpg");
        let upgraded_nft = UpgradedNFT {
            id: object::new(ctx), 
            name: string::utf8(b"UpgradedNFT"),
            description: string::utf8(b"play_more_upgrade_more"), 
            url: string::utf8(b"https://cdn.leonardo.ai/users/8230297a-cf09-47f2-9443-b31c0f80d47e/generations/86b0cade-119a-4a82-a37a-8a5c3a13b41e/Default_Zoria_the_YoungWoman_Human_with_Light_Brown_Eyes_She_i_0.jpg"),
            mode: string::utf8(b"upgraded"),
        };
        dofield::add(&mut nft.id, object::id(&upgraded_nft), upgraded_nft);
    }

    #[test]
    fun verify_hash() {
        // let bid_amount = x"186a0";
        // let salt = x"616263"; 
        let bytes_convert_bid :vector<u8> = vector[ 160, 134, 1, 0 ];
        let test_vector: vector<u8> = vector[];
        let salt_to_vector: vector<u8> = vector[ 114, 97, 109 ];
        vector::append(&mut test_vector, salt_to_vector);
        vector::append(&mut test_vector, bytes_convert_bid);
        let test_sha256 = hash::sha2_256(test_vector);
        debug::print(&test_sha256);
        let expected_hash = hash(100000, salt_to_vector);
        debug::print(&expected_hash);
    }

    // @TODO
    // Encrypted metadata and revealing after certain Game-level
    // Batch auction 
    // optimization on updating shareobject 
    // abstraction of sealed-bid which can easily integrated like suitears
}