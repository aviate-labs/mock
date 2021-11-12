import AccountIdentifier "mo:principal/AccountIdentifier";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import HashSet "mo:base/TrieSet";
import Http "mo:http/Http";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

module {
    // NOTE: do not use in production, this is for testing purposes...
    public actor class Ledger(init : InitPayload) : async LedgerInterface {

        // A simplified state.
        private let blocks   = Buffer.Buffer<Args.Send>(0);
        private let balances = HashMap.HashMap<AccountIdentifier, ICPTs>(
            0, Text.equal, Text.hash,
        );

        public query func account_balance_dfx(
            args : Args.AccountBalance,
        ) : async ICPTs {
            balance(args.account);
        };

        private func balance(a : AccountIdentifier) : ICPTs {
            switch (balances.get(a)) {
                case (null) { return { e8s = 0 } };
                case (? b)  { b };
            };
        };

        // @test
        public shared func addTestBalances(
            test_balances : [(AccountIdentifier, Nat64)],
        ) : async () {
            for ((a, n) in test_balances.vals()) balances.put(a, { e8s = n });
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
            let notify_canister = actor(Principal.toText(args.to_canister)) : NotifyInterface;
            let block_height = Nat64.toNat(args.block_height);
            let block = blocks.get(block_height);
            let notification : TransactionNotification = {
                to              = args.to_canister;
                to_subaccount   = args.to_subaccount;
                from            = caller;
                memo            = block.memo;
                from_subaccount = args.from_subaccount;
                amount          = block.amount;
                block_height    = args.block_height;
            };

            // Send notification.
            ignore notify_canister.transaction_notification(notification);
        };

        public shared({caller}) func send_dfx(
            args : Args.Send,
        ) : async BlockHeight {
            let sender = AccountIdentifier.toText(
                AccountIdentifier.fromPrincipal(caller, args.from_subaccount),
            );
            let sender_balance : ICPTs = balance(sender);
            assert (sender_balance.e8s > args.amount.e8s);
            balances.put(sender, { e8s = sender_balance.e8s - args.amount.e8s - FEE.e8s });
            
            let receiver_balance : ICPTs = balance(args.to);
            balances.put(args.to, { e8s = receiver_balance.e8s + args.amount.e8s });

            blocks.add(args);
            return Nat64.fromNat(blocks.size());
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
