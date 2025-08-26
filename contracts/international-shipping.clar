;; International Shipping Documentation Contract
;; Handles customs forms, import/export permits, and trade compliance

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-DOCUMENT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-STATUS (err u502))
(define-constant ERR-DOCUMENT-ALREADY-EXISTS (err u503))
(define-constant ERR-INVALID-INPUT (err u504))
(define-constant ERR-PERMIT-EXPIRED (err u505))

;; Data Variables
(define-data-var next-document-id uint u1)
(define-data-var next-permit-id uint u1)
(define-data-var next-declaration-id uint u1)

;; Data Maps
(define-map customs-documents
  { document-id: uint }
  {
    shipment-id: uint,
    document-type: (string-ascii 50),
    origin-country: (string-ascii 50),
    destination-country: (string-ascii 50),
    exporter: principal,
    importer: principal,
    total-value: uint,
    currency: (string-ascii 10),
    status: (string-ascii 20),
    created-at: uint,
    approved-at: (optional uint),
    customs-officer: (optional principal),
    notes: (string-ascii 500)
  }
)

(define-map import-export-permits
  { permit-id: uint }
  {
    permit-type: (string-ascii 30),
    applicant: principal,
    product-category: (string-ascii 100),
    origin-country: (string-ascii 50),
    destination-country: (string-ascii 50),
    quantity: uint,
    value: uint,
    issued-date: uint,
    expiry-date: uint,
    status: (string-ascii 20),
    permit-number: (string-ascii 50),
    issuing-authority: (string-ascii 100)
  }
)

(define-map customs-declarations
  { declaration-id: uint }
  {
    document-id: uint,
    hs-code: (string-ascii 20),
    product-description: (string-ascii 200),
    quantity: uint,
    unit-value: uint,
    total-value: uint,
    duty-rate: uint,
    tax-rate: uint,
    calculated-duty: uint,
    calculated-tax: uint,
    paid: bool
  }
)

(define-map trade-compliance
  { country-pair: (string-ascii 100) }
  {
    trade-agreement: (string-ascii 100),
    duty-free-threshold: uint,
    restricted-items: (string-ascii 500),
    required-documents: (string-ascii 300),
    processing-time: uint,
    last-updated: uint
  }
)

(define-map regulatory-updates
  { update-id: uint }
  {
    country: (string-ascii 50),
    regulation-type: (string-ascii 50),
    description: (string-ascii 500),
    effective-date: uint,
    impact-level: uint,
    created-at: uint
  }
)

(define-data-var next-update-id uint u1)

;; Public Functions

;; Create customs document
(define-public (create-customs-document
  (shipment-id uint)
  (document-type (string-ascii 50))
  (origin-country (string-ascii 50))
  (destination-country (string-ascii 50))
  (importer principal)
  (total-value uint)
  (currency (string-ascii 10)))
  (let ((document-id (var-get next-document-id)))
    (asserts! (> total-value u0) ERR-INVALID-INPUT)
    (asserts! (> shipment-id u0) ERR-INVALID-INPUT)

    (map-set customs-documents
      { document-id: document-id }
      {
        shipment-id: shipment-id,
        document-type: document-type,
        origin-country: origin-country,
        destination-country: destination-country,
        exporter: tx-sender,
        importer: importer,
        total-value: total-value,
        currency: currency,
        status: "pending",
        created-at: block-height,
        approved-at: none,
        customs-officer: none,
        notes: ""
      }
    )

    (var-set next-document-id (+ document-id u1))
    (ok document-id)
  )
)

;; Apply for import/export permit
(define-public (apply-for-permit
  (permit-type (string-ascii 30))
  (product-category (string-ascii 100))
  (origin-country (string-ascii 50))
  (destination-country (string-ascii 50))
  (quantity uint)
  (value uint)
  (expiry-date uint)
  (permit-number (string-ascii 50))
  (issuing-authority (string-ascii 100)))
  (let ((permit-id (var-get next-permit-id)))
    (asserts! (> quantity u0) ERR-INVALID-INPUT)
    (asserts! (> value u0) ERR-INVALID-INPUT)
    (asserts! (> expiry-date block-height) ERR-INVALID-INPUT)

    (map-set import-export-permits
      { permit-id: permit-id }
      {
        permit-type: permit-type,
        applicant: tx-sender,
        product-category: product-category,
        origin-country: origin-country,
        destination-country: destination-country,
        quantity: quantity,
        value: value,
        issued-date: block-height,
        expiry-date: expiry-date,
        status: "pending",
        permit-number: permit-number,
        issuing-authority: issuing-authority
      }
    )

    (var-set next-permit-id (+ permit-id u1))
    (ok permit-id)
  )
)

;; Approve customs document
(define-public (approve-customs-document
  (document-id uint)
  (notes (string-ascii 500)))
  (let ((document (unwrap! (map-get? customs-documents { document-id: document-id }) ERR-DOCUMENT-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status document) "pending") ERR-INVALID-STATUS)

    (map-set customs-documents
      { document-id: document-id }
      (merge document {
        status: "approved",
        approved-at: (some block-height),
        customs-officer: (some tx-sender),
        notes: notes
      })
    )

    (ok true)
  )
)

