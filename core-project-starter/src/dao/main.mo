import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";


actor {
    
    stable var proposal_id: Nat = 0;
    private var proposals : HashMap.HashMap<Nat, Proposal> = HashMap.HashMap<Nat, Proposal>(1, Nat.equal, Hash.hash);
    private stable var _proposals : [(Nat, Proposal)] = [];

    public type Vote = {
        accept : Nat;
        reject : Nat;
    };
    public type Proposal = {
        name : Text;
        vote : Vote;
    };

    system func preupgrade() {
        _proposals := Iter.toArray(proposals.entries());
    };

    system func postupgrade() {
        _proposals := [];
    };

    public shared({caller}) func submit_proposal(p : Proposal) : async {#Ok : Proposal; #Err : Text} {
        // return #Err("Not implemented yet");
        proposal_id += 1;
        var proposal : Proposal = {
            name = p.name;
            vote = {
                accept = 0;
                reject = 0;
            };
        };
        proposals.put(proposal_id, proposal);
        return #Ok(p);
    };

    public shared({caller}) func vote(proposal_id : Nat, yes_or_no : Bool) : async {#Ok : (Nat, Nat); #Err : Text} {
        switch(proposals.get(proposal_id)) {
            case(?p) {  
                let proposal = voting(p, yes_or_no, 1);
                proposals.put(proposal_id, proposal);
                return #Ok((proposal.vote.accept, proposal.vote.reject));
            };
            case(null) {
                return #Err("Proposal not found");
            };
        };
    };

    private func voting(p: Proposal, yes_or_no : Bool, voting_power : Nat) : Proposal {
        if (yes_or_no) {
            return {
                name = p.name;
                vote = {
                    accept = p.vote.accept + voting_power;
                    reject = p.vote.reject;
                };
            };
        };
        return {
                name = p.name;
                vote = {
                    accept = p.vote.accept;
                    reject = p.vote.reject + voting_power;
                };
            };
    };

    public query func get_proposal(id : Nat) : async ?Proposal {
        return proposals.get(id);
    };
    
    public query func get_all_proposals() : async [(Nat, Proposal)] {
        return Iter.toArray(proposals.entries());
    };
};