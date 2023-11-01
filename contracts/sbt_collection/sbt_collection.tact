import "./structs";
import "./messages";
import "./../sbt_item/sbt_item";

contract SbtCollection {
    
    const minTonsForStorage: Int = ton("0.03");

    next_item_index: Int as uint64 = 0;
    owner_address: Address;
    royalty_params: RoyaltyParams;                      
    collection_content: Cell;   

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams){
        self.owner_address = owner_address;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
    }

    // [Collection Contract] -> Transfer -> OwnershipAssigned -> NFTExcesses
    receive(msg: RequestMint){
        let ctx: Context = context(); // get sender Info
        require(ctx.sender == self.owner_address, "Invalid Sender");
        require(msg.index <= self.next_item_index, "Invalid Index");

        nativeReserve(self.minTonsForStorage, 2);

        let nft_init: StateInit = self.getSbtItemInit(msg.index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: 0, 
                bounce: false,
                mode: SendRemainingBalance,
                body: DeployItem {
                    owner_address: msg.owner_address,
                    content: msg.content,
                    authority_address: msg.authority_address
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        if (self.next_item_index == msg.index) {
            self.next_item_index = self.next_item_index + 1;
        }
    }

    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  self.royalty_params.numerator,
                denominator: self.royalty_params.denominator,
                destination: self.owner_address
            }.toCell()
        });        
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("meta.json"); // You can changed this your self.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getSbtItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getSbtItemInit(item_index: Int): StateInit {
        return initOf SbtItem(myAddress(), item_index);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let cc: String = self.collection_content.asSlice().asString();
        b.append(cc);
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }
}