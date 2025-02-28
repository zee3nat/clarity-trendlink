;; TrendLink Governance Implementation

;; Constants
(define-constant min-votes u10)
(define-constant vote-period-blocks u144) ;; ~24 hours
(define-constant err-prediction-not-found (err u404))
(define-constant err-voting-closed (err u401))
(define-constant err-already-voted (err u403))

;; Data Maps
(define-map resolution-votes
  { prediction-id: uint }
  {
    yes-votes: uint,
    no-votes: uint,
    end-block: uint,
    total-voters: uint
  }
)

(define-map user-votes
  { prediction-id: uint, voter: principal }
  { voted: bool }
)

;; Public Functions
(define-public (start-resolution
  (prediction-id uint)
)
  (let
    (
      (pred (try! (contract-call? .trend-market get-prediction prediction-id)))
    )
    (asserts! (>= block-height (get end-block pred)) (err u401))
    (ok (map-insert resolution-votes
      { prediction-id: prediction-id }
      {
        yes-votes: u0,
        no-votes: u0, 
        end-block: (+ block-height vote-period-blocks),
        total-voters: u0
      }
    ))
  )
)

(define-public (vote-on-resolution
  (prediction-id uint)
  (vote bool)
)
  (let
    (
      (votes (unwrap! (map-get? resolution-votes {prediction-id: prediction-id}) err-prediction-not-found))
      (already-voted (default-to {voted: false} (map-get? user-votes {prediction-id: prediction-id, voter: tx-sender})))
    )
    (asserts! (< block-height (get end-block votes)) err-voting-closed)
    (asserts! (not (get voted already-voted)) err-already-voted)
    (map-set user-votes
      {prediction-id: prediction-id, voter: tx-sender}
      {voted: true}
    )
    (if vote
      (map-set resolution-votes 
        { prediction-id: prediction-id }
        { 
          yes-votes: (+ (get yes-votes votes) u1),
          no-votes: (get no-votes votes),
          end-block: (get end-block votes),
          total-voters: (+ (get total-voters votes) u1)
        }
      )
      (map-set resolution-votes
        { prediction-id: prediction-id } 
        {
          yes-votes: (get yes-votes votes),
          no-votes: (+ (get no-votes votes) u1),
          end-block: (get end-block votes),
          total-voters: (+ (get total-voters votes) u1)
        }
      )
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-votes (prediction-id uint))
  (map-get? resolution-votes {prediction-id: prediction-id})
)

(define-read-only (has-voted (prediction-id uint) (voter principal))
  (default-to false (get voted (map-get? user-votes {prediction-id: prediction-id, voter: voter})))
)