;; Approve permit
(define-public (approve-permit (permit-id uint))
  (let ((permit (unwrap! (map-get? import-export-permits { permit-id: permit-id }) ERR-DOCUMENT-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status permit) "pending") ERR-INVALID-STATUS)
    (asserts! (> (get expiry-date permit) block-height) ERR-PERMIT-EXPIRED)

    (map-set import-export-permits
      { permit-id: permit-id }
      (merge permit { status: "approved" })
    )

    (ok true)
  )
)

;; Create customs declaration
(define-public (create-customs-declaration
  (document-id uint)
  (hs-code (string-ascii 20))
  (product-description (string-ascii 200))
  (quantity uint)
  (unit-value uint)
  (duty-rate uint)
  (tax-rate uint))
  (let ((declaration-id (var-get next-declaration-id))
        (document (unwrap! (map-get? customs-documents { document-id: document-id }) ERR-DOCUMENT-NOT-FOUND))
        (total-value (* quantity unit-value))
        (calculated-duty (/ (* total-value duty-rate) u100))
        (calculated-tax (/ (* total-value tax-rate) u100)))

    (asserts! (or (is-eq tx-sender (get exporter document))
                  (is-eq tx-sender (get importer document))
                  (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (asserts! (> quantity u0) ERR-INVALID-INPUT)
    (asserts! (> unit-value u0) ERR-INVALID-INPUT)
    (asserts! (< duty-rate u100) ERR-INVALID-INPUT)
    (asserts! (< tax-rate u100) ERR-INVALID-INPUT)

    (map-set customs-declarations
      { declaration-id: declaration-id }
      {
        document-id: document-id,
        hs-code: hs-code,
        product-description: product-description,
        quantity: quantity,
        unit-value: unit-value,
        total-value: total-value,
        duty-rate: duty-rate,
        tax-rate: tax-rate,
        calculated-duty: calculated-duty,
        calculated-tax: calculated-tax,
        paid: false
      }
    )

    (var-set next-declaration-id (+ declaration-id u1))
    (ok declaration-id)
  )
)

;; Update trade compliance rules
(define-public (update-trade-compliance
  (country-pair (string-ascii 100))
  (trade-agreement (string-ascii 100))
  (duty-free-threshold uint)
  (restricted-items (string-ascii 500))
  (required-documents (string-ascii 300))
  (processing-time uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> processing-time u0) ERR-INVALID-INPUT)

    (map-set trade-compliance
      { country-pair: country-pair }
      {
        trade-agreement: trade-agreement,
        duty-free-threshold: duty-free-threshold,
        restricted-items: restricted-items,
        required-documents: required-documents,
        processing-time: processing-time,
        last-updated: block-height
      }
    )

    (ok true)
  )
)

;; Add regulatory update
(define-public (add-regulatory-update
  (country (string-ascii 50))
  (regulation-type (string-ascii 50))
  (description (string-ascii 500))
  (effective-date uint)
  (impact-level uint))
  (let ((update-id (var-get next-update-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> effective-date block-height) ERR-INVALID-INPUT)
    (asserts! (< impact-level u6) ERR-INVALID-INPUT)

    (map-set regulatory-updates
      { update-id: update-id }
      {
        country: country,
        regulation-type: regulation-type,
        description: description,
        effective-date: effective-date,
        impact-level: impact-level,
        created-at: block-height
      }
    )

    (var-set next-update-id (+ update-id u1))
    (ok update-id)
  )
)

;; Pay duties and taxes
(define-public (pay-duties-and-taxes (declaration-id uint))
  (let ((declaration (unwrap! (map-get? customs-declarations { declaration-id: declaration-id }) ERR-DOCUMENT-NOT-FOUND))
        (document (unwrap! (map-get? customs-documents { document-id: (get document-id declaration) }) ERR-DOCUMENT-NOT-FOUND)))

    (asserts! (is-eq tx-sender (get importer document)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get paid declaration)) ERR-INVALID-STATUS)

    (map-set customs-declarations
      { declaration-id: declaration-id }
      (merge declaration { paid: true })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get customs document
(define-read-only (get-customs-document (document-id uint))
  (map-get? customs-documents { document-id: document-id })
)

;; Get import/export permit
(define-read-only (get-permit (permit-id uint))
  (map-get? import-export-permits { permit-id: permit-id })
)

;; Get customs declaration
(define-read-only (get-customs-declaration (declaration-id uint))
  (map-get? customs-declarations { declaration-id: declaration-id })
)

;; Get trade compliance rules
(define-read-only (get-trade-compliance (country-pair (string-ascii 100)))
  (map-get? trade-compliance { country-pair: country-pair })
)

;; Get regulatory update
(define-read-only (get-regulatory-update (update-id uint))
  (map-get? regulatory-updates { update-id: update-id })
)

;; Check permit validity
(define-read-only (is-permit-valid (permit-id uint))
  (match (map-get? import-export-permits { permit-id: permit-id })
    permit (and (is-eq (get status permit) "approved")
                (> (get expiry-date permit) block-height))
    false
  )
)

;; Calculate total duties and taxes
(define-read-only (calculate-total-fees (declaration-id uint))
  (match (map-get? customs-declarations { declaration-id: declaration-id })
    declaration (+ (get calculated-duty declaration) (get calculated-tax declaration))
    u0
  )
)

;; Get next IDs
(define-read-only (get-next-document-id)
  (var-get next-document-id)
)

(define-read-only (get-next-permit-id)
  (var-get next-permit-id)
)

(define-read-only (get-next-declaration-id)
  (var-get next-declaration-id)
)
