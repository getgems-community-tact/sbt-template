// storage::owner_address     = in_msg_body~load_msg_addr();
//         storage::content           = in_msg_body~load_ref();
//         storage::authority_address = in_msg_body~load_msg_addr();
//         storage::revoked_at        = 0;

message DeployItem {
    owner_address: Address;
    content: Cell?;
    authority_address: Address;
}

// prove_ownership#04ded148 query_id:uint64 dest:MsgAddress 
// forward_payload:^Cell with_content:Bool = InternalMsgBody;

message(0x04ded148) ProveOwnership {
    query_id: Int as uint64;
    dest: Address;
    forward_payload: Cell;
    with_content: Bool;
}

// ownership_proof#0524c7ae query_id:uint64 item_id:uint256 owner:MsgAddress 
// data:^Cell revoked_at:uint64 content:(Maybe ^Cell) = InternalMsgBody;

message(0x0524c7ae) OwnershipProof {
    query_id: Int as uint64;
    item_id: Int as uint256;
    owner: Address;
    data: Cell;
    revoked_at: Int as uint64;
    content: Cell?;
}

message(0xc18e86d2) OwnershipProofBounced {
    query_id: Int as uint64;
}

// request_owner#d0c3bfea query_id:uint64 dest:MsgAddress 
// forward_payload:^Cell with_content:Bool = InternalMsgBody;

message(0xd0c3bfea) RequestOwner {
    query_id: Int as uint64;
    dest: Address;
    forward_payload: Cell;
    with_content: Bool;
}

// owner_info#0dd607e3 query_id:uint64 item_id:uint256 initiator:MsgAddress owner:MsgAddress 
// data:^Cell revoked_at:uint64 content:(Maybe ^Cell) = InternalMsgBody;

message(0x0dd607e3) OwnerInfo {
    query_id: Int as uint64;
    item_id: Int as uint256;
    initiator: Address;
    owner: Address;
    data: Cell;
    revoked_at: Int as uint64;
    content: Cell?;
}

message(0xd53276db) Excesses {
    query_id: Int as uint64;
}

message(0x2fcb26a2) GetStaticData { 
    query_id: Int as uint64;
}

message(0x8b771735) ReportStaticData{
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}

// destroy#1f04537a query_id:uint64 = InternalMsgBody;
message(0x1f04537a) Destroy {
    query_id: Int as uint64;
}

// revoke#6f89f5e3 query_id:uint64 = InternalMsgBody;

message(0x6f89f5e3) Revoke {
    query_id: Int as uint64;
}

// take_excess#d136d3b3 query_id:uint64 = InternalMsgBody;

message(0xd136d3b3) TakeExcess {
    query_id: Int as uint64;
}