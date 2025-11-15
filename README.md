# PoolTrust

> This document contains the **Requirements Specification** and the **System Architecture** for the PoolTrust smart contract subsystem. It is intended to guide developers, auditors, and integrators when implementing, testing, and deploying the contracts on Celo.

---

## Table of contents

1. [Overview](#overview)
2. [Scope](#scope)
3. [Requirements Specification](#requirements-specification)

   * Functional Requirements
   * Non-functional Requirements
   * Roles & Permissions
   * Supported Tokens
   * Events & Logging
   * Failure Modes & Edge Cases
   * Acceptance Criteria
4. [Assumptions](#assumptions)
5. [Threat Model & Security Considerations](#threat-model--security-considerations)
6. [System Architecture](#system-architecture)

   * High-level Components
   * Contract Interfaces
   * On-chain vs Off-chain Responsibilities
   * Storage & Data Models
   * Sequence Diagrams
   * Indexing, Analytics & Observability
   * Upgradeability & Governance
7. [Deployment Notes](#deployment-notes)
8. [Appendix: Example Events & Structs](#appendix-example-events--structs)

---

## Overview

PoolTrust is a decentralized funding platform enabling users to create funding pools, contribute assets, submit proposals for fund allocation, and vote on those proposals. Smart contracts handle pool lifecycle, contributions, governance, and fund disbursement.

This README focuses strictly on smart contract requirements and architecture.

---

## Scope

This document covers smart contract design for:

* PoolFactory (creates and indexes pools)
* FundingPool (per-pool logic: contributions, deadlines, goals, refunds)
* Governance / Proposal contract (proposal creation, voting, execution)
* Token adapter logic (ERC-20 / Celo tokens / HBAR adaptations as needed)
* Security & administrative controls (pause, role-management)

Not in scope: frontend UI, backend analytics ingestion code, or specific off-chain relayer implementations (except where explicitly called out as off-chain responsibilities).

---

# Requirements Specification

### Functional Requirements (must-have)

1. **Create Pool**

   * Any registered address may create a pool (subject to optional creation fees or staking).
   * Pool metadata: title, description, funding goal, target token, start timestamp, end timestamp, beneficiary (recipient address), optional milestones (on-chain references), voting rules (quorum, majority), and optional multi-stage disbursement schedule.
   * Emit `PoolCreated(poolId, creator, metadataHash)`.

2. **Contribute**

   * Users can contribute allowed tokens to an active pool between `start` and `end` timestamps.
   * Contributions are recorded per-contributor with amounts and token type.
   * Emit `Contributed(poolId, contributor, amount, token)`.

3. **Goal Evaluation**

   * When `end` is reached, the pool resolves to either `Successful` (goal met/exceeded) or `Failed` (goal not met).
   * If successful, the pool moves to `OpenForProposals` (or directly to `CreatorWithdraw` if governance not used).
   * Emit `PoolResolved(poolId, status)`.

4. **Refunds**

   * If a pool fails, contributors can claim refunds of their contributions.
   * Refunds must be claimable individually and idempotent.
   * Emit `RefundIssued(poolId, contributor, amount)`.

5. **Proposal Creation**

   * Contributors (and optionally the creator) may create proposals for how to use funds.
   * Proposal metadata: title, description, requested amount, recipient address, execution instruction data (if any), voting duration.
   * Emit `ProposalCreated(poolId, proposalId, proposer)`.

6. **Voting**

   * Voting power is proportional to contribution amount at a defined snapshot time (e.g., at proposal creation or pool resolution).
   * Support `for`, `against`, and `abstain` votes.
   * Enforce quorum and passing thresholds.
   * Emit `Voted(poolId, proposalId, voter, weight, side)`.

7. **Proposal Execution & Disbursement**

   * If proposal passes, authorized execution transfers funds (either full or staged) to the recipient.
   * Implement optional timelocks before execution.
   * Emit `ProposalExecuted(poolId, proposalId, recipient, amount)`.

8. **Partial / Staged Payouts**

   * Support multi-stage disbursement if pool configured with milestones (e.g., release 30% on approval, 70% on milestone completion).
   * Each stage requires either automatic release on proposal approval or new proposal+vote.

9. **Administration**

   * Admin roles for emergency pause/unpause, blacklist addresses, and upgrade initiation.
   * Minimize centralization — admin capabilities should be limited and well-documented.

10. **Multi-token Support**

    * Pool may accept one or more token types; contributions tracked per token. Simplest option: one token per pool.
    * Safe transfer handling for ERC20-like tokens and native token (Celo’s CELO or HBAR adaptations).

11. **Events**

    * Emit comprehensive events for each state-changing function to enable robust off-chain indexing.

12. **Gas Efficiency**

    * Optimize storage layout; avoid expensive loops on-chain; favor mappings and per-user pull-payments.

### Non-functional Requirements (should-have)

1. **Security**: Resist reentrancy, integer overflow/underflow, price manipulation if applicable.
2. **Auditability**: All fund flows must be traceable via events.
3. **Upgradability**: Optionally support upgradeable proxies or clear migration paths.
4. **Modularity**: Contracts must be modular (Factory, Pool, Governance) to ease testing and reuse.
5. **Testability**: Full unit & integration tests covering edge cases and failure modes.
6. **Compatibility**: Prefer standard token interfaces and follow Celo best practices.

### Roles & Permissions

* **Creator**: initiates pool, may propose (configurable), may be recipient.
* **Contributor**: funds pool; has voting power proportional to contributions.
* **Admin / Multisig**: emergency actions only (pause, blacklist, upgrade). Use multisig or DAO for admin actions.
* **Oracle (optional)**: supplies off-chain proofs or milestone fulfillment data.

### Supported Tokens

* Native chain token (e.g., CELO or HBAR) and/or ERC-20 compatible tokens.
* Token adapters must implement safe transfer checks and allowance semantics.

### Events & Logging (minimum set)

* `PoolCreated`(poolId, creator, token, goal, start, end, beneficiary)
* `Contributed`(poolId, contributor, amount, token)
* `PoolResolved`(poolId, status)
* `RefundIssued`(poolId, contributor, amount)
* `ProposalCreated`(poolId, proposalId, proposer, requestedAmount)
* `Voted`(poolId, proposalId, voter, weight, side)
* `ProposalExecuted`(poolId, proposalId, recipient, amount)
* `PoolPaused` / `PoolUnpaused`

### Failure Modes & Edge Cases

1. **Double-claim / reentrancy**: Contributions/refunds must be pull pattern.
2. **Token with fees-on-transfer**: Handle tokens that apply transfer fees (account for actual received amount).
3. **Partial funding**: contributions stop at `end`; if goal reached earlier, either close early or keep open (specify behavior).
4. **Proposal spam**: restrict proposal creation to contributors or require deposit to create proposals.
5. **Lost beneficiary key**: design fallback or multisig beneficiary options.
6. **Admin compromise**: minimize admin power and require multisig for critical ops.

### Acceptance Criteria

* Documented functional & non-functional requirements above.
* At least one representative sequence diagram for main flows (creation → contribute → resolve → proposal → vote → execute).
* Security & assumption model included.
* Document ready for handoff to contract developers.

---

## Assumptions

* Chain used is EVM-compatible (Celo).
* Contributors can only use tokens explicitly whitelisted per pool.
* Voting power is derived from contributions, not from external token holdings (unless intentionally integrated).

---

## Threat Model & Security Considerations

### High-level threats

1. **Smart contract bugs** (reentrancy, integer arithmetic, wrong access control)
2. **Governance takeover** (low quorum or cheap proposal creation)
3. **Token-specific ■ behaviors** (fee-on-transfer or non-standard ERC20)
4. **Front-running & timestamp manipulation**
5. **Denial of service via gas exhaustion** (e.g., large loops)

### Mitigations

* Use OpenZeppelin battle-tested libraries for math, access control, and safe token handling.
* Avoid loops over variable-length arrays in critical functions; use mappings & pull payments.
* Define snapshot-based voting or record voting power at a specific block to avoid manipulation.
* Require proposal creation deposits or minimum contribution to create proposals.
* Use multisig or DAO-managed admin privileges.
* Include timelocks for admin-sensitive operations.

---

# System Architecture

## High-level Components

```
+----------------------+        +-------------------+        +----------------+
|      Frontend        | <----> | Off-chain Backend | <----> |  Indexer/DB    |
| (Next.js + Wallet)   |        |                   | (Events store) |
+----------------------+        +-------------------+        +----------------+
         |                                |                          |
         |                                |                          |
         v                                v                          v
+---------------------------------------------------------------+
|                      On-chain Layer (Celo)                    |
|  +-----------+   +--------------+   +------------------------+ |
|  | PoolFactory|--| FundingPool  |-->| Governance / Proposal  | |
|  +-----------+   +--------------+   +------------------------+ |
+---------------------------------------------------------------+
```

### Component responsibilities

* **PoolFactory**

  * Create new FundingPool instances (or register proxy instances).
  * Maintain registry & basic indexing (owner -> pools list, totalPools).
  * Emit `PoolCreated` events.

* **FundingPool** (one per pool)

  * Accept contributions, track per-contributor balances.
  * Resolve pool at end time (successful/failed).
  * Allow refunds and/or move to governance stage.
  * Interface with Governance contract or manage proposals itself.

* **Governance / Proposal Contract**

  * Accept proposals, record votes proportional to contributions.
  * Enforce quorum & threshold rules.
  * Execute token transfers to beneficiaries or external recipients.

* **Off-chain Backend / Indexer**

  * Listen for events and maintain rich queryable state (user contributions, top pools, analytics).
  * Provide APIs to frontend for display and historical queries.

* **Frontend**

  * Wallet integration for contributions & transactions.
  * Display pool analytics using events from the indexer or direct on-chain calls.

## Contract Interfaces & Interactions

* `PoolFactory.createPool(metadata)` -> deploys or registers a `FundingPool` and returns `poolId`.
* `FundingPool.contribute(amount, token)` -> accepts funds.
* `FundingPool.resolve()` -> determines status at end time.
* `FundingPool.createProposal(metadata)` or `Governance.createProposal(poolId, metadata)`.
* `Governance.vote(poolId, proposalId, side)`.
* `Governance.executeProposal(poolId, proposalId)` -> transfers funds.

## On-chain vs Off-chain Responsibilities

**On-chain (must be trusted):**

* Fund custody & transfers
* Contributions accounting and refunds
* Proposal voting and execution logic

**Off-chain (best-effort / performance):**

* Indexing events & producing dashboards
* Large CSV exports, analytics
* Mail/notification systems
* Oracles / milestone verification (optional)

## Storage & Data Models

Example Solidity-like struct sketches (for reference):

```solidity
struct Pool {
  address creator;
  address beneficiary;
  uint256 goal;
  uint256 start;
  uint256 end;
  uint256 totalContributed; // per-token mapping in real impl
  PoolStatus status;
  address token; // token accepted for this pool
}

struct Contribution {
  uint256 amount;
  bool refunded;
}

struct Proposal {
  address proposer;
  uint256 requestedAmount;
  uint256 forVotes;
  uint256 againstVotes;
  uint256 abstainVotes;
  ProposalStatus status;
  uint256 endBlock;
}
```

Storage recommendations:

* Use mappings for contributor balances: `mapping(uint256 => mapping(address => uint256)) contributions;`

## Sequence Diagrams (mermaid)

### Pool creation → contribution → resolve → proposal → vote → execute

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant PF as PoolFactory
    participant P as FundingPool
    participant G as Governance

    U->>F: Fill Create Pool form
    F->>PF: createPool(metadata)
    PF-->>F: poolId
    U->>F: Contribute (wallet)
    F->>P: contribute()
    P-->>F: Contributed event
    Note right of P: time passes until end
    F->>P: resolve()
    P-->>F: PoolResolved(status)
    U->>F: createProposal()
    F->>G: createProposal(poolId,...)
    U->>F: vote()
    F->>G: vote()
    G-->>F: Voted event
    after VotingEnds
    F->>G: executeProposal()
    G-->>P: transfer funds
```


## Indexing, Analytics & Observability

* Emit granular events (see Events list). Off-chain indexer should:

  * Track per-pool contribution totals, per-user contributions, proposal states, and vote tallies.
  * Index event timestamps, transaction hashes, and block numbers.
  * Expose a REST API for the frontend with endpoints for top pools, user contributions, and proposal histories.
* Monitor for suspicious activity: abnormal large contributions, repeated proposals, or sudden admin actions.

## Upgradeability & Governance

* Prefer an immutable core for fund custody logic; if upgradeability is required, use a transparent proxy pattern with a DAO-controlled admin multisig.
* Document upgrade process and require timelocks and multisig approvals for critical upgrades.

---

## Deployment Notes

* Use a Celo testnet (Alfajores) for initial deployments and end-to-end testing.
* Verify contracts on a block explorer and publish ABI + docs.
* Integrate environment variables in the frontend to point to testnet addresses.
* Set up a deterministic deployment script (Hardhat/Foundry/Truffle) and record addresses in a deployment manifest.

---

## Appendix: Example Events & Structs

Minimum event signatures (solidity-like pseudocode):

```solidity
event PoolCreated(uint256 indexed poolId, address indexed creator, address token, uint256 goal, uint256 start, uint256 end, address beneficiary);
event Contributed(uint256 indexed poolId, address indexed contributor, uint256 amount, address token);
event PoolResolved(uint256 indexed poolId, PoolStatus status);
event RefundIssued(uint256 indexed poolId, address indexed contributor, uint256 amount);
event ProposalCreated(uint256 indexed poolId, uint256 indexed proposalId, address proposer, uint256 requestedAmount);
event Voted(uint256 indexed poolId, uint256 indexed proposalId, address indexed voter, uint256 weight, VoteSide side);
event ProposalExecuted(uint256 indexed poolId, uint256 indexed proposalId, address recipient, uint256 amount);
```

---
