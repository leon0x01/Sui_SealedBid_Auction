import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId } from '../utils/packageInfo';
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";
dotenv.config();

async function createAuction() {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    const currentTime = new Date().getTime();
    const endTime = currentTime + 1 * 60 * 1000; // 10 minutes in milliseconds
    const revealTime = endTime + 3 * 60 *1000;
    tx.moveCall({
        target: `${packageId}::sealed_bid::create_auction`,
        arguments: [
            tx.pure.u64(endTime),
            tx.pure.u64(revealTime),
            tx.pure.u64(100000000),
            tx.pure.string("name"),
            tx.object(SUI_CLOCK_OBJECT_ID),
        ],
        typeArguments: [`0x2::sui::SUI`]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log(result.digest);
    const digest_ = result.digest;

    const txn = await client.getTransactionBlock({
        digest: String(digest_),
        // only fetch the effects and objects field
        options: {
            showEffects: true,
            showInput: false,
            showEvents: false,
            showObjectChanges: true,
            showBalanceChanges: false,
        },
    });
    let output: any;
    output = txn.objectChanges;
    let AuctionInfo;
    for (let i = 0; i < output.length; i++) {
        const item = output[i];
        if (await item.type === 'created') {
            if (await item.objectType === `${packageId}::sealed_bid::AuctionInfo<0x2::sui::SUI>`) {
                AuctionInfo = String(item.objectId);
            }
        }
    }
    console.log(`AuctionInfo: ${AuctionInfo}`);
}

createAuction();
