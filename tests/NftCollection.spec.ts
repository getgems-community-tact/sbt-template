import { toNano, beginCell, comment } from "ton";
import { Blockchain, SandboxContract, TreasuryContract } from "@ton-community/sandbox";
import "@ton-community/test-utils";

import { SbtCollection } from "../wrappers/SbtCollection";
import { SbtItem,  } from "../build/SbtCollection/tact_SbtItem";
import { storeOwnerInfo, storeOwnershipProof } from "../wrappers/SbtItem";

describe("contract", () => {
    const OFFCHAIN_CONTENT_PREFIX = 0x01;
    const string_first = "https://s.getgems.io/nft-staging/c/628f6ab8077060a7a8d52d63/";
    let newContent = beginCell().storeInt(OFFCHAIN_CONTENT_PREFIX, 8).storeStringRefTail(string_first).endCell();

    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let authority: SandboxContract<TreasuryContract>;
    let collection: SandboxContract<SbtCollection>;
    let nft0: SandboxContract<SbtItem>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        blockchain.now = 2698781332;
        deployer = await blockchain.treasury("deployer");
        authority = await blockchain.treasury("authority");

        collection = blockchain.openContract(
            await SbtCollection.fromInit(deployer.address, newContent, {
                $$type: "RoyaltyParams",
                numerator: 350n, // 350n = 35%
                denominator: 1000n,
                destination: deployer.address,
            })
        );
        nft0 = blockchain.openContract(await SbtItem.fromInit(collection.address, 0n));

        const deploy_result = await collection.send(deployer.getSender(), { value: toNano(1) }, {$$type: 'RequestMint', index: 0n, owner_address: deployer.address, authority_address: authority.address, content: beginCell().endCell()});
        expect(deploy_result.transactions).toHaveTransaction({
            from: deployer.address,
            to: collection.address,
            deploy: true,
            success: true,
        });
    });

    it("Test", async () => {
        console.log("Next IndexID: " + (await collection.getGetCollectionData()).next_item_index);
        console.log("Collection Address: " + collection.address);
        expect((await collection.getGetCollectionData()).next_item_index).toEqual(1n);
    });

    it("should deploy correctly", async () => {
        let nft = blockchain.openContract(await SbtItem.fromInit(collection.address, 1n));
        let deploy_result = await nft.send(deployer.getSender(), {value: toNano(1)}, {$$type: 'DeployItem', owner_address: deployer.address, content: beginCell().endCell(), authority_address: deployer.address});
        expect(deploy_result.transactions).toHaveTransaction({
            from: deployer.address,
            to: nft.address,
            success: false,
            exitCode: 23263
        });
        expect((await nft.getGetNftData()).is_initialized).toBeFalsy();
        deploy_result = await collection.send(deployer.getSender(), { value: toNano(1) }, {$$type: 'RequestMint', index: 1n, owner_address: deployer.address, authority_address: deployer.address, content: beginCell().endCell()});
        console.log(deploy_result.events)
        console.log(nft.address)
        expect(deploy_result.transactions).toHaveTransaction({
            from: deployer.address,
            to: collection.address,
            success: true,
        });
        expect(deploy_result.transactions).toHaveTransaction({
            from: collection.address,
            to: nft.address,
            success: true,
        });
        expect((await collection.getGetCollectionData()).next_item_index).toEqual(2n);
        expect((await nft.getGetNftData()).is_initialized).toBeTruthy();
        console.log("Next IndexID: " + (await collection.getGetCollectionData()).next_item_index);
    });

    it("should return coins correctly", async () => {
        let transaction = await nft0.send(deployer.getSender(), {value: toNano("0.02")}, {$$type: 'TakeExcess', query_id: 12n});
        expect(transaction.transactions).toHaveTransaction({
            from: nft0.address,
            to: deployer.address,
            op: 0xd53276db,
        })
        expect((await blockchain.provider(nft0.address).getState()).balance).toEqual(toNano("0.03"));
    });
    it("should revoke", async () => {
        expect(await nft0.getGetAuthorityAddress()).toEqualAddress(authority.address);
        let transaction = await nft0.send(authority.getSender(), {value: toNano("0.02")}, {$$type: 'Revoke', query_id: 12n});
        expect(transaction.transactions).toHaveTransaction({
            from: nft0.address,
            to: authority.address,
            op: 0xd53276db,
        })
        expect(await nft0.getGetRevokedTime()).toEqual(BigInt(blockchain.now!));
    });
    it("should prove ownership", async () => {
        let dest = await blockchain.treasury("dest");
        let transaction = await nft0.send(dest.getSender(), {value: toNano("0.02")}, {$$type: 'ProveOwnership', query_id: 12n, dest: dest.address, forward_payload: comment("hello"), with_content: false});
        expect(transaction.transactions).toHaveTransaction({
            from: dest.address,
            to: nft0.address,
            success: false
        })
        transaction = await nft0.send(deployer.getSender(), {value: toNano("0.02")}, {$$type: 'ProveOwnership', query_id: 12n, dest: dest.address, forward_payload: comment("hello"), with_content: false});
        console.log(transaction.events)
        expect(transaction.transactions).toHaveTransaction({
            from: nft0.address,
            to: dest.address,
            success: true,
            body: beginCell().store(storeOwnershipProof({$$type: 'OwnershipProof', query_id: 12n, item_id: 0n, owner: deployer.address, data: comment("hello"), revoked_at: 0n, content: null})).endCell()
        })
    });
    it("should request owner", async () => {
        let dest = await blockchain.treasury("dest");
        let transaction = await nft0.send(dest.getSender(), {value: toNano("0.02")}, {$$type: 'RequestOwner', query_id: 12n, dest: dest.address, forward_payload: comment("hello"), with_content: false});
        expect(transaction.transactions).toHaveTransaction({
            from: nft0.address,
            to: dest.address,
            success: true,
            body: beginCell().store(storeOwnerInfo({$$type: 'OwnerInfo', query_id: 12n, item_id: 0n, initiator: dest.address, owner: deployer.address, data: comment("hello"), revoked_at: 0n, content: null})).endCell()
        })
    });
});