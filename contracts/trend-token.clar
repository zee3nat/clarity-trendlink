;; TrendLink Token Implementation
(define-fungible-token trend-token)

(define-constant contract-owner tx-sender)
(define-constant token-name "TrendLink")
(define-constant token-symbol "TLINK")
(define-constant token-decimals u6)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) (err u403))
    (ft-transfer? trend-token amount sender recipient)
  )
)

(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (ft-mint? trend-token amount recipient)
  )
)
