import HashSet "mo:base/TrieSet";
import Http "mo:http/Http";

module {
    public actor class Ledger(init : InitPayload) : async LedgerInterface {
        public query func account_balance_dfx(
            args : Args.AccountBalance,
        ) : async ICPTs {
            { e8s = 0; };
        };

        public query func get_nodes() : async [CanisterId] {
            [];
        };

        public query func http_request(
            req : Http.Request,
        ) : async Http.Response {
            {
                body        = [];
                headers     = [];
                status_code = Http.Status.NotFound;
            };
        };

        public shared({caller}) func notify_dfx(
            args : Args.NotifyCanister,
        ) : async () {

        };

        public shared({caller}) func send_dfx(
            args : Args.Send,
        ) : async BlockHeight {
            0;
        };
    };

    // -------------------------------------------------------------------------
    // | Types                                                                 |
    // -------------------------------------------------------------------------
    public module Args {
        public type AccountBalance = {
            account : AccountIdentifier;
        };

        public type NotifyCanister = {
            to_subaccount   : ?SubAccount;
            from_subaccount : ?SubAccount;
            to_canister     : Principal;
            max_fee         : ICPTs;
            block_height    : BlockHeight;
        };

        public type Send = {
            to              : AccountIdentifier;
            fee             : ICPTs;
            memo            : Memo;
            from_subaccount : ?SubAccount;
            created_at_time : ?TimeStamp;
            amount          : ICPTs;
        };
    };

    public type AccountIdentifier = Text;

    public type ArchiveOptions = {
        max_message_size_bytes     : ?Nat32;
        node_max_memory_size_bytes : ?Nat32;
        controller_id              : Principal;
    };

    public type BlockHeight = Nat64;

    public type CanisterId = Principal;

    public type Duration = {
        secs : Nat64;
        nanos : Nat32;
    };

    public let FEE : ICPTs = { e8s = 10000 }; // 0.0001 ICP

    public type ICPTs = {
        e8s : Nat64;
    };

    public type Memo = Nat64;

    public type SubAccount = [Nat8];

    public type TimeStamp = {
        timestamp_nanos : Nat64
    };

    public type TransactionNotification = {
        to              : Principal;
        to_subaccount   : ?SubAccount;
        from            : Principal;
        memo            : Memo;
        from_subaccount : ?SubAccount;
        amount          : ICPTs;
        block_height    : BlockHeight;
    };

    public type TransactionResult = {
        #Ok  : [Nat8];
        #Err : (Http.StatusCode, Text);
    };

    // -------------------------------------------------------------------------
    // | Actor Types                                                           |
    // -------------------------------------------------------------------------

    public type InitPayload = {
        minting_account        : AccountIdentifier;
        initial_values         : [(AccountIdentifier, ICPTs)];
        transaction_window     : ?Duration;
        max_message_size_bytes : ?Nat32;
        archive_options        : ?ArchiveOptions;
        send_whitelist         : HashSet.Set<CanisterId>;
    };

    public type LedgerInterface = actor {
        account_balance_dfx : query Args.AccountBalance  -> async ICPTs;
        get_nodes           : query ()                   -> async [CanisterId];
        http_request        : query Http.Request         -> async Http.Response;
        notify_dfx          : shared Args.NotifyCanister -> async ();
        send_dfx            : shared Args.Send           -> async BlockHeight;
    };

    public type NotifyInterface = actor {
        transaction_notification : query TransactionNotification -> async TransactionResult;
    };
};
