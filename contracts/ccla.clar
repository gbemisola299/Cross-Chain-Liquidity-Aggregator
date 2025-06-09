;; Cross-Chain Liquidity Aggregator
;; A protocol that aggregates liquidity from multiple chains using Bitcoin and Stacks as a settlement layer

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-chain-exists (err u102))
(define-constant err-chain-not-found (err u103))
(define-constant err-pool-exists (err u104))
(define-constant err-pool-not-found (err u105))
(define-constant err-insufficient-funds (err u106))
(define-constant err-invalid-parameters (err u107))
(define-constant err-timeout-not-reached (err u108))
(define-constant err-timeout-expired (err u109))
(define-constant err-swap-already-claimed (err u110))
(define-constant err-swap-not-found (err u111))
(define-constant err-invalid-path (err u112))
(define-constant err-invalid-signature (err u113))
(define-constant err-slippage-too-high (err u114))
(define-constant err-oracle-not-found (err u115))
(define-constant err-price-deviation (err u116))
(define-constant err-insufficient-liquidity (err u117))
(define-constant err-invalid-fee (err u118))
(define-constant err-invalid-preimage (err u119))
(define-constant err-relayer-not-found (err u120))
(define-constant err-invalid-route (err u121))
(define-constant err-emergency-shutdown (err u122))
(define-constant err-already-executed (err u123))
(define-constant err-inactive-pool (err u124))

;; Protocol parameters
(define-data-var next-swap-id uint u1)
(define-data-var next-route-id uint u1)
(define-data-var protocol-fee-bp uint u25) ;; 0.25% fee in basis points
(define-data-var max-slippage-bp uint u100) ;; 1% maximum slippage allowed
(define-data-var min-liquidity uint u1000000) ;; 1 STX minimum liquidity
(define-data-var default-timeout-blocks uint u144) ;; ~24 hours (144 blocks/day)
(define-data-var max-route-hops uint u3) ;; maximum hops in a route
(define-data-var treasury-address principal contract-owner)
(define-data-var emergency-shutdown bool false)
(define-data-var price-deviation-threshold uint u200) ;; 2% threshold for price oracle deviation
(define-data-var relayer-reward-percentage uint u10) ;; 10% of protocol fee goes to relayers

;; Stacks token for protocol governance
(define-fungible-token xchain-token)

;; Chain status enumeration
;; 0 = Active, 1 = Paused, 2 = Deprecated
(define-data-var chain-statuses (list 3 (string-ascii 10)) (list "Active" "Paused" "Deprecated"))

;; Swap status enumeration
;; 0 = Pending, 1 = Completed, 2 = Refunded, 3 = Expired
(define-data-var swap-statuses (list 4 (string-ascii 10)) (list "Pending" "Completed" "Refunded" "Expired"))

;; Supported blockchains
(define-map chains
  { chain-id: (string-ascii 20) }
  {
    name: (string-ascii 40),
    adapter-contract: principal,
    status: uint,
    confirmation-blocks: uint,
    block-time: uint, ;; Average block time in seconds
    chain-token: (string-ascii 10), ;; Chain's native token symbol
    btc-connection-type: (string-ascii 20), ;; "native", "wrapped", "bridged"
    enabled: bool,
    base-fee: uint, ;; Base fee for transactions on this chain
    fee-multiplier: uint, ;; Dynamic fee multiplier
    last-updated: uint
  }
)

;; Liquidity pools
(define-map liquidity-pools
  { chain-id: (string-ascii 20), token-id: (string-ascii 20) }
  {
    token-contract: principal,
    total-liquidity: uint,
    available-liquidity: uint,
    committed-liquidity: uint,
    min-swap-amount: uint,
    max-swap-amount: uint,
