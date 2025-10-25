;; health-app
;; Clarity contract for a decentralized health record sharing platform

(define-data-var record-counter uint u0)

(define-map records {id: uint}
  {patient: principal,
   data: (string-ascii 50),
   shared-with: (optional principal),
   status: (string-ascii 10)})

;; Create a health record
(define-public (create-record (data (string-ascii 50)))
  (begin
    (asserts! (> (len data) u0) (err u1))
    (let
      (
        (id (var-get record-counter))
      )
      (map-set records {id: id}
        {patient: tx-sender,
         data: data,
         shared-with: none,
         status: "private"})
      (var-set record-counter (+ id u1))
      (ok id)
    )
  )
)

;; Share a record with a provider
(define-public (share-record (id uint) (provider principal))
  (match (map-get? records {id: id})
    record
    (if (and (is-eq (get status record) "private") (is-eq tx-sender (get patient record)))
      (begin
        (map-set records {id: id}
          {patient: (get patient record),
           data: (get data record),
           shared-with: (some provider),
           status: "shared"})
        (ok "Record shared")
      )
      (err u2)) ;; not private or not patient
    (err u3)) ;; record not found
)

;; Revoke shared record
(define-public (revoke-record (id uint))
  (match (map-get? records {id: id})
    record
    (if (and (is-eq (get status record) "shared") (is-eq tx-sender (get patient record)))
      (begin
        (map-set records {id: id}
          {patient: (get patient record),
           data: (get data record),
           shared-with: none,
           status: "private"})
        (ok "Record revoked")
      )
      (err u4)) ;; not shared or not patient
    (err u5)) ;; record not found
)