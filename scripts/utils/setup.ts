import { SuiObjectChangePublished } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import getExecStuff from './execstuff';

const { execSync } = require('child_process');

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    });
}

const getPackageId = async () => {
    try {
        const { keypair, client } = getExecStuff();
        const account = "0x16b80901b9e6d3c8b5f54dc8a414bb1a75067db897e7a3624793176b97445ec6";
        const packagePath = process.cwd();
        const { modules, dependencies } = JSON.parse(
            execSync(`sui move build --dump-bytecode-as-base64 --path ${packagePath} --skip-fetch-latest-git-deps`, {
                encoding: "utf-8",
            })
        );
        const tx = new TransactionBlock();
        const [upgradeCap] = tx.publish({
            modules,
            dependencies,
        });
        tx.transferObjects([upgradeCap], tx.pure(account));
        const result = await client.signAndExecuteTransactionBlock({
            signer: keypair,
            transactionBlock: tx,
            options: {
                showEffects: true,
                showObjectChanges: true,
            }
        });
        console.log(result.digest);
        const digest_ = result.digest;

        const packageId = ((result.objectChanges?.filter(
            (a) => a.type === 'published',
        ) as SuiObjectChangePublished[]) ?? [])[0].packageId.replace(/^(0x)(0+)/, '0x') as string; 
        let UpgradeCap;
        let VAdminCap;
        let Version;

        // console.log(`packaged ID : ${packageId}`);
        await sleep(10000);

        if (!digest_) {
            console.log("Digest is not available");
            return { packageId};
        }

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

        for (let i = 0; i < output.length; i++) {
            const item = output[i];
            if (await item.type === 'created') {
                if (await item.objectType == `0x2::package::UpgradeCap`) {
                    UpgradeCap = String(item.objectId);
                }
                if (await item.objectType == `${packageId}::version::VAdminCap`) {
                    VAdminCap = String(item.objectId);
                }
                if (await item.objectType == `${packageId}::version::Version`) {
                    Version = String(item.objectId);
                }
            }
        }
        return { packageId,  UpgradeCap, VAdminCap, Version };
    } catch (error) {
        // Handle potential errors if the promise rejects
        console.error(error);
        return { packageId: '', UpgradeCap: '', VAdminCap: '', Version: '', };
    }
};

// Call the async function and handle the result.
getPackageId()
    .then((result) => {
        console.log(result);
    })
    .catch((error) => {
        console.error(error);
    });

export default getPackageId;
