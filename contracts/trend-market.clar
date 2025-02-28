;; TrendLink Market Implementation

(use-trait trend-token .trend-token.trend-token)

;; Constants
(define-constant min-blocks-until-close u72) ;; Minimum 12 hours
(define-constant err-invalid-duration (err u405))
(define-constant err-prediction-not-found (err u404))
(define-constant err-prediction-closed (err u401))
(define-constant err-insufficient-stake (err u402))

;; Data Maps
(define-map predictions 
  { id: uint }
  {
    creator: principal,
    description: (string-utf8 256),
    stake-amount: uint,
    end-block: uint,
    resolved: bool
  }
)

(define-map user-predictions
  { prediction-id: uint, user: principal }
  { prediction: bool, stake: uint }
)

(define-data-var next-prediction-id uint u0)

;; Public Functions
(define-public (create-prediction 
  (description (string-utf8 256))
  (stake-amount uint)
  (blocks-until-close uint)
)
  (let 
    (
      (prediction-id (var-get next-prediction-id))
    )
    (asserts! (>= blocks-until-close min-blocks-until-close) err-invalid-duration)
    (map-insert predictions
      { id: prediction-id }
      {
        creator: tx-sender,
        description: description,  
        stake-amount: stake-amount,
        end-block: (+ block-height blocks-until-close),
        resolved: false
      }
    )
    (var-set next-prediction-id (+ prediction-id u1))
    (ok prediction-id)
  )
)

(define-public (make-prediction
  (prediction-id uint)
  (prediction bool)
  (stake uint)
)
  (let
    (
      (pred (unwrap! (map-get? predictions {id: prediction-id}) err-prediction-not-found))
    )
    (asserts! (< block-height (get end-block pred)) err-prediction-closed)
    (asserts! (>= stake (get stake-amount pred)) err-insufficient-stake)
    (try! (contract-call? .trend-token transfer stake tx-sender (as-contract tx-sender)))
    (ok (map-insert user-predictions
      { prediction-id: prediction-id, user: tx-sender }
      { prediction: prediction, stake: stake }
    ))
  )
)

;; Read-only Functions
(define-read-only (get-prediction (prediction-id uint))
  (map-get? predictions {id: prediction-id})
)

(define-read-only (get-user-prediction (prediction-id uint) (user principal))
  (map-get? user-predictions {prediction-id: prediction-id, user: user})
)
