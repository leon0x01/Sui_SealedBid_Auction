import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, AuctionInfo, novaNFTId} from '../utils/packageInfo';
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";
dotenv.config();

async function mint(amount: number) {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    const coin = tx.splitCoins(tx.gas, [tx.pure(amount)]);
    tx.moveCall({
        target: `${packageId}::sealed_bid::mint`,
        arguments: [
            tx.object(AuctionInfo),
            tx.object(novaNFTId),
            tx.object(SUI_CLOCK_OBJECT_ID),
            coin,
        ],
        typeArguments: [`0x2::sui::SUI`]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log(result.digest);
}

mint(200000000);
