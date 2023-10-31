import "./structs";
import "./messages";

contract SbtItem {

    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");
    
    item_index: Int as uint64;
    collection_address: Address;
    owner: Address? = null;
    content: Cell? = null;
    authority_address: Address? = null;
    revoked_at: Int as uint64 = 1;
    is_initialized: Bool = false;

    init(collection_address: Address, item_index: Int) {
        self.item_index = item_index;
        self.collection_address = collection_address;
    }

    receive(msg: DeployItem) {
        require(!self.is_initialized, "Already Initiated");
        require(sender() == self.collection_address, "Invalid Sender");
        self.owner = msg.owner_address;
        self.content = msg.content;
        self.authority_address = msg.authority_address;
        self.revoked_at = 0;
        self.is_initialized = true;
    }

    receive(msg: ProveOwnership) {
        require(self.is_initialized, "Not Initiated");
        require(self.owner == sender(), "Invalid Sender");
        let content: Cell? = null;
        if (msg.with_content) {
            content = self.content;
        }
        send(SendParameters{
            to: msg.dest,
            value: 0,
            mode: SendRemainingValue,
            body: OwnershipProof {
                query_id: msg.query_id, 
                item_id: self.item_index, 
                owner: self.owner!!, 
                data: msg.forward_payload, 
                revoked_at: self.revoked_at, 
                content: content
            }.toCell()
        });

        self.exit_without_saving();
    }

    receive(msg: RequestOwner) {
        require(self.is_initialized, "Not Initiated");
        let content: Cell? = null;
        if (msg.with_content) {
            content = self.content;
        }
        send(SendParameters{
            to: msg.dest,
            value: 0,
            mode: SendRemainingValue,
            body: OwnerInfo {
                query_id: msg.query_id, 
                item_id: self.item_index, 
                initiator: sender(),
                owner: self.owner!!, 
                data: msg.forward_payload, 
                revoked_at: self.revoked_at, 
                content: content
            }.toCell()
        });

        self.exit_without_saving();
    }

    receive(msg: Destroy) {
        require(self.is_initialized, "Not Initiated");
        require(self.owner == sender(), "Invalid Sender");
        send(SendParameters{
            to: self.owner!!,
            value: 0,
            mode: SendRemainingBalance,
            body: Excesses{query_id: msg.query_id}.toCell()
        });
        self.owner = null;
        self.authority_address = null;
    }

    receive(msg: Revoke) {
        require(self.is_initialized, "Not Initiated");
        require(self.authority_address == sender(), "Invalid Sender");
        require(self.revoked_at == 0, "Already revoked");
        self.revoked_at = now();
    }

    receive(msg: TakeExcess) {
        require(self.is_initialized, "Not Initiated");
        require(self.owner == sender(), "Invalid Sender");
        nativeReserve(self.minTonsForStorage, 2);
        send(SendParameters{
            to: self.owner!!,
            value: 0,
            mode: SendRemainingBalance,
            body: Excesses{query_id: msg.query_id}.toCell()
        });
        self.exit_without_saving();
    }
    
    receive(msg: GetStaticData) {
        require(self.is_initialized, "Not Initiated");
        send(SendParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
        self.exit_without_saving();
    }

    bounced(msg: bounced<OwnershipProof>) {
        send(SendParameters{
            to: self.owner!!,
            value: 0,
            mode: SendRemainingValue,
            body: OwnershipProofBounced{query_id: msg.query_id}.toCell()
        });
        self.exit_without_saving();
    }

    inline fun exit_without_saving() {
        commit();
        throw(0);
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.content!!).asSlice().asString();
        b.append(collectionData);
        b.append(self.item_index.toString());
        b.append(".json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }

    get fun get_authority_address(): Address? {
        return self.authority_address;
    }
    get fun get_revoked_time(): Int {
        return self.revoked_at;
    }
}

