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
    console.log(ToHex("ram"));
    function numberToBytes(num: number): Uint8Array {
        const buffer = new ArrayBuffer(8); // 8 bytes for a 64-bit number
        const view = new DataView(buffer);
        view.setUint32(0, num >>> 0); // Set the lower 32 bits
        view.setUint32(4, (num / 0x100000000) >>> 0); // Set the upper 32 bits
        return new Uint8Array(buffer);
    }
     const stringToHex = (str: string, uint8Array: Uint8Array): Uint8Array => {
        const hex: number[] = [];

        // Convert the string characters to hex representation
        for (let i = 0; i < str.length; i++) {
            const charCode = str.charCodeAt(i);
            const hexValue = charCode.toString(16).padStart(2, '0');
            hex.push(parseInt(hexValue, 16));
        }

        // Concatenate the uint8Array to the hex array
        uint8Array.forEach((value) => {
            hex.push(value);
        });

        // Create a Uint8Array from the array of numbers
        return new Uint8Array(hex);
    }
    // const stringToHex = (str: string, u64Value: number): Uint8Array => {
    //     const hex: number[] = [];

    //     // Convert the string characters to hex representation
    //     for (let i = 0; i < str.length; i++) {
    //         const charCode = str.charCodeAt(i);
    //         const hexValue = charCode.toString(16).padStart(2, '0');
    //         hex.push(parseInt(hexValue, 16));
    //     }

    //     // Convert the u64Value to its hexadecimal representation (u64 value should be a BigInt)
    //     const u64HexValue = u64Value.toString(16).padStart(16, '0');
    //     for (let i = 0; i < 16; i += 2) {
    //         hex.push(parseInt(u64HexValue.slice(i, i + 2), 16));
    //     }

    //     // Create a Uint8Array from the array of numbers
    //     return new Uint8Array(hex);
    // }

    function numberToUint8Array(number: number): Uint8Array {
            const buffer = new ArrayBuffer(4); // 4 bytes for a 32-bit number
            const view = new DataView(buffer);
            view.setUint32(0, number, true); // Set the number in little-endian format
            return new Uint8Array(buffer);
    }
    console.log(numberToUint8Array(100000));
    const hashDigest = sha256(stringToHex("ram", numberToUint8Array(100000000)));
    //const hashDigest = sha256(stringToHex("ram",100000000));
    //const hashDigest = sha256(proof);
    console.log(`hashDigest: ${hashDigest}`);
    console.log(typeof hashDigest);
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    // for rps coin
    // let coinId: string = (await client.getCoins({
    //     owner: keypair.getPublicKey().toSuiAddress(),
    //     coinType: `${packageId}::rps::RPS`,
    // })).data[0].coinObjectId;
    // const coin = tx.splitCoins(coinId, [tx.pure(amount)]);

    // for sui only
    //const coin = tx.splitCoins(tx.gas, [tx.pure(amount)]);

    tx.moveCall({
        target: `${packageId}::sealed_bid::bid`,
        arguments: [
            tx.object(AuctionInfo),
            tx.pure(Array.from(hashDigest)),
            tx.object(SUI_CLOCK_OBJECT_ID),
        ],
        // typeArguments: [`${packageId}::rps::RPS`]

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