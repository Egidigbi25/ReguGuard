;; contract title
;; Regulatory Document Summarization & Impact Analysis
;; This contract allows users to submit regulatory documents (by hash) and authorized AI agents to submit summaries.
;; It includes mechanism to analyze the complexity of the summary and predict regulatory impact.
;; NOW EXPANDED: Includes auditor roles, document lifecycle management, dispute resolution, and predictive analysis.

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized-agent (err u103))
(define-constant err-invalid-score (err u104))
(define-constant err-unauthorized-auditor (err u105))
(define-constant err-invalid-status-transition (err u106))
(define-constant err-dispute-active (err u107))
(define-constant err-no-dispute (err u108))

;; Status Constants for Document Lifecycle
(define-constant status-submitted u0)   ;; Document uploaded
(define-constant status-summarized u1)  ;; AI Summary provided
(define-constant status-reviewed u2)    ;; Auditor reviewed
(define-constant status-approved u3)    ;; Final approval
(define-constant status-rejected u4)    ;; Rejected (needs rework)
(define-constant status-disputed u5)    ;; Under dispute

;; data maps and vars
(define-data-var total-docs uint u0)

;; Store document metadata: submitter and submission block height
(define-map documents 
    uint 
    {
        hash: (buff 32), 
        submitter: principal, 
        timestamp: uint,
        title: (string-ascii 64)
    }
)

;; Store summaries provided by AI agents
(define-map summaries 
    uint 
    {
        summary-hash: (buff 32), 
        agent: principal, 
        timestamp: uint,
        version: uint
    }
)

;; Whitelist of authorized AI agents who can submit summaries and predictions
(define-map authorized-agents principal bool)

;; Whitelist of authorized auditors who can review summaries
(define-map authorized-auditors principal bool)

;; Track the current status of a document
(define-map doc-status uint uint)

;; Store reviews/audits for a document
(define-map reviews
    uint
    {
        auditor: principal,
        verdict: bool, ;; true = approve, false = reject
        comments-hash: (buff 32),
        timestamp: uint
    }
)

;; Store disputes raised against impact predictions
(define-map disputes
    uint
    {
        raiser: principal,
        reason-hash: (buff 32),
        resolved: bool,
        resolution-time: uint
    }
)

;; private functions

;; Check if the caller is the contract owner
(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner)
)

;; Check if the caller is an authorized AI agent
(define-private (is-authorized-agent (agent principal))
    (default-to false (map-get? authorized-agents agent))
)

;; Check if the caller is an authorized auditor
(define-private (is-authorized-auditor (auditor principal))
    (default-to false (map-get? authorized-auditors auditor))
)

;; Internal helper to update document status
(define-private (update-doc-status (doc-id uint) (new-status uint))
    (map-set doc-status doc-id new-status)
)

;; public functions

;; Register a new authorized AI agent. Only the contract owner can do this.
(define-public (add-authorized-agent (agent principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (map-set authorized-agents agent true))
    )
)

;; Remove an authorized AI agent. Only the contract owner can do this.
(define-public (remove-authorized-agent (agent principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (map-delete authorized-agents agent))
    )
)

;; Register a new authorized auditor. Only the contract owner can do this.
(define-public (add-authorized-auditor (auditor principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (map-set authorized-auditors auditor true))
    )
)

;; Remove an authorized auditor. Only the contract owner can do this.
(define-public (remove-authorized-auditor (auditor principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (map-delete authorized-auditors auditor))
    )
)

;; Submit a new regulatory document hash. Anyone can submit a document.
;; Updated to include a title for easier tracking.
(define-public (submit-document (doc-hash (buff 32)) (title (string-ascii 64)))
    (let
        (
            (doc-id (+ (var-get total-docs) u1))
        )
        (map-set documents doc-id {
            hash: doc-hash,
            submitter: tx-sender,
            timestamp: block-height,
            title: title
        })
        (map-set doc-status doc-id status-submitted)
        (var-set total-docs doc-id)
        (ok doc-id)
    )
)

;; Submit a summary for an existing document. Only authorized agents can do this.
;; Updated to track versions of summaries in case of re-submissions.
(define-public (submit-summary (doc-id uint) (summary-hash (buff 32)) (version uint))
    (begin
        ;; Verify the document exists
        (asserts! (is-some (map-get? documents doc-id)) err-not-found)
        ;; Verify the caller is an authorized agent
        (asserts! (is-authorized-agent tx-sender) err-unauthorized-agent)
        
        ;; Ensure document is in a state that allows summarization (Submitted or Rejected)
        (let ((current-status (default-to status-submitted (map-get? doc-status doc-id))))
            (asserts! (or (is-eq current-status status-submitted) (is-eq current-status status-rejected)) err-invalid-status-transition)
        )

        (map-set summaries doc-id {
            summary-hash: summary-hash,
            agent: tx-sender,
            timestamp: block-height,
            version: version
        })
        (update-doc-status doc-id status-summarized)
        (ok true)
    )
)

