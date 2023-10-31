import { beginCell, contractAddress, toNano, Cell, Address } from "ton";
import { NetworkProvider } from '@ton-community/blueprint';
// ================================================================= //
import { SbtCollection } from "../wrappers/SbtCollection";
import { SbtItem } from "../wrappers/SbtItem";
// ================================================================= //

export async function run(provider: NetworkProvider) {
    let collection_address = Address.parse("EQBLzYrl72T2vUJxR4Ju7OgXU8E4KeUOMcu8RrD5HAhi-vkn");

    let collection = provider.open(SbtCollection.fromAddress(collection_address));

    const nft_index = 0n;
    let address_by_index = await collection.getGetNftAddressByIndex(nft_index);

    console.log("NFT ID[" + nft_index + "]: " + address_by_index);
}