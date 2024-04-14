# SEALED BID AUCTION

## INTRODUCTION

An Implementation of Sealed Bid Auction In SUI. A sealed-bid auction is a type of auction where bidders submit their bids in sealed envelopes, and the highest bidder wins the item and pays the amount of their bid. The bids are kept secret until the auction is over, and the bidders do not have visibility into the bids submitted by others.

In a sealed-bid auction, each bidder submits a bid in an envelope, and these are opened simultaneously to determine the highest bidder. The bidder with the highest value wins the bidding at a price equal to the second-highest value. The sealed-bid auction is more challenging to analyze because the bidders don't have a dominant strategy, and the best bid depends on what the other bidders are bidding.

## How to run

```
# Install Dependencies
npm install

# publish package
ts-node scripts/utils/setup.ts


```
