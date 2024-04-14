import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { sha256 } from '@noble/hashes/sha256';
import { packageId, AuctionInfo } from '../utils/packageInfo';
import { SUI_CLOCK_OBJECT_ID, toHEX } from "@mysten/sui.js/utils";
import { toB64 } from '@mysten/sui.js/utils';
import { bcs } from '@mysten/sui.js/bcs';
dotenv.config();

// string => hex => sha256 => hex value => passss
async function create_bid() {
    
    const ToHex = (str: string): Uint8Array => {
        const hex: number[] = [];
        for (let i = 0; i < str.length; i++) {
            const charCode = str.charCodeAt(i);
            const hexValue = charCode.toString(16);

            // Pad with zeros to ensure two-digit representation
            const paddedHexValue = hexValue.padStart(2, '0');

            // Convert the padded hex value to a number and push it to the array
            hex.push(parseInt(paddedHexValue, 16));
        }

        // Create a Uint8Array from the array of numbers
        return new Uint8Array(hex);
    };
    function hash(bid_amount: number, salt: Uint8Array): Uint8Array {
    let data = salt;
    let round_bytes = new Uint8Array([0, 0, 0, 0, 0, 0, 0, 0]);
    let i = 7;

    while (i > 0) {
        let curr_byte = bid_amount % 0x100;
        round_bytes[i] = curr_byte;
        bid_amount = bid_amount >> 8;
        i = i - 1;
    };

    data = new Uint8Array([...data, ...round_bytes]);
    let digest = sha256(data);
    return digest;
    }   
    const hashDigest = hash(200000000, ToHex("ram"))
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${packageId}::sealed_bid::bid`,
        arguments: [
            tx.object(AuctionInfo),
            tx.pure(Array.from(hashDigest)),
            tx.object(SUI_CLOCK_OBJECT_ID),
        ],
        typeArguments: ['0x2::sui::SUI']

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
    let NovaNFTId;
    for (let i = 0; i < output.length; i++) {
        const item = output[i];
        if (await item.type === 'created') {
            if (await item.objectType === `${packageId}::sealed_bid::NovaNFT`) {
                NovaNFTId = String(item.objectId);
            }
        }
    }
    console.log(`NovaNFT ${NovaNFTId}`);
}
create_bid();