import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, AuctionInfo} from '../utils/packageInfo';
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";
dotenv.config();

async function revealAuction() {
    const stringToHex = (str: string): Uint8Array => {
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
    const inputData = stringToHex("ram");
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${packageId}::sealed_bid::reveal_auction`,
        arguments: [
            tx.object(AuctionInfo),
            tx.object(SUI_CLOCK_OBJECT_ID),
            tx.pure.u64(200000000),
            tx.pure(Array.from(inputData)),
        ],
        typeArguments: [`0x2::sui::SUI`]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log(result.digest);
}

revealAuction();
