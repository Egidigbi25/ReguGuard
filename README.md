# ReguGuard: Regulatory Document Summarization & Impact Analysis

I have engineered **ReguGuard** as a comprehensive, decentralized solution for the high-integrity management of regulatory data. In a world of rapidly shifting legal landscapes, ReguGuard serves as a "Trust Layer," ensuring that AI-generated summaries and economic impact predictions are versioned, audited, and immune to retroactive tampering.

By utilizing the Clarity smart contract language on the Stacks blockchain, I have ensured that the business logic is interpreted and broadcast on-chain, providing full transparency into how regulatory risk scores are derived. This system is designed for institutional use cases where compliance transparency is non-negotiable.

---

## 📜 Table of Contents

1. Architectural Overview
2. Document Lifecycle & Status Codes
3. Private Logic & Access Control
4. Public Interface (State-Changing)
5. Read-Only Data Access
6. Mathematical Modeling
7. Governance & Dispute Resolution
8. Contribution & Development
9. MIT License

---

## Architectural Overview

I designed ReguGuard to operate on a principle of "Separation of Concerns." Users provide raw data hashes, AI Agents provide specialized intelligence, Auditors provide human validation, and the Contract Owner provides ultimate administrative governance.

### Ecosystem Roles:

* **Contract Owner:** The root of trust. Manages the whitelists for Agents and Auditors.
* **Authorized AI Agents:** Off-chain LLMs or analytical engines that process documents and commit their findings (summaries and impact scores) to the chain.
* **Authorized Auditors:** Subject matter experts who verify that the AI’s summary and impact analysis align with the actual regulatory text.
* **Submitters:** Any user or entity that needs a document processed by the ReguGuard network.

---

## Document Lifecycle & Status Codes

I have implemented a strict state machine to govern the lifecycle of every document. A document's status dictates which functions can be called upon it.

| Status Code | Constant | Meaning |
| --- | --- | --- |
| `u0` | `status-submitted` | Document hash is recorded; awaiting AI processing. |
| `u1` | `status-summarized` | AI Agent has submitted a summary hash and version. |
| `u2` | `status-reviewed` | An Auditor has completed a review of the summary. |
| `u3` | `status-approved` | The document is finalized and verified as accurate. |
| `u4` | `status-rejected` | The summary or analysis was found lacking; requires rework. |
| `u5` | `status-disputed` | An Auditor has flagged a prediction as potentially erroneous. |

---

## Private Logic & Access Control

I have encapsulated the core security checks within private functions to ensure consistency and reduce code duplication across the public interface.

### `is-contract-owner`

I use this to restrict sensitive administrative actions (like whitelisting) to the `tx-sender` who originally deployed the contract.

### `is-authorized-agent`

Returns a boolean by querying the `authorized-agents` map. This is the primary gatekeeper for summarization and predictive functions.

### `is-authorized-auditor`

Ensures only verified human experts (or secondary verification bots) can influence the document's path to approval or trigger disputes.

### `update-doc-status`

A centralized helper function that modifies the `doc-status` map, ensuring that every state transition is recorded uniformly.

---

## Public Interface (State-Changing)

I have categorized the public functions based on their impact on the global state of the contract.

### Administrative Functions

* **`add-authorized-agent` / `remove-authorized-agent**`: I designed these to manage the AI Agent whitelist, ensuring only verified computational models can commit data.
* **`add-authorized-auditor` / `remove-authorized-auditor**`: Used to manage the pool of human reviewers who provide the final layer of scrutiny.
* **`resolve-dispute`**: This is the final step in the dispute workflow. I allow the owner to review the `disputes` map entry and manually set the document to an `approved` or `rejected` state.

### Submission & Analysis Functions

* **`submit-document`**: Accepts a 32-byte hash (representing the raw document) and a string title. It increments the `total-docs` counter and initializes the status to `u0`.
* **`submit-summary`**: This function is called by Agents. It requires a `summary-hash` and a `version` number. I include a check that the document is currently in `submitted` or `rejected` state to allow for iterative improvements.
* **`analyze-complexity`**: A computational function that takes metadata (length, terms, readability) to categorize the document into "Low," "Medium," or "High" complexity categories.
* **`predict-regulatory-impact`**: This is the most advanced function in the contract. I have programmed it to calculate a weighted impact score based on compliance costs, entity counts, and punitive risks.

### Audit & Governance Functions

* **`review-summary`**: I provide this for Auditors to submit a boolean `verdict`. A `true` verdict pushes the document toward approval, while `false` triggers a rejection status, allowing the Agent to resubmit.
* **`dispute-prediction`**: If an Auditor disagrees with an AI’s impact score, they can freeze the document in a `disputed` state, providing a `reason-hash` for the Contract Owner to review.

---

## Read-Only Data Access

I provide several entry points for front-end dashboards and external integrations to query the state without gas costs.

* **`get-document`**: Returns the submitter, timestamp, title, and hash of the original document.
* **`get-summary`**: Returns the latest summary hash, the agent who provided it, and the version number.
* **`get-doc-status`**: Returns the current numerical status code from the state machine.
* **`get-review-details`**: Returns the auditor's principal, their verdict, and the hash of their comments.
* **`get-complexity-scores`**: Retrieves the specific algorithmic complexity category and score for a specific ID.

---

## Mathematical Modeling

I have implemented a tiered risk analysis model within the `predict-regulatory-impact` function. This provides a quantifiable "Impact Score" that drives the risk level classification.

Based on this , I categorize the regulation into one of the following:

* **Critical Risk:** 
* **High Risk:** 
* **Moderate Risk:** 
* **Low Risk:** 

---

## Governance & Dispute Resolution

I believe that even the best AI can be wrong. The dispute resolution system acts as a circuit breaker. If an Auditor triggers `dispute-prediction`, the document enters a "Legal Hold" (status `u5`). Only the Contract Owner can release this hold after conducting an off-chain investigation, ensuring that no document is approved with faulty impact data.

---

## Contribution & Development

I invite the community to help expand the predictive logic and front-end integration.

1. **Clone:** `git clone https://github.com/your-repo/ReguGuard.git`
2. **Test:** Use `clarinet test` to run the suite.
3. **Deploy:** Ensure you have sufficient STX on your testnet account before running `clarinet deploy`.

---

## MIT License

```text
MIT License

Copyright (c) 2026 ReguGuard - Decentralized Regulatory Analysis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

---
