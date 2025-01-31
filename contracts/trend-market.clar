;; TrendLink Market Implementation
(use-trait trend-token .trend-token.trend-token)

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

(define-public (create-prediction 
  (description (string-utf8 256))
  (stake-amount uint)
  (blocks-until-close uint)
)
  (let 
    (
      (prediction-id (var-get next-prediction-id))
    )
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
      (pred (unwrap! (map-get? predictions {id: prediction-id}) (err u404)))
    )
    (asserts! (< block-height (get end-block pred)) (err u401))
    (asserts! (>= stake (get stake-amount pred)) (err u402))
    (try! (contract-call? .trend-token transfer stake tx-sender (as-contract tx-sender)))
    (ok (map-insert user-predictions
      { prediction-id: prediction-id, user: tx-sender }
      { prediction: prediction, stake: stake }
    ))
  )
)