;; Review a summary. Only authorized auditors can do this.
;; Auditors can approve or reject a summary, moving it to the next stage.
(define-public (review-summary (doc-id uint) (verdict bool) (comments-hash (buff 32)))
    (begin
         ;; Verify the document exists
        (asserts! (is-some (map-get? documents doc-id)) err-not-found)
        ;; Verify the caller is an authorized auditor
        (asserts! (is-authorized-auditor tx-sender) err-unauthorized-auditor)
        ;; Verify that a summary exists to review
        (asserts! (is-some (map-get? summaries doc-id)) err-not-found)

        (map-set reviews doc-id {
            auditor: tx-sender,
            verdict: verdict,
            comments-hash: comments-hash,
            timestamp: block-height
        })

        (update-doc-status doc-id (if verdict status-approved status-rejected))
        (ok true)
    )
)

;; Dispute an impact prediction. Any authorized auditor can raise a dispute if they disagree with the AI.
(define-public (dispute-prediction (doc-id uint) (reason-hash (buff 32)))
    (begin
        (asserts! (is-authorized-auditor tx-sender) err-unauthorized-auditor)
        (asserts! (is-some (map-get? documents doc-id)) err-not-found)
        
        (map-set disputes doc-id {
            raiser: tx-sender,
            reason-hash: reason-hash,
            resolved: false,
            resolution-time: u0
        })
        (update-doc-status doc-id status-disputed)
        (ok true)
    )
)

;; Resolve a dispute. Only the contract owner (admin) can resolve disputes finaly.
(define-public (resolve-dispute (doc-id uint) (resolution bool))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (let ((dispute (unwrap! (map-get? disputes doc-id) err-not-found)))
            (map-set disputes doc-id (merge dispute { resolved: true, resolution-time: block-height }))
            (update-doc-status doc-id (if resolution status-approved status-rejected))
            (ok true)
        )
    )
)

;; Get document details by ID
(define-read-only (get-document (doc-id uint))
    (map-get? documents doc-id)
)

;; Get summary details by document ID
(define-read-only (get-summary (doc-id uint))
    (map-get? summaries doc-id)
)

;; Get document status
(define-read-only (get-doc-status (doc-id uint))
    (default-to status-submitted (map-get? doc-status doc-id))
)

;; Get review details
(define-read-only (get-review-details (doc-id uint))
    (map-get? reviews doc-id)
)

;; data map for complexity analysis feature
(define-map complexity-scores 
    uint 
    {
        score: uint,
        category: (string-ascii 20),
        analyzed-by: principal
    }
)

;; Analyze Complexity Function (Simulated AI Analysis)
(define-public (analyze-complexity (doc-id uint) (summary-len uint) (term-count uint) (readability-index uint))
    (let
        (
            (doc (unwrap! (map-get? documents doc-id) err-not-found))
            (is-agent (asserts! (is-authorized-agent tx-sender) err-unauthorized-agent))
            (base-score (+ (* summary-len u2) (* term-count u5)))
            (adjusted-score (/ (* base-score u100) (+ readability-index u1)))
            (category 
                (if (> adjusted-score u5000) "High Complexity"
                    (if (> adjusted-score u2000) "Medium Complexity" "Low Complexity")))
        )
        (map-set complexity-scores doc-id {
            score: adjusted-score,
            category: category,
            analyzed-by: tx-sender
        })
        (ok {
            doc-id: doc-id,
            score: adjusted-score,
            category: category
        })
    )
)

;; NEW FEATURE: Predictive Regulatory Impact Analysis
;; This function simulates a complex predictive model that an AI agent might run off-chain,
;; but validates and records the parameters on-chain to provide an immutable record of the prediction.
;; It takes various economic and legal factors to estimate the impact of the regulation.

(define-map impact-predictions
    uint
    {
        sector-code: (string-ascii 10),
        estimated-compliance-cost: uint,
        impact-score: uint,
        risk-level: (string-ascii 20),
        prediction-time: uint
    }
)

(define-constant risk-low "Low Risk")
(define-constant risk-moderate "Moderate Risk")
(define-constant risk-high "High Risk")
(define-constant risk-critical "Critical Risk")


