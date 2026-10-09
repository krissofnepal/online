# Dental Clinic Management System — Module-Based Implementation Master Plan

Version: 0.4 — Revised after review | Date: 9 October 2026 | Status: DRAFT — IMPLEMENTATION NOT AUTHORIZED

Revision notes for v0.4 are in section 26.

Source: Dental_Clinic_Management_System_AI_Coder_Specification.pdf, version 1.0, 18 pages.

This document supplements the supplied specification. It identifies corrections and proposes a concrete implementation plan. Recommendations are not approved requirements unless explicitly identified below. No application code, repository, cloud account or deployment has been created as part of this review.

## How to use this plan

This is a self-contained implementation and review blueprint. It retains the original product/finance decisions and adds detailed module contracts and phase instructions. Confirmed user facts are separate from proposed rules. Implementation is conditional on the user's approval; no code or deployment is authorized by this document alone.

**For the user:** review scope, module map, financial examples, screen contracts and unresolved decisions. **For review agents:** use section 25 with this full file attached. **For coding agents after approval:** follow one authorized phase from section 21 and the module contracts in section 20; report actual evidence.

| Read first | Location |
| --- | --- |
| Confirmed clinic facts, release scope and architecture | Sections 1–4A |
| Relationships, finance examples, permissions, API and security | Sections 5–13 |
| New-clinic setup and canonical phase map | Sections 14–15 |
| Acceptance tests, risks and approval | Sections 16–18 |
| Primary technical sources | Section 19 |
| Detailed User/Admin/Doctor/Patient/Accounting and other module contracts | Section 20 |
| Phase 0–11 playbooks, including detailed foundation implementation steps | Section 21 |
| Field-level implementation baseline | Section 22 |
| Screen specifications and user journeys | Section 23 |
| Readiness and decision checklist | Section 24 |
| Copy-paste agent review and later coding prompts | Section 25 |

### Complete module map

| ID | User-facing module | Domain code owner | Main phase |
| --- | --- | --- | --- |
| M01 | User | accounts | 1 schema; 2 functionality |
| M02 | Admin and Clinic | clinics; scoped admin views | 2 |
| M03 | Doctor | clinics doctor subdomain | 3 |
| M04 | Patient | patients | 4 |
| M05 | Appointments and Reception | appointments | 5 |
| M06 | Clinical Visits | clinical | 6 |
| M07 | Dental Chart | dental_chart | 6 |
| M08 | Services and Pricing | treatments catalogue | 3 and 7 |
| M09 | Treatment Plans and Procedures | treatments | 7 |
| M10 | Prescriptions and Consent | clinical | 7 |
| M11 | Billing, Payments and Patient Credit | billing; payments | 8 |
| M12 | Accounting and Reconciliation | reconciliation; finance reports | 9 |
| M13 | Documents and Media | documents | 6–7; production adapter 10 |
| M14 | Reports and Dashboards | reports | 9; basic earlier widgets |
| M15 | Audit, Security and Tenant Isolation | audit; core; accounts | 1 infrastructure; 2 onward enforcement |
| M16 | Platform, Deployment and Backups | config; deploy; runbooks | 1 and 10–11 |

An Admin or Accounting menu is a workflow surface, not permission to duplicate another module's records. Modules share services through explicit interfaces. A module may span phases when its minimum dependency must be available earlier.

## 1. Confirmed scope and remaining approval

The user selected these planning directions on 6 October 2026:

- First working release: one new pilot clinic; architecture prepared for independent clinics later.
- Confirmed capacity: four dentists, one chair, approximately five patients per day.
- No existing patient or financial records; no historical-data migration is needed for launch.
- Hosting preference: Vercel at the start; no hosting budget allocated. The commercial-plan requirement below is unresolved.
- Local focus: Nepal; NPR, Nepal timezone, optional BS date display, and locally verified invoice requirements.
- Accounting scope: patient billing, advances, refunds, cash/bank reconciliation and accounting exports. Full clinic accounting is outside the first release.
- Treatment billing direction: use established practice-management patterns. The specific defaults proposed in section 6A require approval; there is no assumed universal deposit percentage.
- Implementation begins only after the complete plan is approved.

These choices authorize planning; they do not approve the schema, financial policies, hosting, or application implementation. Proposed defaults throughout this document remain reviewable.

## 2. Assessment of the supplied specification

Keep the modular Django/PostgreSQL architecture, central patient record, longitudinal clinical history, separation of invoices from cash received, server-side permissions, secure documents, tests and one-clinic pilot.

Resolve these issues before coding. In this table, references are to the source PDF, not to sections of this document.

| Source PDF reference | Issue | Proposed resolution |
| --- | --- | --- |
| PDF §12, p. 8 | Allocations appear in statement credit columns while the running balance changes inconsistently. This can count a receipt twice. | Financial statement balance changes only on charges, receipts, credit notes, refunds and approved opening entries. Allocations affect individual invoice/source balances, not patient net position. |
| PDF §§4, 10–11 | PaymentAllocation and CreditAllocation can spend the same receipt through separate paths unless carefully coordinated. | One credit-source allocation mechanism for both immediate payments and later advances. Keep PatientCredit as the traceable source; expose separate user actions without separate money pools. |
| PDF §4 | A single User.clinic_id and role limit staff who later work in several clinics. | Global User identity plus ClinicMembership; permissions belong to membership. |
| PDF §4 | Invoice.balance and PatientCredit.remaining_amount might become independently editable figures. | Compute from posted transactions; any stored summaries are controlled caches, never editable balances. |
| PDF §§6, 15 | Collision validation alone does not specify what happens when two receptionists book simultaneously. | Serialize scheduling writes per dentist/chair, then recheck overlap before commit. Record authorized override reason. |
| PDF §§7–9 | Multi-visit procedures, multi-tooth treatments and clinical signing are underspecified. | Separate treatment item, procedure and procedure sessions; tooth links can contain multiple teeth; signed clinical records use amendments. |
| PDF §§10–11 | Discounts, credit notes, paid-invoice cancellation, reversal and refund approval details are missing. | Approve transaction state machines and examples before finance implementation. |
| PDF §§19, 21 | Two incompatible phase-numbering schemes. | Use one phase register in this document. |
| PDF §19 | Audit/security appear as a late phase even though earlier modules depend on them. | Establish tenant isolation, audit infrastructure and security in the foundation; test them in every phase. |
| PDF §4 / phase descriptions | Prescriptions, consents, due dates, chairs and cash accounts lack sufficient models. | Add explicit entities and acceptance tests; defer opening imports because the clinic is new. |

## 3. First-release boundaries

### Include

1. Login, clinic memberships, roles and permissions.
2. Clinic settings, staff, dentist availability and chair configuration.
3. Patient registration, duplicate warnings, guardian/contact and medical-history alerts.
4. Dentist/chair calendar, walk-ins, check-in, cancellation, no-show and rescheduling history.
5. Visits, diagnoses, signed notes, amendments and tooth-history chart.
6. Services, treatment plan versions (including alternative options), item acceptance, multi-session procedures, billing eligibility and minimal lab-order tracking for outsourced work (proposed; D17).
7. Prescriptions and consent records, with templates approved by the clinic.
8. Draft/issued invoices, receipt entry, partial payments, advances, allocation, overpayments, credit notes, approved write-off of uncollectable balances (as a credit note) and unused-credit refunds.
9. Private PDFs/images for X-rays, consent and other patient documents.
10. Daily cash/bank reconciliation, patient statements, receivables ageing, source credits and management reports.
11. New-clinic setup with zero opening patient balances, clinic-level exports, audit, backup and restoration.

### Defer

- Full general ledger, expenses, supplier accounts, inventory and clinic financial statements.
- Dentist commission calculations, insurance claims and insurer settlement.
- SaaS subscriptions, self-service onboarding and public clinic sign-up.
- Multi-branch operations and cross-clinic patient sharing.
- Patient portal, online payment gateway, automated messaging and external integrations.
- AI diagnosis, automated clinical advice and AI-generated prescriptions.
- Offline writes, mobile apps, full React migration and advanced X-ray/DICOM viewers.
- Historical/opening-balance imports: not required for this new clinic; design and implement only if later authorized.

Do not silently enlarge release scope because a later feature is easy to scaffold.

## 4. Architecture and technical decisions

| Area | Proposed choice | Reason / condition |
| --- | --- | --- |
| Application | Modular Django monolith | One deployment; clear domain boundaries; fewer operational dependencies. |
| Versions | Proposed Python 3.12, Django 5.2 LTS latest security patch, PostgreSQL 17, Tailwind tooling (prefer the standalone CLI so the host build needs no Node toolchain); DRF only if an API is later authorized | Recheck support/compatibility and lock exact versions at implementation approval; no floating production dependencies. |
| UI | Django templates, locally built Tailwind assets and small JavaScript components | Fast common workflows without building two complete frontends. |
| Interactive chart/calendar | Focused components calling the same backend services | Upgrade a component later without replacing patient/finance logic. |
| API | Service layer first: browser forms and views call the same services. A versioned JSON `/api/v1/` (section 10) is optional and built only when a real external or JavaScript consumer exists; session auth and CSRF if built | No external client is in scope. Skipping DRF avoids a second surface to secure and test. No JWT layer. |
| Database | PostgreSQL in development, tests and production | Test the actual transaction and locking behavior. |
| Files | Private development storage; private external object storage in production | Vercel runtime disk is not persistent patient storage. Use authorized direct upload/download for large files. |
| Background tasks | Introduce only when a release feature needs them | Avoid adding a queue solely for possible future reminders. |
| Hosting | Vercel for the Django application, as requested; external PostgreSQL and private object storage | Production commercial-plan cost unresolved; provider region, backup destination and storage choice need review. |
| Tenancy | Clinic is the tenant; every owned row has clinic_id | A future branch is subordinate to a clinic, not automatically an independent tenant. |
| Database isolation | Application scoping plus PostgreSQL row-level security for tenant tables, subject to review | Additional protection against forgotten filters; see the deployment precautions below. The Phase 2 spike must confirm it works with the chosen pooler; if not, record an explicit decision to fall back to application scoping + composite FKs + automated scope tests (never drop it silently). |
| Currency/dates | NPR with decimal arithmetic; UTC timestamps; Asia/Kathmandu display; AD date source | BS display optional. Monetary rounding and fiscal-year numbering require policy approval. |

Use a custom User model in the first accounts migration. Django documents that moving to a custom model later is substantially harder [S1].

For database row-level security, the application role must not be a superuser, table owner or BYPASSRLS role. Set tenant context transaction-locally and test missing context, pooled connection reuse, background jobs and reports. Migrations and backups use a separately controlled role. PostgreSQL documents owner/bypass exceptions and the fact that referential integrity checks bypass row policies [S4]. RLS does not validate that two linked records belong to the same clinic.

### Proposed repository inventory

| Path | Responsibility |
| --- | --- |
| `config/settings/{base,development,test,production}.py` | Environment-specific configuration |
| `config/urls.py`, `asgi.py`, `wsgi.py` | Application entry points |
| `apps/core/` | Shared types, currency/date helpers, request context, idempotency |
| `apps/accounts/` | Custom User, memberships, role grants, authentication |
| `apps/clinics/` | Clinic settings, numbering, chairs, staff availability |
| `apps/patients/` | Patients, guardians, alerts, history snapshots, controlled merges |
| `apps/appointments/` | Scheduling, reschedule events, arrival and queues |
| `apps/clinical/` | Visits, diagnoses, signed notes, prescriptions, consents |
| `apps/dental_chart/` | Tooth references, findings, surfaces and longitudinal view |
| `apps/treatments/` | Services, plan revisions, items, procedures and sessions |
| `apps/billing/` | Invoices, lines, credit notes and billable-source tracking |
| `apps/payments/` | Receipts, credit sources, allocations, reversals and refunds |
| `apps/documents/` | Private upload, quarantine, authorized retrieval, versions |
| `apps/reconciliation/` | Cash/bank accounts, collection batches and reconciliation |
| `apps/reports/` | Read-only aggregation and controlled exports |
| `apps/audit/` | Append-only application audit events and protected reads |
| `templates/`, `static_src/` | Shared UI and compiled asset inputs |
| `tests/integration/`, `tests/browser/` | Cross-domain and end-to-end verification |
| `docs/decisions/`, `docs/workflows/`, `docs/runbooks/` | Approved decisions, workflows and operations |
| `deploy/`, `compose.yaml`, `.env.example` | Reproducible setup with no committed secrets |

Within a domain app: models store relationships; services perform writes; selectors perform scoped reads; views/API serializers validate input and call services. Django signals must not secretly post money.

## 4A. Vercel deployment revision and cost decision

Vercel now documents direct Django deployment: the application is served as a Vercel Function [S7]. Keep Django templates and PostgreSQL; do not switch to Next.js merely because the hosting provider is Vercel. Docker remains useful locally and for portability, but production is configured for Vercel Functions rather than running the local Compose stack there.

### Proposed deployment components

| Component | Proposed location / design |
| --- | --- |
| Django app and compiled static assets | Vercel project; one application origin for UI, sessions and API |
| Transactional database | External managed PostgreSQL connected to Vercel; provider selected after reviewing limits, backups and region |
| Sessions | Database-backed Django sessions; no instance-local session state |
| Documents | Private external object storage; Vercel Private Blob is a candidate, subject to Django/Python adapter review [S10] |
| Large uploads/downloads | Short-lived authorized object-store URLs; metadata/finalization through Django, validation gate before availability (antivirus per decision G12) |
| Tenant/financial locking | PostgreSQL transactions and locks; never process-memory locks |
| Schema migrations | One controlled release step against the intended database; preview builds never migrate production |
| Backups | Database-provider backups or an approved external backup job, plus protected document backups |
| Routine tasks | None required for the first release; add a platform-scheduled/external task only for a defined feature |

Vercel connects external PostgreSQL services through its Marketplace [S8]. Do not assume hosting the application also supplies a persistent database. Choose an application region close to the database, validate pooling and transaction-local tenant context, and keep preview/test databases separate from production.

Serverless functions open many short-lived connections, so a transaction-mode pooler is likely. That has consequences to test early (Phase 2 spike, reproducible locally with PgBouncer in transaction mode): tenant context must use `SET LOCAL` inside an explicit transaction on every request; Django server-side cursors must be disabled behind such a pooler; session-level advisory locks are unavailable; `select_for_update` needs an open transaction; cold-start latency and connection limits must be measured; and the deployed bundle must fit the platform's size limit (verify the current figure).

Vercel Functions have temporary rather than durable application disk [S11]. Patient files, SQLite databases and audit/backup files must not depend on it. The documented normal request/response body limit is 4.5 MB [S9]; choose direct private transfers for larger X-rays and PDFs. Validate that the selected Python storage integration can generate the required scoped URLs without exposing privileged credentials. Keep browser printing as the first invoice/PDF output method to avoid unnecessary heavy server PDF tooling.

### Budget conflict — not yet resolved

- User preference: no hosting budget allocated; start on Vercel.
- Current provider policy: Hobby is restricted to non-commercial personal use [S6]. Running this clinic application for business is not covered merely because it has low traffic or is an internal tool.
- Current published Pro base fee: USD 20/month, including one deploying team seat and USD 20 usage credit, with potential additional usage/taxes [S12]. External database, files and backup costs must be reviewed separately. Clinic app users are not Vercel deploying-team seats.
- Therefore, Vercel is technically suitable, but a guaranteed zero-cost live commercial deployment is not the approved plan.
- Until this is resolved, plan local development/testing and do not promise that a business-related online demo is eligible for Hobby. The Hobby eligibility depends on purpose, not the absence of real patient data.
- Decision needed before production approval: accept the applicable commercial-plan cost, use an already eligible paid Vercel team, or authorize comparison with another commercial-use host, including a small self-managed VPS. No subscription or external account is changed by this draft.

| Option | Strengths | Costs / risks to evaluate |
| --- | --- | --- |
| Vercel Pro + external PostgreSQL + private object storage | Requested host; managed deploys; no server to patch | Several paid components; serverless pooling and RLS behavior; storage adapter and scanning limits; vendor pricing must be rechecked |
| Single VPS running the existing Docker Compose stack (app, PostgreSQL, local private storage) | Persistent disk; simple PostgreSQL and RLS; one bill; the Compose stack already exists | The clinic or its developer operates OS patching, TLS, backups, monitoring and restores; single point of failure unless backups are off-host |
| Other managed platform with persistent disk | Less operations than a raw VPS | Cost and Django fit unverified; compare only if the first two fail |

Compare these at G11/G12 using current provider documentation and quotes; this table does not claim any price.

### Shared-chair scheduling specification

- The clinic has four dentists but only one chair. Chair capacity is one; dentist count does not multiply treatment capacity.
- Chair-required bookings are checked against every dentist's active bookings on that chair, not just against the selected dentist.
- Lock the chair resource and applicable dentist schedule in a deterministic order, then recheck overlaps. Competing creates/reschedules cannot both claim the chair.
- Apply the same protection to walk-in bookings, extensions and status changes that begin chair use. Track the actual occupied chair as well as planned times.
- Include a configurable turnaround/cleaning buffer in the reserved interval; its duration is a clinic decision, not an invented clinical standard.
- Dentist availability remains a separate constraint. A free chair does not mean a dentist is available.
- A non-chair consultation can overlap chair use only when its service/resource configuration permits it and its dentist is available.
- No role can override physical concurrent occupancy of the one chair. Schedule exceptions must move/shorten a reservation, choose a permitted non-chair service, or arrange a later slot; reasons remain audited.
- Service duration and clinic working hours remain configurable; do not assume all four dentists are present at once.

The approximately five-patient daily workload suggests a simple interface and modest initial infrastructure. It does not establish measured performance, provider-plan eligibility or adequate backup coverage.

## 5. Proposed entity and relationship plan

All tenant-owned entities carry a clinic foreign key, UUID, timestamps and attribution as appropriate. Posted records preserve original amounts and references. A UUID is an identifier, not an authorization mechanism.

### Identity and clinic

| Entity | Key fields and relationships |
| --- | --- |
| User | Global login identity using Django password handling; active flag |
| Clinic | Tenant identity, name, contact, timezone, currency, active status |
| ClinicSettings | Invoice policies, numbering rules, fiscal-year label, print branding |
| ClinicMembership | User + Clinic, active status; unique pair |
| Role / MembershipRole | Clinic-role permissions and grants; supports more than one role |
| DentistProfile | One-to-one eligible membership; license/reference, specialization |
| Chair | Clinic-owned resource, code, active status |
| Availability / ScheduleBlock | Dentist/chair/clinic-wide availability, closures (including festival days) and blocked intervals |
| DocumentSequence | Clinic + document type + configured period (fiscal-year boundaries from reviewed BS calendar data); locked counter |

User 1:N Membership; Clinic 1:N Membership; Membership 0:1 DentistProfile. Staff roles never bypass active membership checks.

### Patient and appointments

| Entity | Key fields and relationships |
| --- | --- |
| Patient | Clinic, patient_no, name, optional DOB or age estimate, contact, active/merged status |
| PatientContact / Guardian | Patient, relationship, contact fields, authority details |
| MedicalHistoryRevision | Patient, history/allergies, author and review time; preserve prior revisions |
| PatientAlert | Patient, type/severity, active dates, responsible author |
| Appointment | Patient, dentist membership, optional chair, start/end, status, reason |
| AppointmentEvent | Appointment, previous/new time or status, actor and reason |
| Visit | Patient, optional unique appointment, responsible dentist, started/completed/signed times |

Patient 1:N Appointment and Visit. Appointment 0:1 Visit; Visit may exist without an appointment for a walk-in. Chair-required bookings must reference the clinic's single chair; non-chair consultations may omit it only under an approved service rule. Do not require unique phone numbers: a family may share one. Patient numbers are unique within clinic. Duplicate detection warns; it does not silently merge people.

### Clinical and treatment

| Entity | Key fields and relationships |
| --- | --- |
| ClinicalNoteRevision | Visit, text/structured examination, author, signed_at, amendment_of, reason |
| Diagnosis | Visit, clinician-entered code/name, notes |
| ToothReference | Global supported tooth identifier and dentition; chart standard fixed for pilot |
| ToothFinding | Patient, visit, tooth, condition, observed time, clinician; supersession/resolution event |
| FindingSurface | Finding and normalized surface; supports several surfaces |
| Service | Clinic, code, category, standard price, active, billability/tax configuration |
| TreatmentPlan | Patient, originating visit, current revision pointer, lifecycle status |
| TreatmentPlanRevision | Plan, immutable submitted/accepted version, validity and acceptance evidence |
| TreatmentPlanItem | Revision, service, price snapshot, quantity, item status, proposed clinical scope, optional alternative_group (mutually exclusive options) |
| PlanItemTooth | Plan item + tooth; optional surface links as needed |
| Procedure | Patient, service, responsible dentist, optional originating plan item, lifecycle |
| ProcedureTooth | Procedure + tooth; supports multi-tooth and no-tooth services |
| ProcedureSession | Procedure + Visit, clinician, work performed, completion evidence |
| BillableCharge | Procedure/session source, quantity/value approved for billing; source uniqueness |
| LabOrder (proposed, D17) | Procedure or plan item, lab name, work type, sent/due/received dates, status, internal cost note (not patient billing); lets deposit rules refer to real lab commitments |
| Prescription / PrescriptionItem | Visit, author, signed version; drug, dose, route, frequency, duration, instructions |
| ConsentRecord | Patient, relevant plan/procedure, template/version, guardian if applicable, evidence |

One TreatmentPlan has many revisions; a revision has many items. A plan item can produce many procedures; each procedure references at most one originating item in the pilot. A procedure can span several visits through ProcedureSession. No uncontrolled many-to-many link between plan items and procedures.

Do not automatically make a procedure session billable. The approved service policy determines whether billing happens on final completion or at explicit milestones. Include full-mouth services, mixed dentition and multiple teeth in clinic review. Proposed pilot tooth numbering: one fixed FDI-style chart, subject to dentist sign-off, rather than a user-switchable standard.

### Finance and controls

| Entity | Key fields and relationships |
| --- | --- |
| Invoice | Patient, unique clinic/period number, issue date, due date, status, currency, immutable issued totals |
| InvoiceItem | Invoice, service snapshot, description, quantity, unit price, discount/tax snapshot, discount reason and approver when above the configured threshold |
| InvoiceChargeLink | Invoice item + billable charge; quantity/value consumed; prevents duplicate billing |
| CreditNote / CreditNoteItem | Original invoice/line, approved reduction, reason code (e.g. pricing correction, clinical cancellation, approved write-off), issue reference |
| Payment | Patient, receipt number, received date, original amount, payment method/account, actor |
| PatientCredit | Traceable source pool; one per ordinary Payment in this release; future opening-source support deferred |
| Allocation | PatientCredit + Invoice, positive amount, actor, posted time |
| AllocationReversal | Original Allocation, reversed amount, reason, actor; no deletion |
| Refund | PatientCredit, requested amount, status, method/account, requester/approver/payment evidence |
| RefundReservation | Refund + credit source, reserved amount; prevents concurrent use while approved/pending |
| ReceiptReversal | Payment, reason, source events and control evidence; unwinds receipt effects |
| CashBankAccount | Clinic account, method mapping, active flag |
| ReconciliationBatch / ReconciliationItem | Account/date, expected collections/refunds, verified amount, variance and closure |
| ImportBatch / OpeningBalanceEntry — deferred | Future historical import only; not created for this new-clinic release |
| AuditEvent | Actor membership, clinic, action, entity, reason, protected change detail, timestamp/request ID |
| IdempotencyRecord | Clinic + operation + retry key, request hash and result reference |

Clinic 1:N each implemented finance entity. Patient 1:N Invoices, Payments and PatientCredits. Payment 1:1 ordinary PatientCredit. PatientCredit 1:N Allocations and Refunds. Invoice 1:N Allocations and CreditNotes. CashBankAccount 1:N receipts/refunds/reconciliation batches.

**Explicit schema change requiring approval:** replace separate PaymentAllocation and CreditAllocation writes with Allocation. A UI action may be called “pay invoice” or “apply advance,” but both use the same source funds. All receipts briefly enter their own traceable source pool; immediate payment plus allocation commits atomically. This avoids two spending mechanisms. If retaining the original two tables is preferred, an equivalent shared source-funds constraint and cross-table locking design must be approved instead.

### Database and validation controls

- Cross-clinic foreign keys: validate in services and enforce with composite reference constraints or reviewed database triggers. Ordinary foreign keys plus RLS are insufficient for tenant-consistent links.
- Same-patient consistency: invoice allocations, refunds, visit attachments and treatment links must agree on patient.
- Positive posted receipt/allocation amounts; valid times; bounded discounts/refunds; fixed currency per clinic in the pilot.
- Unique patient/service/document numbers at their intended clinic/period scope.
- One appointment-linked visit; one ordinary credit source per payment; no duplicate source charge billing.
- PROTECT historical references. Deactivate catalog/staff records instead of deleting used records.
- Index clinic with patient search fields, appointment start/dentist, invoice due date/status, credit source and audit time.
- Deterministic lock order for clinic counters, source credits and invoices to reduce deadlock risk.
- No manual edits to balances, signed notes, issued invoice lines or posted receipt amounts.

## 6. Financial specification to approve before coding

### One source of funds

For each ordinary receipt source:

`original received amount = active allocated amount + completed refunds + remaining unallocated credit`

Active allocated amount means posted allocations less their posted reversals. Pending refund reservations are part of remaining unallocated credit, but unavailable for new allocation. A reversed receipt must have its source effects unwound; it is excluded from active receipt totals while preserving history. Opening-credit sources are out of scope for this release (see Defer).

`spendable credit = remaining unallocated credit - active refund reservations`

For an invoice:

`adjusted charge = issued total - issued credit notes`

`outstanding = adjusted charge - active allocations`

The service must release surplus allocations when a credit note reduces a paid invoice, so outstanding never becomes negative. Tax/rounding policy affects issued totals and must be fixed first.

### Required behavior

| Scenario | Expected posted result |
| --- | --- |
| NPR 15,000 invoice; NPR 5,000 received | Invoice outstanding 10,000; credit available 0 |
| Later receipt NPR 10,000 | Separate original receipt; invoice outstanding 0; no new sale |
| NPR 20,000 advance, no invoice | Collections 20,000; available credit 20,000; invoiced value 0 |
| NPR 15,000 completed charge against that advance | Invoice outstanding 0; available credit 5,000 |
| NPR 12,000 receipt for NPR 10,000 due | Invoice outstanding 0; available credit 2,000 |
| New NPR 20,000 invoice, existing NPR 5,000 credit | Outstanding remains 20,000 and credit 5,000 until explicit allocation |
| Allocate that NPR 5,000 | Outstanding 15,000; available credit 0 |
| Refund NPR 5,000 unused credit | Original receipt retained; completed refund 5,000; credit reduced by 5,000 |
| Reduce fully paid NPR 15,000 invoice by NPR 5,000 | Issue credit note 5,000; release allocations 5,000 to original source pool; adjusted invoice settled at 10,000 |
| Reduce NPR 15,000 invoice with only NPR 5,000 allocated by NPR 5,000 | Adjusted charge 10,000; remaining due 5,000; no automatic cash refund |
| Browser retries receipt submission | Same result returned once; no second receipt |
| Two staff try to spend NPR 5,000 credit at the same time | Lock source and recheck; combined allocations/refunds cannot exceed source funds |
| Source NPR 20,000: 15,000 allocated to an invoice, 5,000 refunded (completed); then a 5,000 credit note on that invoice | Adjusted charge 10,000; 5,000 allocation released to the source; 20,000 = 10,000 allocated + 5,000 refunded + 5,000 remaining |
| Reverse a receipt that still has active allocations | Rejected until each allocation is explicitly reversed; the invoice outstanding then rises, and the receipt reversal removes the source and the collection |
| Reverse a receipt after part of it was refunded | Rejected; returned money follows the refund workflow |
| NPR 10,000 invoice balance judged uncollectable | Approved write-off credit note 10,000 with write-off reason code; outstanding 0; no cash movement; reported as a write-off, not as a collection or price correction |

A refund request does not prove cash left the clinic. Approved/pending refunds reserve funds; completed refunds reduce credit and enter cash reports. Rejected/cancelled requests release the reservation. Actual bank/QR receipt verification is separate from simply typing a payment reference.

### Corrected patient statement

Positive net balance means patient owes; negative means net credit. Allocations have zero effect on this net position.

| Date | Event | Charge / refund | Receipt / charge reduction | Net balance |
| --- | --- | ---: | ---: | ---: |
| Oct 1 | Advance received | 0 | 20,000 | -20,000 |
| Oct 5 | RCT invoice | 15,000 | 0 | -5,000 |
| Oct 5 | Allocate 15,000 to RCT — informational | 0 | 0 | -5,000 |
| Oct 20 | Crown invoice | 20,000 | 0 | 15,000 |
| Oct 20 | Allocate remaining 5,000 — informational | 0 | 0 | 15,000 |

Before the final allocation: invoice outstanding 20,000; available credit 5,000; net balance 15,000. After it: outstanding 15,000; available credit 0; net balance still 15,000. This corrects the source document's final 10,000 due and the double-counting risk in its allocation columns.

Always show **invoice outstanding**, **available unallocated credit**, **reserved credit**, and **net position** separately. A net credit alone must not hide an unpaid invoice. Allocation detail can appear beneath the statement or in zero-effect rows.

### Posting controls

1. Authenticate and confirm active clinic membership and action permission.
2. Validate server-side clinic, patient, currency and posted state.
3. Validate a retry key; reject the same key with different input.
4. Begin one database transaction; lock relevant sources and invoices.
5. Recompute available amounts and outstanding after locks.
6. Write immutable posting events, reversals if any, and an audit event.
7. Update controlled summaries and commit; trigger printing/notifications only after commit.

Use Django atomic transactions and row locks [S2, S3]. Test concurrency with PostgreSQL and transaction-aware tests; a fast ordinary unit test alone does not demonstrate safe competing writes.

### Policies still unapproved

- Invoice timing: review the proposed service-specific defaults in section 6A; completion and agreed earned milestones must be documented.
- Allocation default: recommended user confirmation with suggested oldest-due invoices; no silent offset.
- Deposit restrictions: usable for any treatment or reserved to a plan.
- Refund approval: recommended Owner approval; clinic-specific limits and whether sole owner may execute own approval.
- Discount thresholds and who can authorize below-standard prices.
- Write-off authority, limit and approval separation.
- Fallback approval rules when the clinic is too small for separate roles (see section 8).
- Receipt mistakes versus actual returned money; correction cutoffs after reconciliation closure.
- Amount precision, line/document rounding and tax-inclusive/exclusive prices.
- Credit-note format, invoice numbering, retention and Nepal billing requirements: verify before approval; no fixed legal claims or tax rates are assumed here.

## 6A. Proposed dental billing defaults

The user requested industry practice rather than an existing clinic policy. ADA practice-management guidance describes several accepted choices: payment when services are rendered, multi-visit treatment with an initial deposit and payment by completion, alternative agreed schedules, and optional full prepayment [S13]. It emphasizes a clear written policy presented before extensive treatment. This supports configurable billing; it does not establish a universal deposit percentage or a Nepal tax rule.

### Proposed pilot policy — requires approval

| Treatment category | Patient payment arrangement | Billable amount / invoice rule |
| --- | --- | --- |
| Consultation, filling, scaling or another single-visit service | Payment due at the service visit | Invoice the actually completed service; due date defaults to that visit |
| Multi-visit treatment, such as a root-canal course | Written estimate and agreed advance; remaining collection scheduled through treatment, normally settled by completion | By default invoice completed procedure; use separately approved earned milestones if the clinic chooses staged invoicing |
| Lab-dependent crown/denture work | Agreed deposit before committing fabrication costs, amount set by clinic policy | Deposit stays patient credit; invoice only completed work or an explicitly agreed billable milestone, not solely because cash was received |
| Long-duration treatment/installments | Written schedule, installments and completion/payment terms | Deferred unless offered at launch; do not turn every installment into a new sale for the full package |
| Partial payment / approved exception | Remaining invoice stays outstanding with due date and promise-to-pay note | No automatic write-off or mandatory new invoice |
| Voluntary full prepayment | Receipt for full funds with estimate/acceptance reference | Unused funds remain patient credit until allocated or refunded |

Recommended launch controls:

1. Provide an estimate and explain payment terms before planned treatment; retain acceptance of that plan version and terms.
2. Configure deposit amount as a fixed amount or percentage per approved service/plan, with **no universal percentage prefilled**.
3. Keep invoice timing separate from cash collection timing. Uncompleted-work money remains an advance in the operational ledger, subject to verified local invoicing requirements.
4. Suggest available advance when an invoice is issued; require explicit confirmation before allocating it.
5. A staged package cannot be charged twice. Cumulative billable milestones and the final remainder must reconcile to the accepted package price or a documented price amendment.
6. Do not automatically charge interest, late fees, no-show penalties, cancellation fees or discounts. Enable only after a specific reviewed policy.
7. Refund unused source credit only through the documented approval/completion workflow; review completed work and agreed lab commitments when a plan is cancelled.
8. Collect by cash, bank transfer or QR only where the clinic actually supports that method; staff verify receipt evidence before posting.
9. Plan cancellation or treatment interruption does not itself erase invoice debt or justify retaining all unspent advance.
10. Dentist validates which stage represents completed billable work. Software must not invent clinical milestones.

Example: an accepted treatment package is NPR 30,000 and the agreed advance is NPR 10,000. Receiving it creates NPR 10,000 patient credit. If an approved completed milestone is NPR 8,000, issue that charge and explicitly apply NPR 8,000. Credit remaining is NPR 2,000; uncompleted estimated work of NPR 22,000 is not automatically an invoice receivable. These illustrative amounts are not clinic prices or recommended industry percentages.

## 7. Workflow state machines

| Record | Proposed states / rules |
| --- | --- |
| Appointment | SCHEDULED → CONFIRMED → ARRIVED → IN_TREATMENT → COMPLETED; permitted CANCELLED/NO_SHOW alternatives. Rescheduling appends an event and changes the booking; it is not an unexplained terminal status. A chair overrun sets a non-terminal DELAY_RISK flag on the next appointment (a flag, not a status). |
| Visit | OPEN → CLOSED. Note signing is separate (ClinicalNoteRevision DRAFT → SIGNED); closing a visit neither signs nor invoices. Later correction of a signed note creates an amendment. Walk-ins allowed. |
| Plan revision | DRAFT → PROPOSED → ACCEPTED / PARTIALLY_ACCEPTED / REJECTED / SUPERSEDED. Acceptance refers to a specific version. |
| Plan item | PROPOSED → ACCEPTED → SCHEDULED → IN_PROGRESS → COMPLETED; explicit REJECTED/CANCELLED. Plan header derives progress from items. |
| Procedure | PLANNED → IN_PROGRESS → COMPLETED; CANCELLED with reason. Sessions document each visit. |
| Invoice | DRAFT → ISSUED, or DRAFT → DISCARDED (never issued; no number consumed). Settlement state UNPAID/PARTIALLY_PAID/PAID derived independently. Issued invoices are never voided; corrections, including full cancellation, use credit notes. A VOID state is added only if local billing verification (G10) requires it. |
| Receipt | POSTED → REVERSED with explicit events and reason; refund does not turn the entire receipt into a reversed receipt. Reversal requires no active allocations and no completed refunds. |
| Refund | REQUESTED → APPROVED → COMPLETED; REJECTED/CANCELLED/FAILED handled explicitly, with reservation policy. |
| Reconciliation batch | OPEN → VERIFIED → CLOSED; reopening restricted and audited. |

Every transition has an allowed actor, validation, reason where needed and audit record. A completed appointment does not automatically sign clinical notes or issue an invoice. Cancelling a plan does not delete completed procedures, billed charges or money already received.

## 8. Proposed permission matrix

O = Owner/Admin; D = Dentist; R = Receptionist; A = Accountant; S = Assistant.

| Action | O | D | R | A | S |
| --- | --- | --- | --- | --- | --- |
| Manage staff/clinic settings | Yes | No | No | No | No |
| Register/update demographics | Yes | Yes | Yes | View billing identity | Limited view |
| Schedule/check in | Yes | Own schedule | Yes | View | Assigned support |
| Override dentist scheduling policy | Explicit grant + reason | Explicit grant + reason | No by default | No | No |
| Override occupied single-chair capacity | No | No | No | No | No |
| View detailed clinical records | Only if clinician, explicit clinical grant or audited break-glass | Care scope | Minimum alerts only | No | Assigned care scope |
| Draft clinical support notes | Only with clinical grant | Yes | No | No | Yes, cannot sign |
| Sign/amend clinical record | Licensed clinical role | Own record; other clinician by policy | No | No | No |
| Create treatment estimates | Approved grant | Yes | No by default | Financial view | No |
| Complete procedure/prescribe | Licensed clinical role | Yes | No | No | No |
| Create invoice draft | Yes | From approved charges | Yes | Yes | No |
| Issue invoice | Yes | Optional grant | Standard prices/policy | Yes | No |
| Receive verified payment/advance | Yes | No by default | Yes | Yes | No |
| Allocate available credit | Yes | No by default | Within policy | Yes | No |
| Request refund | Yes | No | Yes | Yes | No |
| Approve refund/credit note | Yes | No | No | Explicit grant; separation policy | No |
| Complete approved refund | Yes | No | No by default | Yes | No |
| Close daily reconciliation | Yes | No | Own batch submission | Yes | No |
| View full financial reports | Yes | Own attributed work only | Own collections/basic operations | Yes | No |
| Bulk export patient/financial data | Explicit grant | No by default | No | Explicit finance grant | No |
| View audit | Clinic oversight | Own clinical history | No by default | Financial scope | No |

Change from the source: ownership does not automatically grant unrestricted clinical access. A dentist-owner gets clinical rights through the clinician role. Confirm this with the pilot clinic.

**Small-clinic fallback (decision D07):** with about five patients a day there may be no separate accountant, and the owner may also be a dentist. Define in advance who approves refunds, credit notes and write-offs when approver and requester would be the same person (for example: sole owner may approve with a mandatory reason, every self-approved item appears on a monthly owner review report, and amounts above a configured limit need a second named person). Do not leave this to a hidden default.

Super Admin manages platform operations, not unrestricted patient browsing by default. Any exceptional support access must be explicitly granted, time-limited, justified and audited. Permission checks apply to lists, details, search, downloads, print, exports and mutations.

## 9. Screens and wireframe requirements

| Screen | Required content / behavior |
| --- | --- |
| Reception dashboard | Today's calendar, arrival queue, search, check-in and verified receipt shortcuts |
| Dentist dashboard | Assigned appointments, open visits, medical alerts, pending plan/procedure work |
| Patient registration | Search first, duplicate warning, guardian, minimum mandatory data |
| Patient workspace | Stable identity header; Overview, Visits/Chart, Plans, Billing/Payments, Documents and Prescriptions |
| Calendar | Dentist/chair filters, blocked slots, overlap warning, cancel/reschedule reasons |
| Visit | History review, examination, findings, diagnosis, draft/sign controls, amendment history |
| Tooth chart | Adult/child/mixed view, orientation labels, surfaces, timeline, condition and treatment legend |
| Treatment plan | Version, tooth/service items, estimate vs completed/billed totals, acceptance evidence |
| Invoice | Unbilled sources, price snapshots, discounts, due date, printable issued document |
| Receive money | Choose invoice payment or advance; selected invoices, credit remainder preview, account/reference |
| Apply credit | Source receipt, spendable credit, target invoices, allocation preview and confirmation |
| Refund | Source, reservation, approver, return method, completion evidence and reason |
| Statement | Separate due/available/reserved balances; chronological postings and allocation detail |
| Reconciliation | Cash/bank/QR totals, refunds, verification, variance, close/reopen audit |

Before coding, review low-fidelity wireframes for patient registration, calendar, visit/chart, plan, invoice/payment, statement/refund and daily reconciliation. Include empty/loading/error states, keyboard use, readable print output and phone/tablet layout. A clinical chart must communicate status with labels or patterns as well as colors.

Proposed common task targets for usability review: locate patient in under 15 seconds; record a routine verified receipt in under 30 seconds; make a standard appointment in under 45 seconds. These are design targets, not measured results.

## 10. API contract plan

This section defines the action contract. It applies to the service layer first; exposing it as JSON HTTP endpoints is optional (section 4, API row) and should wait for a real consumer. Where endpoints exist, ordinary catalogue/draft records may use CRUD. Posted money and signed clinical records use explicit actions. No generic update endpoint may bypass a financial service.

| Endpoint group | Principal operations |
| --- | --- |
| `/api/v1/auth/` | Login/logout, password change/reset, session information |
| `/api/v1/clinic-memberships/` | Authorized membership list, role grant/revoke, active clinic selection |
| `/api/v1/patients/` | Create, scoped search, detail, demographic update, controlled duplicate review |
| `/api/v1/appointments/` | List/create, confirm, arrive, start, complete, cancel, no-show, reschedule |
| `/api/v1/visits/` | Open, update draft, sign, amend, history |
| `/api/v1/patients/{id}/dental-chart/` | Current projection and findings history |
| `/api/v1/tooth-findings/` | Add finding, resolve/supersede with attribution |
| `/api/v1/services/` | Catalogue, controlled price update, deactivate |
| `/api/v1/treatment-plans/` | Draft revision, propose, accept items, supersede, cancel |
| `/api/v1/procedures/` | Create, start, add session, complete, approve billable charge |
| `/api/v1/prescriptions/`, `/consents/` | Draft, sign/record evidence, amend, authorized print |
| `/api/v1/invoices/` | Draft/create from charges, issue, preview, print, read settlement |
| `/api/v1/credit-notes/` | Propose, approve/issue, read; reference original invoice |
| `/api/v1/payments/` | Receive with optional immediate allocation; read; controlled reverse |
| `/api/v1/patient-credits/` | Source balances and spendable amounts; read only |
| `/api/v1/allocations/` | Post and explicit reverse, with retry key |
| `/api/v1/refunds/` | Request, approve/reject, complete/fail/cancel |
| `/api/v1/reconciliations/` | Open, verify, close, controlled reopen |
| `/api/v1/documents/` | Upload, scan status, authorized download, new version |
| `/api/v1/reports/` | Statement, ageing, collections, credits, charges, clinical/operational summaries |
| `/api/v1/audit-events/` | Protected scoped read; no user write/update/delete |
| `/api/v1/import-batches/` — deferred | Not part of the new-clinic release; implement only if historical import is later authorized |

For each actual endpoint, approve request/response fields, action permission, validation, pagination, audit behavior and error codes before its phase. Return 401 for no session, 403 for denied actions, 404 for foreign-clinic object lookup, 409 for stale/conflicting state and validation errors with field details. Clients never choose their clinic by an unverified payload field. Use revision/version tokens for concurrent edits. Browser forms call the same services as API endpoints.

## 11. Reports and reconciliation definitions

| Metric/report | Proposed definition |
| --- | --- |
| Gross invoiced value | Issued line charges before discounts/tax adjustments per approved definition |
| Net invoiced service value | Issued charges less discounts and issued credit notes, excluding tax |
| Collections | Verified posted receipts in local date range, excluding reversed receipts |
| Refunds paid | Completed refunds in local date range; pending requests shown separately |
| Net cash movement | Collections minus completed refunds; by cash/bank account |
| Receivables | Adjusted issued charges less active allocations, by invoice |
| Overdue | Positive invoice balance with due date before report as-of date |
| Ageing | By due date: current, 1–30, 31–60, 61–90, 91–120, over 120 days |
| Patient credits | Remaining source credit and spendable/reserved breakdown |
| Write-offs | Issued credit notes with the write-off reason code; shown apart from collections and from pricing corrections |
| Dentist service value | Invoice line/source attribution to responsible dentist; mixed work split by approved rule |
| Dentist collections | Allocation attribution by source line only if a rule is approved; never all receipt value to one dentist |
| Treatment pipeline | Proposed/accepted/pending/completed work, excluding superseded revisions |

Label dashboard service value as “invoiced service value” until the clinic approves its revenue-recognition policy. Cash received, estimated plan value and invoiced value are different measures. A receipt allocation is not another collection.

Reports accept clinic-local date/as-of filters, show their calculation basis and reconcile to detail. Reconciliation batches must avoid overlapping receipt coverage. QR/bank references support human verification first; no bank integration is assumed.

Accounting exports: patient identifiers, document references/dates, net charges, tax/discount, account/payment method, receipts, allocations, credit notes and refunds in CSV/XLSX. Agree the destination accounting system and account mapping before export development. These exports are not a substitute for a full general ledger.

## 12. Nepal configuration and policy verification

Confirmed planning defaults: NPR, Asia/Kathmandu, English interface initially with Nepali text support, AD storage and optional BS display. Language and print preferences still need confirmation.

Before billing approval, collect dated primary-source evidence and clinic facts for:

- Applicable patient invoice/receipt fields and tax registration status.
- Treatment of each offered service for invoice/tax configuration; do not assume one tax rate covers everything.
- Whether the intended electronic billing setup needs a specific registration/approval or integration.
- Fiscal year, numbering rules, issued-document correction and retention requirements.
- Patient privacy, consent, guardian authority, record access and clinical-record retention.
- Hosting location/access expectations and permitted export/support arrangements.

### Localization items to design now and confirm with the clinic

- **Fiscal year:** Nepal's fiscal year follows the Bikram Sambat calendar (Shrawan to Ashadh), so document-sequence periods cannot be computed from AD dates by formula. Use a reviewed BS calendar data table, and test period rollover.
- **Working week:** the usual weekly holiday is Saturday, so default availability must not assume a Saturday–Sunday weekend. Make the working days a clinic setting and confirm the real ones.
- **Closures:** festival days (for example Dashain, Tihar) are clinic-wide ScheduleBlocks, not per-dentist leave.
- **Timezone:** Asia/Kathmandu is UTC+05:45. Add explicit tests at the local-midnight boundary and for any report that groups by local day.

This is a verification workstream, not a claim that a particular law, exemption, percentage or product certification applies. Record “verified,” “not applicable with reason,” or “unresolved” for each before pilot approval. Configure rates and rules only after verification.

## 13. Documents, security and operations

- Patient files remain private; clinic/role/patient checks apply before viewing/downloading.
- Limit upload type/size, inspect actual file signatures, use generated storage keys, quarantine until validated (antivirus scanning per decision G12), and prevent executable content from being served.
- Pilot images/PDFs only; define maximum sizes with the clinic. Existing device-specific X-ray formats need a sample before support is promised.
- Upload replacements create versions; retain metadata and audit. Define deletion/retention policy before real patient data is recorded.
- TLS, secure cookies, CSRF, protected password reset, login rate limiting and privileged-user MFA are proposed baseline controls.
- Use separate development/staging/production environments. Development data is synthetic unless explicitly approved and protected.
- Audit financial/clinical changes, sensitive export/download actions and views of clinical records (who opened which patient, when). An owner without a clinical grant may use a reasoned, audited break-glass view. Keep clinical detail out of general logs; restrict audit details by role.
- Back up database and document bytes as a consistent set; protect encryption keys and restore instructions separately.
- Proposed pilot recovery goals: restore service within 4 hours; maximum 24 hours of lost data with daily backups. Clinic must approve whether that potential loss is acceptable; if not, use more frequent/PITR database backups and matching file protection.
- Require one successful full restore rehearsal before real clinic use, including document retrieval and finance reconciliation.
- Monitor uptime, failed logins, app errors, storage, backup freshness and financial consistency checks.
- Run Django deployment checks and review official production settings [S5].
- An application audit table is append-only for ordinary application users; it is not tamper-proof against a database administrator. Stronger evidence retention requires protected external copies and operational controls.

Internet outages: first release does not queue offline financial/clinical writes. Approve a numbered paper downtime process and subsequent controlled entry to avoid duplicate receipts and missing treatment records.

## 14. New-clinic setup and launch plan

No historical records or opening balances exist. Do not build a migration/import subsystem for this pilot.

1. Configure clinic identity, NPR, timezone, fiscal period and reviewed document formats.
2. Create four individual dentist accounts plus owner/reception/finance accounts according to actual staffing. Never share dentist credentials.
3. Configure exactly one active chair, dentist availability and chair-required service rules.
4. Enter the approved service catalogue, durations, prices, billable milestones and payment policies. No invented clinical prices.
5. Set patient receivables and patient advances to zero. This concerns the patient subledger only; it does not claim the clinic itself has no assets, capital or other accounting balances.
6. Test with synthetic patients in a separate test environment; exclude them from production.
7. Validate the complete visit-to-payment journey, simultaneous chair booking attempts and daily reconciliation.
8. Rehearse backups/restoration, downtime records and refund approval.
9. Run a controlled pilot. If paper records are maintained in parallel, define which record controls live receipt numbering to avoid double issuance.
10. Obtain approval for live use; begin real registration and receipt entry from the agreed opening date.

Future imports require a separately authorized phase with dry-run validation, duplicate matching, original source references, opening credit/receivable separation and financial reconciliation.

## 14A. Post-launch operations and maintenance

The plan otherwise ends at go-live. Before the pilot is approved, name an owner for each item below and record the cost.

| Area | Decision needed |
| --- | --- |
| Platform ownership | Who applies Django, Python, PostgreSQL and dependency security patches, and how often |
| Incident response | Who is contacted when the system is down or a posting looks wrong; clinic downtime process (D13) |
| Backups | Who checks backup freshness and runs periodic restore tests |
| Support | Hours, channel and response target for staff problems; how change requests are approved |
| Recurring cost | Hosting, database, storage, backups, monitoring and developer time, stated as a monthly figure |
| Exit | How the clinic exports its own data if it changes developer or host |

## 15. Canonical module-based phase map

Detailed execution steps are in section 21. This sequence supersedes the conflicting phase numbering in the source PDF and previous drafts. Security/audit/tests are included throughout; final hardening verifies them rather than introducing them.

| Phase | Modules / deliverable | Gate |
| --- | --- | --- |
| 0 | Design, independent reviews and approval | User approves specific plan/version and implementation scope |
| 1 | Foundation only: project, PostgreSQL/Docker, custom User infrastructure, settings/templates, health/logging/tests | Repeatable technical skeleton, no business functionality |
| 2 | User and Admin/Clinic; tenant/permission enforcement | Login, active memberships, scoped admin and isolation tests |
| 3 | Doctor and Service catalogue | Four configurable dentists, availability, one chair and reviewed services |
| 4 | Patient | Search/registration/workspace, history revisions and guardian support |
| 5 | Appointments/Reception | Single-chair resource/concurrency controls and queue |
| 6 | Clinical Visits, Dental Chart and secure Documents minimum | Signed/amended history, dentist-reviewed chart, protected attachments |
| 7 | Treatment/Procedures, Prescriptions/Consent | Accepted revisions, actual sessions, consent and unique billable sources |
| 8 | Billing/Payments/Credit | All financial scenarios, locks, retries, corrections and refunds pass |
| 9 | Accounting/Reconciliation and Reports | Daily close, statement/ageing, exports and summary/detail agreement |
| 10 | Production readiness/hosting validation | Host cost decision, security, storage, monitoring and restore evidence |
| 11 | Controlled pilot/go-live | Explicit live-use approval, staff acceptance and reliable daily operation |

Each phase implements database changes, services, authorized UI/API, audit, validation and appropriate tests together. No phase is completed by merely generating screens. Durations are not promised without approved service definitions and implementation environment.

**Minimum approval to start Phase 1:** G02 and G03 plus local-only scope. Later gates (G04–G14) are required only before the phase they block; they need not delay the foundation.

**Early operational milestone (optional):** after the Phase 5 gate, staff may use patient registration and scheduling on synthetic data in staging. Live use of scheduling alone, with paper billing continuing, is a separate explicit approval. Nothing financial goes live before Phase 8 and Phase 10 gates.

**Long-lead workstreams to start in Phase 0 and run in parallel:**

| Workstream | Gate | Needed by | Owner |
| --- | --- | --- | --- |
| Real doctor names, availability, service list and prices | G07 | Phase 3 | Clinic owner |
| Nepal invoice, tax, e-billing and retention verification | G10 | Phase 8 design | Clinic owner / accountant |
| Hosting option comparison and cost decision | G11, G12 | Phase 2 spike; decision before Phase 10 | Clinic owner / developer |
| Accounting export destination and mapping | G13 | Phase 9 | Accountant |
| Post-launch ownership and cost | G16 | Phase 10 | Clinic owner |

### Database dependency order

1. Phase 1: custom User first migration and framework tables; no business module schema.
2. Phase 2: Clinic/Membership/Role grants, settings/numbering, audit/retry/context infrastructure, resource Chair.
3. Phase 3: doctor profile/availability/blocks and service catalogue/policy definitions.
4. Phase 4: Patient, contacts/guardians, medical-history revisions/alerts.
5. Phase 5: Appointment and events; chair occupancy source references completed when Visit exists in Phase 6.
6. Phase 6: Visit/notes/diagnoses first, then findings/surfaces/history, then document metadata and authorized links.
7. Phase 7: plan revisions/items and procedure skeleton, consent/prescription records, session completion guards and billable sources. M09/M10 integrate in this order to avoid circular creation dependencies.
8. Phase 8: money account configuration, Invoice/lines/source links and CreditNotes, then receipt sources, allocations/reversals/reservations/refunds. Cross-app migration dependencies are explicit and non-circular.
9. Phase 9: reconciliation/export records, report indexes; no historical import subsystem.
10. Phase 10: production policy/index refinements through reviewed non-destructive migrations.

A parent pointing to its current revision/version is created with a nullable pointer initially, then linked by a later migration/service to avoid circular schema dependencies. Backfilled constraints are verified before being made non-null where required. Posted financial records are not dropped to repair migrations.

## 16. Acceptance test catalogue

| Area | Cases that must be demonstrated |
| --- | --- |
| Tenancy | Clinic B blocked through list/detail/search/API/forms/print/export/files; malicious cross-clinic FK; missing tenant context; connection reuse; context isolation behind a transaction-mode pooler |
| Permissions | Reception cannot read full clinical notes or sign prescriptions; assistant cannot sign; inactive member blocked; support access audited; clinical-record views audited; break-glass needs a reason and is logged |
| Patient | Shared family phone; estimated age; guardian; duplicate warning; safe merge review |
| Appointments | Concurrent overlapping booking; single-chair conflict across different dentists; actual chair occupancy; adjacent slots plus buffer; blocked leave; authorized dentist policy override only; reschedule history; walk-in; chair overrun flags the next appointment without auto-starting it; Saturday closure and festival block |
| Clinical | Adult/child/mixed chart; several surfaces; previous history; signed-note immutability; amendments; alert acknowledgement |
| Treatment | Partial acceptance; plan revisions; no-tooth service; multiple teeth; procedure across visits; cancellation after partial work |
| Billing | Price/tax snapshots; discounts/rounding; invoice retry; duplicate source billing prevention; partial milestone charges |
| Funds | Partial/later payment; advance; overpayment; several invoices/sources; unallocated credit with unpaid invoice; cross-patient allocation denial |
| Corrections | Paid/unpaid credit notes; partial/full allocation reversal; receipt reversal; receipt reversal blocked while allocations or completed refunds exist; write-off credit note; credit note after a partial refund; source availability maintained |
| Refunds | Approval denial; amount limit; pending reservation; competing allocation/refund; failed completion; cancelled request; split-source refund if enabled |
| Reports | Corrected sample statement; as-of date; local midnight boundary; no duplicate allocation collection; source totals and reconciliation agree |
| New-clinic setup | No sample/test patient records in production; patient dues and advances start at zero; initial settings and staff verified |
| Files | Unauthorized retrieval; oversize/type mismatch; quarantine; replacement history; no public link |
| Recovery | Restore database and files; reconcile balances; retrieve documents; preserve audit history |
| User acceptance | Receptionist/dentist/accountant complete the entire approved journey without developer intervention |

Use real database transaction tests for competing writes, service tests for financial invariants and browser tests for the key patient journey. Test meaningful business behavior rather than replicating implementation details. Baseline pilot load is four dentists, one chair and approximately five patients/day. Test concurrent staff use and a reasonable accumulated synthetic history as well as daily throughput; no measured performance capacity is claimed yet.

## 17. Risk and decision register

| ID | Decision or risk | Proposed direction | Needed before |
| --- | --- | --- | --- |
| D01 | Exact pilot clinic/approvers | Named owner, dentist, reception and finance reviewers | Final design |
| D02 | Pilot capacity | Confirmed: four dentists, one chair, about five patients/day; one site assumed | Schema approval |
| D03 | Receipt/allocation source model | Unified Allocation | Financial schema |
| D04 | Signing and clinical access | Clinician signing; owner access by explicit grant | Permissions approval |
| D05 | Service completion/milestone billing | Proposed industry-aligned defaults in section 6A; service milestones and deposit amounts still reviewable | Treatment/finance approval |
| D06 | Nepal legal/tax/print policy | Dated verification; no guessed rates/approval claims | Billing approval |
| D07 | Refund/discount/void controls | Owner approval with configured limits | Finance approval |
| D08 | Chart orientation, numbering, mixed dentition | Dentist validates one pilot convention | Clinical approval |
| D09 | Prescription/consent templates | Use supplied clinic forms with versioning | Clinical approval |
| D10 | Existing data | Confirmed: new clinic, no records; remove historical imports from release | Resolved for pilot |
| D11 | Hosting/budget and restore targets | Vercel requested; no allocated budget; live commercial plan and external storage/backups unresolved; compare a self-managed VPS (section 4A) | Deployment design |
| D12 | Export accounting system | Agree account mapping and file columns | Export implementation |
| D13 | Internet reliability | Online pilot plus numbered downtime process | Pilot approval |
| D14 | UI and printed languages/BS dates | English-first with Unicode; optional BS display | Wireframes/printing |
| D15 | Record/file retention and exceptional support access | Explicit policy; no unrestricted default | Pilot approval |
| D16 | Post-launch ownership: patching, incidents, backups, support, monthly cost | Section 14A table completed | Pilot approval |
| D17 | Lab-order tracking and plan alternatives (proposed small additions) | Approve or defer with the dentists | Phase 7 |

Highest risks: incorrect financial conservation, inconsistent tenant references, dentist-unapproved clinical workflows, shared-chair overlap, unresolved commercial hosting cost, and backups that cannot restore files as well as database records. These have concrete tests/gates above.

## 18. Approval procedure and immediate next work

Planning continues with:

1. Review the corrections, first-release boundaries and proposed finance model.
2. Review proposed clinic forms and service/billing defaults; there are no existing records to request. Agree dentist working hours and shared-chair use.
3. Resolve D01–D17/G01–G16; review the screen contracts and field baseline in sections 22–24, and refine any remaining policy-dependent fields before their phase.
4. Complete dated local policy verification and hosting/cost options.
5. Produce an approved version of this master plan with decisions labeled APPROVED or OUT OF SCOPE; use its canonical phases and replacement AI-coder prompts rather than conflicting older phase instructions.
6. Request explicit approval of that version and implementation scope. Until received, remain in planning.

Final plan approval should identify the approved document version, first-release scope, financial examples, permissions, clinical workflow/chart, wireframes, environment and execution gates. A general agreement with one recommendation is not approval to start implementation.

Suggested eventual implementation instruction, to use only after approval:

> Implement only the authorized phase from the approved Dental Clinic module-based implementation master plan version [approved version]. Inspect the repository first. Preserve approved domain and financial rules. Use PostgreSQL and real tenant/role controls. Include migrations, functioning UI, services, audit and meaningful tests. Do not expand scope or bypass money-posting services. Report changes and test evidence, and stop at the agreed review gate.

## 19. Primary technical references

The architecture and workflow choices here are proposals; the references support framework/database mechanisms, not Nepal legal compliance or clinical policy.

- [S1] Django — Customizing authentication: https://docs.djangoproject.com/en/5.2/topics/auth/customizing/
- [S2] Django — Database transactions: https://docs.djangoproject.com/en/5.2/topics/db/transactions/
- [S3] Django — QuerySet row locking and testing cautions: https://docs.djangoproject.com/en/5.2/ref/models/querysets/#select-for-update
- [S4] PostgreSQL — Row security policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- [S5] Django — Deployment checklist: https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/
- [S6] Vercel — Hobby plan and commercial-use restriction: https://vercel.com/docs/plans/hobby
- [S7] Vercel — Deploy Django: https://vercel.com/docs/frameworks/full-stack/django
- [S8] Vercel — External PostgreSQL: https://vercel.com/docs/postgres
- [S9] Vercel — Function limits: https://vercel.com/docs/functions/limitations
- [S10] Vercel — Private Blob availability and signed URLs: https://vercel.com/changelog/vercel-private-blob-is-now-generally-available
- [S11] Vercel — Runtime filesystem and persistent state: https://vercel.com/docs/functions/runtimes
- [S12] Vercel — Pro pricing: https://vercel.com/docs/plans/pro-plan
- [S13] American Dental Association — Considerations in Developing a Financial Policy: https://www.ada.org/resources/practice/practice-management/considerations-in-developing-a-financial-policy
- [S14] Django — Supported/LTS releases: https://www.djangoproject.com/download/
- [S15] Django — Management checks and migrations: https://docs.djangoproject.com/en/5.2/ref/django-admin/

References checked 6 October 2026. Technical baseline versions are proposed; exact patch/dependency pins must be locked and support/compatibility rechecked at implementation. Local legal/tax requirements remain an explicitly separate verification workstream. The supplied PDF remains the source for the reviewed product requirements.


## 20. Module-based implementation contracts

Each module below has an owner in the codebase, dependencies, ordered tasks and objective acceptance tests. UI menus are not separate databases. Admin screens call the responsible module's services; they never maintain their own copies of patients, doctors, invoices or balances.

### M01 — User Module

**Purpose:** individual identities, sign-in, clinic membership and allowed actions. **Code owner:** `accounts`. **Phases:** technical User model in Phase 1; functioning module in Phase 2. **Dependencies:** core settings, PostgreSQL and clinic identity.

**Data:** User, ClinicMembership, Role, MembershipRole, with Django permission definitions. Session/reset-token mechanisms use Django support. Doctor profile belongs to M03; patient identity belongs to M04.

**Implementation steps:**

1. Create custom User before the first application migration; use UUID ID, normalized unique login email, name, active flag and Django-managed password. In Phase 1 this is only schema infrastructure.
2. Add Membership with unique `(clinic_id, user_id)` and active flag. Role grants apply to that membership, never globally to all clinics.
3. Implement one tenant-context resolver: select only an active membership for the authenticated user; reject arbitrary clinic IDs from requests.
4. Implement login/logout, session expiry, password change/reset and account disable. Local reset delivery uses a development backend; production email delivery is configured before live reset use.
5. Centralize `require_permission(actor, action, clinic)` and object-scope checks. Views, forms, API, print and exports reuse them.
6. Build user list, invite/create, grant/revoke role, deactivate/reactivate and password-reset screens. An account may hold Dentist plus Owner roles when appropriate.
7. Invalidate or recheck authorization after role/membership changes. An already open tab must not retain removed privileges.
8. Add privileged-account MFA before pilot; exact implementation chosen and dependency-tested in Phase 2, verified in Phase 10.

**Actions:** `create_user`, `add_membership`, `grant_role`, `revoke_role`, `deactivate_membership`; ordinary authentication endpoints under `/auth/`. Grantable roles/permissions are limited by the actor's authority. The last active clinic administrator cannot accidentally remove their own recovery path.

**Acceptance:** inactive accounts cannot log in; inactive memberships cannot access clinic data; Clinic A staff cannot switch into Clinic B; receptionist cannot sign a note; role changes take effect on the next protected request; password/reset tokens never appear in logs.

### M02 — Admin and Clinic Module

**Purpose:** clinic setup, policies and oversight. **Code owner:** `clinics`; administrator-facing aggregation calls other modules. **Phase:** 2, with financial settings completed in 8. **Dependencies:** M01 and core audit.

**Data:** Clinic, ClinicSettings, Chair, DocumentSequence, versioned policy configuration. Platform Super Admin operations are distinct from clinic Owner/Admin.

**Implementation steps:**

1. Create the pilot clinic via controlled setup command; do not expose public SaaS registration.
2. Set NPR, Asia/Kathmandu, clinic contact/branding, allowed fiscal-year label and language preferences. Start with one site and one chair.
3. Add scoped staff/role management through M01, and clinic profile/settings screens. Ordinary clinic users do not receive Django's unrestricted administration console.
4. Add explicit settings versions for prices/discount limits, invoice numbering, refund approvers and print policy. Financial records retain the policy/tax snapshot used at issue.
5. Implement sequence allocation with row locking, unique period/document counters and immutable issued numbers. A failed issuance must not create duplicate numbers; number gaps and abandoned drafts follow approved rules.
6. Reject changing currency once posted transactions exist. Keep historical timezone/date effects traceable; do not restate prior receipts silently.
7. Audit material settings changes and bulk exports. Owner access to clinical detail requires the clinical role or a specific clinical grant.

**Screens:** clinic profile, chair/resource setup, staff links, policy settings, document formatting, setup status. **Acceptance:** clinic-scoped sequences remain unique during concurrent issue; changing a catalogue price does not alter issued invoices; settings cannot turn an old advance into revenue.

### M03 — Doctor Module

**Purpose:** four separate dentists, availability and responsibility for clinical work. **Code owner:** `clinics` initially; doctor-specific services/selectors under that app. Do not create a second copy of User. **Phase:** 3. **Dependencies:** M01–M02.

**Data:** DentistProfile linked one-to-one to an eligible Membership; Availability and ScheduleBlock. Add doctor code, specialization/reference fields, active status, working hours and configurable availability. Registration/license details are provided by the clinic; no automated license verification is promised.

**Implementation steps:**

1. Create doctor profiles for four named accounts after actual names are supplied.
2. Provide doctor directory, profile editor, weekly availability and leave/block editor. The default week follows the clinic's actual working days (confirm; Saturday is the usual weekly holiday in Nepal).
3. Define a roster independently of the one-chair schedule; four profiles do not imply simultaneous chair capacity.
4. Implement eligibility selectors for appointment, visit, plan and procedure assignments. Membership and doctor profile must both be active.
5. Define clinical care scope consistently: assigned appointments/visits/plans grant ordinary access to the relevant patient's longitudinal records; a broader clinic-wide clinical grant is explicit and audited. Care-scope policy needs clinic review.
6. Preserve attribution when a doctor is deactivated. Reassign future appointments explicitly; signed records remain attributed to the original doctor.
7. Expose own calendar, assigned patients and attributable completed work; financial totals follow the report permission matrix.

**Actions:** profile create/update, availability update, block/unblock, deactivate and future-booking reassign. **Acceptance:** a doctor on leave cannot receive a normal booking; inactive staff cannot perform new work; historical signatures remain intact; two doctors cannot use the single chair at the same time.

### M04 — Patient Module

**Purpose:** one durable patient identity used by every domain. **Code owner:** `patients`. **Phase:** 4. **Dependencies:** M01–M02 and scoped selectors.

**Data:** Patient, PatientContact/Guardian, MedicalHistoryRevision, PatientAlert. Proposed pilot mandatory fields: full name and one contact or a recorded reason it is unavailable. DOB is optional with dated approximate age support; no fake DOB values. Required clinical history before treatment is a separate review workflow.

**Implementation steps:**

1. Build search-first registration by patient number, normalized phone and name.
2. Generate clinic-scoped patient numbers safely; warn about likely duplicates without enforcing unique family phones.
3. Add demographic/contact/guardian forms with validation and protected historical links.
4. Build the patient workspace and identity header. Display age/DOB uncertainty accurately and highlight allergies/alerts only to appropriate staff.
5. Store medical history as reviewed revisions. Clinician acknowledges the relevant history revision during each visit.
6. Add deactivate/reactivate with history retained. The pilot does not automatically merge or transfer patient funds. Provide duplicate review/flagging; destructive merge is a separately approved action.
7. Add privacy-scoped export with audit. Reception sees operational alerts, not unrestricted full clinical narratives.

**Endpoints:** patient search/create/detail/update, history revision, alert resolution, deactivate/reactivate. **Acceptance:** shared phone, uncertain age, guardian, duplicate warning, race-safe numbering, inaccessible foreign-clinic records and medical history revision retrieval.

### M05 — Appointment and Reception Module

**Purpose:** bookings, walk-ins, arrivals and the shared-chair queue. **Code owner:** `appointments`. **Phase:** 5. **Dependencies:** M03–M04 and service duration/resource rules from M08.

**Data:** Appointment, AppointmentEvent, actual ChairOccupancy event/projection. The appointment may reference a service for duration/resource suggestions; the reason is not automatically a billable charge.

**Implementation steps:**

1. Implement a day/week calendar with all-doctor and individual-doctor views, plus the single chair view.
2. Add booking form with patient, doctor, start/end, reason, chair requirement and suggested duration. Validate local date input as timezone-aware UTC storage.
3. Implement one scheduling service for create/reschedule/extend/walk-in. Lock the involved Chair and doctor resources in sorted order; check intervals including buffer and active statuses.
4. Distinguish dentist policy exceptions from impossible physical chair occupancy. A role cannot authorize two actual occupants of the same chair.
5. Record confirm, arrival, cancellation, no-show and reschedule events. Rescheduling preserves previous time and actor/reason.
6. Add waiting queue and patient-ready/doctor-ready context. Starting treatment must check current chair occupation, including an earlier appointment running late.
7. Add Visit creation through M06 once Phase 6 exists. Repeated start-clicks reuse the same appointment-linked Visit.
8. Keep booking completion separate from clinical signing, procedure completion and invoicing.
9. Handle overrun: when actual chair occupancy passes the planned end plus buffer, flag the next appointment DELAY_RISK with a projected start. Reception chooses to keep the patient waiting, reschedule (event logged) or reassign. The system never auto-starts or auto-moves a booking.

**Acceptance:** competing bookings for different doctors but one chair produce at most one successful reservation; adjacency respects buffer; backdated/no-show transitions obey policy; walk-ins cannot bypass locks; non-chair consults overlap only under approved resource rules; an overrunning treatment flags the next appointment without moving it.

### M06 — Clinical Visit Module

**Purpose:** clinical encounter, examination, diagnosis, advice and signed record history. **Code owner:** `clinical`. **Phase:** 6. **Dependencies:** M03–M05, minimal secure document support M13 and M07 chart.

**Data:** Visit, ClinicalNoteRevision, Diagnosis. Visit records responsible doctor, patient, optional appointment, clinical times and reviewed history revision.

**Implementation steps:**

1. Implement start-visit for booked patients and walk-ins; verify patient/doctor/appointment clinic consistency.
2. Add clinical workspace with prior visits, medical alerts and acknowledged history review.
3. Provide chief complaint, examination, diagnosis and advice fields; optional structured templates supplement free text.
4. Integrate M07 chart findings with the same Visit; avoid saving a second patient record from clinical forms.
5. Save drafts with optimistic version checking to stop one browser tab overwriting another.
6. Implement signing as an explicit clinician action. Save sign time, author and immutable content snapshot.
7. Implement amendments as new linked revisions with reason; preserve the original signed note and show the timeline.
8. Closing a visit does not erase drafts or force bill issuance. Prescriptions/consents are added in M10.

**Acceptance:** support staff cannot sign; a signed record cannot be edited through API/admin; amendments retain content/author; concurrent stale saves fail clearly; prior records are available within the approved care scope.

### M07 — Dental Chart Module

**Purpose:** tooth/surface findings and treatment history. **Code owner:** `dental_chart`. **Phase:** 6. **Dependencies:** M04 and M06.

**Data:** ToothReference, ToothFinding, FindingSurface and explicit resolve/supersede events. Service/procedure progress is read from M09 rather than duplicated independently in the chart.

**Implementation steps:**

1. Agree one numbering/orientation convention and valid surface mappings with the clinic; seed reviewed adult and child tooth references.
2. Build adult/child/mixed chart views with labels, legend and clear upper/lower orientation. Distinguish a finding from a planned/completed treatment.
3. Implement click-to-view history and add finding for one tooth and one or more valid surfaces.
4. Persist observation date, visit and responsible clinician. Current view is a projection of history; do not overwrite old caries/filling findings.
5. Resolve/supersede with a new event and reason. Show current and historical status independently.
6. Overlay accepted/in-progress/completed procedures from M09; the chart does not independently charge the patient or complete a procedure.
7. Add keyboard-accessible selection and readable colors/patterns; validate with a dentist using realistic scenarios.

**Acceptance:** adult and child references cannot be confused; surfaces validate; multiple findings on the same tooth remain readable; a new finding does not delete old history; tooth 36 example from the specification is reviewed by the pilot dentist.

### M08 — Service and Pricing Module

**Purpose:** clinic-approved treatments, durations, prices, resource requirements and billability rules. **Code owner:** `treatments` catalogue subdomain. **Phase:** 3 for catalogue; Phase 7 for milestones. **Dependencies:** M02.

**Data:** Service, ServicePolicyVersion, optional ServiceMilestoneDefinition. Stable service code, display name/category, current price, chair requirement, expected duration and active status. Tax configuration is versioned and local-policy verified.

**Implementation steps:**

1. Create catalogue/category forms and scoped listing. Enter real clinic prices later; no invented seed prices for production.
2. Set chair requirement/duration suggestions used by appointments, allowing an explicitly configured no-chair service where appropriate.
3. Set default billability: completed service or defined earned milestones. Deposit collection policy is separate.
4. Add price/policy effective versions and approval limits. Estimates/invoices copy snapshots, not dynamically changing current prices.
5. Implement deactivate rather than deleting used services.
6. For staged packages, define named milestones and cumulative value caps, approved by the dentist and owner. A final remainder excludes earlier billable milestones.

**Acceptance:** historical plan/invoice prices remain unchanged after a catalogue update; inactive services cannot be added to new plans by default; a no-chair flag cannot be used to bypass real treatment capacity; milestone totals match the agreed package.

### M09 — Treatment Plan and Procedure Module

**Purpose:** proposed work, accepted price/terms, treatment sessions and sources eligible for billing. **Code owner:** `treatments`. **Phase:** 7. **Dependencies:** M06–M08 and M13 for evidence. Consent is consumed through the `ConsentRequirement` check interface defined first in M10, so the two modules do not depend on each other circularly (see Phase 7 order).

**Data:** TreatmentPlan, TreatmentPlanRevision, TreatmentPlanItem, PlanItemTooth, Procedure, ProcedureTooth, ProcedureSession, BillableCharge. Item acceptance belongs to a specific revision; service progress does not rewrite acceptance history.

**Implementation steps:**

1. Create plan from Visit, selecting services, teeth/surfaces, quantities, price snapshots and alternatives (items sharing an alternative_group; accepting one marks the others not chosen).
2. Validate totals, then propose the version. Show estimated value, accepted value, completed billable value and invoiced value separately.
3. Record full or partial item acceptance, actor/patient/guardian evidence and terms version. Changing accepted clinical scope/price requires a new revision and renewed acceptance where appropriate.
4. Create procedure from accepted item or documented direct/emergency treatment; an estimate is not mandatory for every consultation but clinical authorization is.
5. Add actual sessions across visits, with clinician and performed work. Completion uses clinical evidence and permissions.
6. Create BillableCharge only on approved completion/milestone. Give the source a unique posting key to prevent retry duplicates.
7. Cap cumulative billable amount at accepted package value unless an explicit approved amendment changes it. Cancelling pending work does not erase completed sessions or existing bills.
8. Expose unbilled-charge list to M11. Billing consumes sources without editing clinical notes.
9. Optionally track a LabOrder (sent, due, received) for outsourced crowns and dentures, so deposit and lab-commitment decisions refer to real records. A LabOrder never creates a charge by itself.

**Acceptance:** rejected items cannot silently become accepted; one procedure spans multiple visits; multiple/no-tooth work supported; partial acceptance and cancellation preserve history; milestone plus final billing cannot exceed the package or bill the same charge twice.

### M10 — Prescription and Consent Module

**Purpose:** clinician-authored prescriptions and evidence of patient/guardian consent. **Code owner:** `clinical`. **Phase:** 7. **Dependencies:** M06 and M13; templates reviewed in Phase 0. Delivered in two parts: (A) templates, versions and the `ConsentRequirement` interface before M09; (B) consent records linked to plans and procedures after M09 exists, through nullable references resolved by service.

**Data:** Prescription, PrescriptionItem, ConsentTemplateVersion, ConsentRecord. Clinical drug/dose/instructions are clinician inputs, never software-invented recommendations.

**Implementation steps:**

1. Add clinic-reviewed prescription print template and required medication fields.
2. Implement draft/sign/amend behavior using clinician permission; only signed versions are official output.
3. Create consent templates with immutable versions; separate clinical consent from estimate/payment acceptance.
4. Record patient/guardian, treatment scope, clinician, time, signed evidence/document version and witness where policy requires.
5. Implement procedure-specific consent checklist; required consent cannot be bypassed by a hidden button or direct API call. Emergency exception follows an explicit clinical policy and audit.
6. Provide authorized view/print; future template edits do not change previous consent or prescriptions.

**Acceptance:** receptionist cannot prescribe; expired/incomplete consent is identified under the approved policy; signed document versions stay linked; guardian relationship is checked; clinical scope changes trigger review.

### M11 — Billing, Payments and Patient Credit Module

**Purpose:** invoices, money received, explicit allocation, corrections and refunds. **Code owners:** `billing` and `payments`, linked by defined service interfaces. **Phase:** 8. **Dependencies:** M01–M02, M04, M08–M09 and transactional audit.

**Data:** Invoice/InvoiceItem, InvoiceChargeLink, CreditNote/Item, Payment, PatientCredit, Allocation/AllocationReversal, Refund/RefundReservation, ReceiptReversal, IdempotencyRecord, CashBankAccount. CashBankAccount configuration is shared with M12; there is one table, not one per module.

**Implementation steps:**

1. Approve section 6 financial examples, invoice/receipt numbering, rounding, taxes, due dates and controls before posting code.
2. Implement decimal line/document calculation and tests; issued snapshots are immutable. No client-submitted total is trusted.
3. Build unbilled-source invoice draft; verify source consistency and atomically consume a charge once at issue.
4. Implement a unified receipt source: Payment creates one PatientCredit for the full receipt, optionally allocating selected invoices in the same transaction.
5. Implement source-to-invoice allocation, locking both source and invoice; positive amount cannot exceed spendable credit or invoice outstanding.
6. Add reversal events with amounts bounded by the original active posting. Original receipts/allocations are never edited/deleted.
7. Implement credit notes. If adjusted charges fall below active allocation, release the surplus allocation to original sources inside the credit-note transaction. A write-off of an uncollectable balance is a credit note with a write-off reason code, a configured approval limit and its own report line.
8. Implement refund request/reservation, approval/rejection and actual completion/failure/cancellation. Retrying completion cannot return money twice in the system.
9. Implement receipt reversal for recording errors, separate from actual refund. Reject while active allocations or completed refunds exist; staff first reverse allocations explicitly. Verify reconciliation cutoff before reversing.
10. Build patient statement, payment/advance entry, source-credit view, allocation preview and print outputs. Use explicit confirmation; net position does not hide separate dues and credit.
11. Add finance consistency checker and report discrepancies without silently repairing data.

**Financial services:** `issue_invoice`, `receive_payment`, `allocate_credit`, `reverse_allocation`, `issue_credit_note`, `request_refund`, `approve_refund`, `complete_refund`, `reverse_receipt`. Every function receives verified actor/context, reason if required and retry key for financial mutation.

**Acceptance:** all numerical examples in section 6 pass, including concurrent allocation/refund, idempotent retries, paid invoice credit note, cross-patient and cross-clinic rejection, local-day boundaries and late payments without new revenue.

### M12 — Accounting and Reconciliation Module

**Purpose:** patient subledger control, cash/bank/QR reconciliation and accounting exports. **Code owners:** `reconciliation`, finance selectors in `reports`. **Phase:** 9. **Dependencies:** M11 and immutable postings.

**Scope clarification:** this is the Accounting Module requested in the module map, within the confirmed billing-plus-exports scope. It is not a full general ledger, supplier ledger, expenses, payroll, stock or financial-statements package. Those need an explicitly approved extension; the module name does not imply they exist.

**Data:** shared CashBankAccount, ReconciliationBatch, ReconciliationItem, AccountingExportRecord and versioned ExportMapping. Patient balances derive from M11; do not create another manually maintained balance table.

**Implementation steps:**

1. Define cash/bank/QR account mapping and whether a QR receipt is settled to a bank account or pending verification. Only verified received funds are posted as collections.
2. Implement daily expected movement by account: posted verified receipts less completed refunds plus valid correcting reversal effects. Pending refunds are separate.
3. Build reconciliation batch with linked posting IDs, entered verified total, variance and explanatory note. Each posting can belong to only one active closed batch under that reconciliation scope.
4. Require review for unresolved variance; close atomically. Reopening/backdated correction has permission, reason and audit.
5. Build patient statement, receivables ageing and advances report from one set of selectors. Define transaction effective date and as-of handling consistently.
6. Implement CSV/XLSX accounting export with source references, period, account mapping, tax/discount columns, checksum and export run ID.
7. Record export history. Re-exporting is permitted but clearly labeled; a downstream import must use source IDs/run handling to avoid duplicate posting.
8. Verify zero opening patient receivables/advances for this new clinic. Do not fabricate asset/capital balances or a full trial balance.

**Acceptance:** cash and bank balances in reconciliation match posting detail; receipt allocation does not inflate collection; pending refunds do not reduce actual cash until completed; closed-batch edits are blocked; report and export totals agree; no duplicate source rows.

### M13 — Documents and Media Module

**Purpose:** private patient files and versioned clinical evidence. **Code owner:** `documents`. **Phase:** minimal secure uploads in 6; clinical linking in 7; production adapter completed before 10. **Dependencies:** M01/M04, clinic authorization and storage choice.

**Data:** Document, DocumentVersion, scan/validation status, storage key, byte size/checksum, owner/patient and optional visit/procedure/consent links. Avoid an uncontrolled public URL field as the source of access.

**Implementation steps:**

1. Define a storage interface for private write/read, signed transfer URL, checksum and deletion/retention actions.
2. Implement session-authenticated upload intent with clinic/patient/type/size checks; storage key generated by server.
3. Support direct large-file transfer to the private store, then finalize by verifying object size/type/checksum and expected owner. Never trust a client-declared successful upload alone.
4. Quarantine unvalidated files: server-side signature/MIME check, size limit, image re-encoding or PDF sanity check, staff-only upload. Antivirus scanning is decision G12: if the chosen host cannot run a scanner, use an external scanning service or record the residual risk for staff-only uploads. Files stay unavailable when validation fails; if scanning is declared mandatory, the scanner must exist before the Phase 10 gate.
5. Generate brief authorized read URLs or controlled response only after clinic, role and patient checks. Public caching of patient responses is disabled.
6. Implement replacements as versions; consent/signature records pin the version they used.
7. Audit access/export and define retention/deletion evidence. Backups include active/retained document versions and metadata.

**Acceptance:** foreign-clinic URLs cannot be minted; uploaded file type mismatch rejected; pending/quarantined files cannot be opened; replaced consent evidence remains recoverable; files survive application redeploy and full restore.

### M14 — Reports and Dashboard Module

**Purpose:** operational and financial insight without duplicate source data. **Code owner:** `reports`. **Phase:** basic reception/doctor widgets in relevant modules, full report set in 9. **Dependencies:** each source domain; money metrics require M11.

**Implementation steps:**

1. Define each metric as in section 11, including source statuses, effective date, clinic timezone and void/reversal handling.
2. Implement scoped selectors for appointments, visits, source charges, issued value, verified collections, dues, advances and refunds.
3. Build separate role-oriented dashboards: receptionist queue, doctor workload, owner overview and accountant reconciliation.
4. Add statement, ageing, source credits, daily collection, service value, doctor attribution, treatment pipeline, appointment outcomes and audit reports.
5. Add date/as-of filters, pagination, print/export permission and accessible empty states.
6. Validate against posted detail; optimize indexes/select-related queries before considering summaries/caches.
7. A later cache must include clinic and permission scope, with no shared patient-content cache across clinics.

**Acceptance:** clinic/date totals equal underlying details; cancelled/superseded plans do not inflate pending work; allocations do not become cash receipts; users see only allowed report columns; repeated exports reproduce the specified period.

### M15 — Audit, Security and Tenant Isolation Module

**Purpose:** cross-cutting controls for all modules. **Code owners:** `audit`, `core`, `accounts` and reviewed database migrations. **Phases:** scaffold 1, enforce 2 onward, harden 10. It is not postponed until the end.

**Implementation steps:**

1. Establish request ID, actor/membership context, protected audit writer and sensitive-data logging rules.
2. Add clinic-aware selectors and PostgreSQL row policies for tenant-owned tables as introduced. Use non-owner/non-bypass application role and controlled migration role.
3. Enforce tenant/patient consistency for foreign keys using tested database constraints/triggers; serializers alone are insufficient.
4. Write audit event in the same transaction as critical business changes. Keep necessary protected diff information separate from ordinary diagnostic logs.
5. Protect export/download actions, privileged support access and role/settings changes. Audit reads of clinical records and break-glass use. Ordinary users cannot update audit rows.
6. Configure TLS, CSRF, cookie/security settings, login protection and MFA with meaningful denial tests.
7. Implement consistency/backup checks and incident/support runbooks. A database administrator can still alter database data; do not claim an audit table alone is tamper-proof.

**Acceptance:** at least two synthetic clinics test every implemented read/write route; missing tenant context fails closed; connection-pool reuse cannot leak prior context; constraints reject cross-clinic links; an audit write failure rolls back critical posting.

### M16 — Platform, Deployment and Backup Module

**Purpose:** reproducible local runtime and reliable deployment. **Code owners:** `config`, `deploy`, development/operations docs. **Phases:** 1 and 10–11. **Dependencies:** approved host configuration for live use.

**Implementation steps:**

1. Build Docker-based local app/PostgreSQL environment, pinned dependency locks and test database.
2. Separate development/test/production settings; provide `.env.example` with placeholders and no secrets.
3. Build static assets locally/CI and configure Django WSGI/ASGI entrypoint compatible with current Vercel docs.
4. Keep external database, sessions and object storage durable; do not use local SQLite/files for production persistence.
5. Apply schema migrations through one controlled release operation; previews use isolated test infrastructure and never change production.
6. Set monitoring/alerting and backup schedules, then demonstrate restore of both PostgreSQL and files.
7. Document safe rollback of application code, forward database fixes and downtime entry. Code rollback does not undo posted money.
8. Resolve commercial Vercel plan and database/storage/backup provider costs before real deployment.

**Acceptance:** fresh checkout starts repeatably; environment separation verified; production secrets do not appear in source/logs; backup restore matches finance totals and retrieves files; no unapproved live patient deployment.

## 21. Phase-by-phase execution playbooks

This is the canonical phase sequence. It replaces earlier phase numbering in the source PDF and prior planning drafts. Phase 0 is review/design. **Phase 1 remains foundation-only, as originally requested.** A module's detailed behavior is in section 20; each phase builds a coherent subset, not the whole product at once.

### Phase 0 — Complete review and approve the design

**Outcome:** approved plan baseline and resolved business controls; no application code.

1. Review sections 1–19 and module contracts M01–M16.
2. Resolve blocking decisions in section 24. Supply clinic name, doctor names/availability and initial service list; review forms created for this new clinic.
3. Review the wireframe specifications in section 23 and the financial examples manually.
4. Obtain separate architecture, clinical workflow, finance, security and deployment reviews using the prompts in section 25. Agents advise; they do not authorize code or change scope.
5. Consolidate findings with accepted/rejected/deferred disposition and supporting rationale. Re-review changed critical finance/tenant designs.
6. Publish the approved plan version and authorized next phase. If live hosting is unresolved, the owner may explicitly approve local-only implementation while retaining the deployment block. No such approval has yet been given.

**Gate:** user approval references a specific version and scope; all implementation-blocking findings resolved. Majority reviewer agreement does not replace user approval.

### Phase 1 — Foundation and development environment

**Outcome:** a working technical skeleton, without patient/appointment/finance features. **Modules:** M16, M15 infrastructure, M01 technical schema only.

#### Step 1.1 — Inspect the target workspace

- Confirm repository path, existing contents, development OS and environment. Preserve any existing project; create an isolated project directory if necessary.
- Record the approved plan version and phase in `docs/implementation-status.md`.
- If there is no repository, initialize local Git only after implementation authorization. Remote repository creation/publishing is a separate requested action.
- Why: prevents overwriting unrelated work and establishes what the coding agent is permitted to build.

#### Step 1.2 — Pin the technical baseline

- Proposed baseline: Python 3.12, Django 5.2 LTS latest security patch, PostgreSQL 17 and current compatible Tailwind build tooling (no DRF unless an API is authorized). Lock exact resolved package versions and container tags/digests during implementation; recheck compatibility then.
- Django lists 5.2 as an LTS series with extended support through April 2028 [S14]. Choosing it is a stability decision, not a claim it is the newest release.
- Add only required baseline libraries. Choose one dependency installation/lock workflow, documented for local/CI/Vercel use.
- Why: all agents and environments use the same dependency set, and patch/security maintenance is traceable.

#### Step 1.3 — Create the project structure

- Add `manage.py`, `config`, domain app directories from section 4, shared templates/static sources, test directories and docs/runbooks.
- Register app configuration explicitly. Domain app migrations remain empty until their models are due.
- Add `.gitignore` for secrets, local databases, test artifacts and generated dependencies; `.env.example` contains placeholders only.
- Why: later modules can be added without a repository-wide reorganization.

#### Step 1.4 — Split configuration

- Create base/development/test/production settings, explicit timezone handling and environment-variable parsing.
- Development uses local PostgreSQL. Test uses a separate disposable PostgreSQL database. Production requires external database configuration and disables debug.
- Set WSGI entrypoint and `AUTH_USER_MODEL` before migrations. Use database sessions; production cannot depend on instance memory.
- Secrets have no production default. Required production settings fail validation when missing.
- Why: accidental test writes to the live database and secret exposure become harder.

#### Step 1.5 — Set up Docker and PostgreSQL

- Create app Dockerfile and Compose `app`/`db` services with named development database volume, database health check and configurable host port.
- Database migrations use the controlled development owner role; prepare separate application-role configuration for tenancy work in Phase 2.
- PostgreSQL test environment must support transactions, triggers and row-level security. Do not substitute SQLite for business tests.
- Document ordinary start/stop and explicitly warn that deleting the development volume erases its data.
- Why: finance and concurrency tests must exercise the real database behavior.

#### Step 1.6 — Install the minimal custom User schema

- Create `accounts.User` using Django-supported authentication foundations with UUID identity and approved email login fields. Add its initial migration before any other model references it.
- Do not build clinic user management, role screens, login workflows or permissions functionality in this phase; those belong to Phase 2.
- Run framework/custom-user migrations against the fresh database.
- Why: Django recommends defining the custom user at project start; moving it after dependent migrations is difficult [S1].

#### Step 1.7 — Build the neutral UI shell

- Compile Tailwind into local static assets; no production dependency on a public CSS playground/CDN script.
- Create base layout, shared header/navigation container, typography, accessible forms/error components and a neutral foundation page.
- Business navigation entries remain absent or visibly unavailable; no fake working patient/payment buttons.
- Configure print stylesheet hooks, without claiming invoice printing exists.
- Why: later screens share a consistent layout without pretending the application is already usable.

#### Step 1.8 — Health checks, errors and logging

- `/health/live` returns minimal liveness without querying patient data.
- `/health/ready` checks required database connectivity and returns only ready/not-ready information. Restrict detailed diagnostics; no credentials or internal exception dump.
- Configure structured logging with request IDs and redaction; add clean 403/404/500 templates.
- Establish the audit interface contract and future tenant-context contract; no fictitious business audit entries or active tenant records.
- Why: deployment health and troubleshooting are available before business features arrive.

#### Step 1.9 — Verification automation

- Add tests for configuration, health behavior including database failure, custom-user migration and safe error responses.
- Add CI definition: dependency install, asset build, Django checks, migration drift check and tests with PostgreSQL.
- Enforce no committed secrets and syntax/lint checks. Security deployment checks use realistic environment variables without exposing values.
- Why: each subsequent module inherits a repeatable validation workflow.

#### Step 1.10 — Vercel compatibility configuration, without deploying

- Add configuration consistent with current official Django integration: recognized entrypoint, dependency installation and static build/collection.
- Keep production database/storage/secret placeholders explicit. Do not create Vercel project, database or paid plan.
- No production migrations in arbitrary preview build hooks. Migrations have a single controlled future release step.
- Document platform/body-size/persistent-storage limitations from section 4A.
- Why: the requested hosting choice is considered early without incurring cost or publishing unapproved code.

#### Step 1.11 — README and completion report

- Document prerequisites, local start/stop, migrations, tests, assets, environment variables and non-destructive recovery.
- List implemented infrastructure, intentionally deferred modules, known limitations and test evidence.
- Stop at the agreed phase gate; do not begin Phase 2 merely because the foundation tests passed.

#### Expected files after Phase 1

| Group | Required artifacts |
| --- | --- |
| Runtime | `manage.py`, `config/settings/`, URL/WSGI files, dependency lock, Dockerfile, `compose.yaml` |
| Accounts infrastructure | custom User model and first migration; no user-management screens |
| UI | base templates, foundation page, static build configuration, CSS source/output process |
| Diagnostics | health views/tests, logging config, safe error pages |
| Tests/CI | PostgreSQL test settings, foundation tests, local validation commands, CI config |
| Documentation | README, `.env.example`, phase status, dependency decision record, future release notes |
| Platform | Vercel compatibility configuration and deployment requirements; no deployed service |

#### Planned verification commands

The following commands are to be implemented/documented by the Phase 1 coder after the named files and `app`/`db` services exist. They are not commands executed during planning and are not a bootstrap script for an empty directory. Docker commands work from PowerShell or a Linux shell when Docker is installed.

```bash
docker compose config --quiet
docker compose build
docker compose up -d db
docker compose run --rm app python manage.py migrate
docker compose run --rm app python manage.py check
docker compose run --rm app python manage.py makemigrations --check --dry-run
docker compose run --rm app python manage.py test
docker compose up -d app
```

The README must additionally provide the selected asset-build command and `check --deploy` command with its production-settings module. Inspect a liveness URL on the configured development port; the port is set in Compose and documented rather than assumed.

**Phase 1 acceptance:** clean checkout starts; PostgreSQL migrations succeed; assets compile; health/error tests pass; no migration drift; no patient/clinical/money module falsely marked implemented; production secrets remain unset/placeholders; no external deployment or charge. Demonstrate a foundation-page screenshot and actual check/test output after implementation.

### Phase 2 — User and Admin modules

**Modules:** M01/M02, enforce M15. **Depends on:** accepted Phase 1.

1. Implement Clinic, Membership, role grants, settings, chair and numbering schema; create audited/scoped bootstrap operation.
2. Establish non-owner application database role, request tenant context and RLS policies on implemented tenant tables; add database tenant-reference controls. Run a throwaway spike first with local PgBouncer in transaction mode (synthetic data, no paid account) to confirm `SET LOCAL` context, `select_for_update` and cursor behavior; record the result as a decision.
3. Implement authentication, password workflows and membership/permission services. Add privileged MFA choice and tests.
4. Build admin setup and staff screens; create synthetic clinics only in test environments.
5. Add session/role-change/foreign-clinic denial integration tests and audit atomicity checks.

**Gate:** owner can manage scoped users/settings; clinical records are not globally exposed; unassigned/disabled user denied; two-clinic tests pass. **Review evidence:** permission test matrix, schema migration and setup walkthrough.

### Phase 3 — Doctor and Service modules

**Modules:** M03/M08. **Depends on:** 2.

1. Implement doctor profile, eligibility, availability and leave blocks.
2. Implement real-price catalogue entry, duration/chair policy and versioned settings.
3. Build doctor directory/availability and service CRUD/deactivation screens.
4. Verify policy updates preserve historical snapshots and inactive staff/services are excluded from new assignments.

**Gate:** four separate doctor profiles can be configured; exactly one chair in pilot setup; no production prices invented; schedule/resource rules documented.

### Phase 4 — Patient module

**Modules:** M04. **Depends on:** 2; doctor assignment uses 3.

1. Implement patient identity, numbers, contacts/guardians, history revisions and alerts.
2. Build search-first registration and workspace shell with enabled tabs only for implemented features.
3. Add updates/deactivation, duplicate warnings and scoped permission/audit tests.
4. Validate family phones, uncertain age and guardian cases with clinic staff.

**Gate:** receptionist registers/searches a patient without developer help; history changes traceable; no automatic merge or opening balances.

### Phase 5 — Appointment and reception module

**Modules:** M05. **Depends on:** 3–4.

1. Implement calendar, queue and lifecycle services.
2. Implement chair/dentist locking and buffer logic across create/reschedule/extend/walk-ins.
3. Add arrival/no-show/cancellation history and operational dashboard.
4. Run competing booking transaction tests with two doctors and one chair.

**Gate:** no conflicting chair reservations/occupancy; dentist availability respected; visit-start link introduced only when Phase 6 exists.

### Phase 6 — Clinical visit, dental chart and secure document foundation

**Modules:** M06/M07/M13 minimum. **Depends on:** 4–5.

1. Implement Visit and draft/sign/amend notes with history review acknowledgement.
2. Implement reviewed tooth/surface reference data and chart UI/history.
3. Implement private image/PDF metadata, upload validation/quarantine and authorized retrieval using a development adapter.
4. Link chart/documents to patient/visit; maintain care scope and clinical permissions.
5. Perform dentist walkthrough and tests for immutability, chart history and unauthorized files.

**Gate:** doctor completes examination and charting; support cannot sign; previous records retained; no production-storage claim until selected adapter passes Phase 10.

### Phase 7 — Treatment, procedures, prescriptions and consent

**Modules:** M09/M10, M08 milestones, M13 linking. **Depends on:** 6.

1. First deliver consent templates and the `ConsentRequirement` interface (M10 part A), then implement plan revisions/items, partial acceptance and evidence/terms linkage.
2. Implement procedure/session lifecycle across multiple visits and teeth.
3. Implement service milestone rules and unique BillableCharge sources.
4. Implement signed prescriptions and consent records linked to plans/procedures (M10 part B), plus optional LabOrder tracking if approved (D17).
5. Validate treatment cancellation, changed estimates, guardian consent and completed-work value.

**Gate:** accepted work progresses to a unique unbilled charge; no false invoices from estimates/deposits; clinical outputs approved by dentist.

### Phase 8 — Financial engine

**Modules:** M11; shared money-account configuration M12. **Depends on:** 7 and approved finance/local billing policies.

1. Implement invoice calculations, immutable issue and source consumption.
2. Implement unified source funds, receipts, allocation and statement projections.
3. Implement credit notes, bounded reversals, reserved/approved/completed refunds and recording-error reversal.
4. Add idempotency, locks, protected periods, finance audit and consistency checks.
5. Build functioning finance screens/prints; execute numerical and competing-write tests.

**Gate:** accountant/owner independently reconcile every section 6 example; no unexplained negative invoice balances or overspent sources; critical finance findings resolved.

### Phase 9 — Accounting, reports and dashboard

**Modules:** M12/M14. **Depends on:** 8.

1. Implement account-level daily reconciliation and close/reopen controls.
2. Implement financial/operational report selectors with local date/as-of filtering and scoped exports.
3. Implement accountant/owner dashboards and agreed CSV/XLSX mapping/export manifest.
4. Reconcile summary/detail/exports against posted examples and zero-opening new-clinic setup.

**Gate:** reports tie to postings; collection excludes allocations and includes actual refund/reversal effect; clinic users can close the day and reproduce exported totals.

### Phase 10 — Production readiness and hosting validation

**Modules:** M15/M16 and production M13 adapter. **Depends on:** all implemented modules and resolved deployment decisions.

1. Recheck provider support/plan, paid eligibility, database/storage connection behavior and limits before any requested deployment.
2. Finish private direct-transfer adapter, scan mechanism, production auth/reset/MFA, monitoring and backup scheduling.
3. Re-run tenant isolation for every screen/API/print/export/file path, pool reuse and raw-query/report cases.
4. Exercise complete restore, failure/retry, migrations/release rollback and internet-outage entry.
5. Confirm billing-rule evidence, clinical template review and privacy/retention policies; record actual service/load test results.

**Gate:** no unresolved critical security/money issue; restore evidence; approved commercial host/cost decision; explicit authority for any actual deployment. Staging credentials/data remain isolated.

### Phase 11 — Controlled pilot and go-live

**Modules:** all. **Depends on:** 10 and explicit live-use approval.

1. Create production clinic and verified staff/catalogue settings; patient dues/advances start at zero.
2. Train receptionist, doctor, accountant/owner with synthetic scenarios in staging.
3. Run limited real-use pilot, using one authoritative live receipt numbering process.
4. Compare clinic workflows and cash reports; fix defects with migration/audit integrity preserved.
5. Obtain user/clinic acceptance, record known noncritical issues and approve go-live.

**Gate:** entire patient journey and daily close work without developer intervention; backup/restore and staff ownership established. Wide SaaS rollout is not implied.

## 22. Field-level implementation baseline

This supplement defines proposed types/validation for core fields. Combine it with section 5 relationships, module contracts and state machines. A coding agent may not turn an unspecified clinical/financial policy into a hidden default.

**Authority rule:** this section is the schema authority. Sections 5 and 20 describe relationships and behavior; on any conflict, section 22 governs and the conflict is logged for correction.

### Shared conventions

- `id`: UUID primary key. Global catalogue ToothReference uses reviewed stable code plus ID.
- Tenant records: non-null `clinic_id` foreign key, indexed; derived parent clinic must match at database and service layers.
- `created_at`: aware UTC timestamp, server-controlled; `created_by`: attributable User/Membership where applicable. Posted events also preserve business/effective date and request ID.
- Mutable drafts/configuration: `updated_at`, `row_version` positive integer; stale updates return conflict. Posted/signature records use separate revision/reversal events rather than updating their substance.
- `M`: monetary Decimal(14,2), not float; NPR only in pilot. `Q`: quantity Decimal(10,3), positive. Percentage Decimal(7,4), constrained to 0–100. Multiplication rounded only according to the approved line/document policy.
- Phone text max 32, normalized searchable form separate; names max 200; codes max 50; notes text with server length limits. Shared phone does not imply shared identity.
- Enumerations use declared choices and transition services. FK references used historically are protected; active flags on catalogue/staff records replace deletion.
- Important money fields are required, server-calculated or validated; empty amounts are not silently treated as zero.

| Model / field group | Required proposed fields and validation |
| --- | --- |
| User | unique normalized email; display_name text; is_active bool; password through Django; staff/superuser flags for controlled platform use only |
| Clinic | name text; timezone IANA name; currency char(3)=NPR; address/contact; active bool |
| Membership | clinic FK, user FK, active bool; unique clinic/user; role links independently scoped |
| Role / MembershipRole | role code/name and permission codes; membership/role links unique and clinic-consistent; only permitted actions can be granted |
| ClinicSettings / PolicyVersion | clinic FK; version, effective date, approved configuration; immutable when referenced by issued/signed records |
| DocumentSequence | clinic/document_type/period unique (period boundaries from reviewed BS fiscal-year data); next_number positive integer; lock before issue; format version reference |
| DentistProfile | membership one-to-one; doctor_code unique per clinic; specialization/reference optional; active bool |
| Chair | clinic FK; code/name; active; pilot bootstrap exactly one active chair |
| Availability | doctor FK; weekday 0–6 (numbering documented; the clinic week may start on Sunday); local start/end; effective dates; end after start; no ambiguous overnight span without explicit design |
| ScheduleBlock | doctor, chair or clinic-wide resource; aware UTC start/end; reason; end greater than start |
| Patient | patient_no unique per clinic; full_name; DOB nullable; estimated_age nullable plus age_recorded_on; phone/email optional; status ACTIVE/INACTIVE/DUPLICATE_FLAGGED; do not store a fabricated DOB |
| PatientContact | patient FK; name, relationship, contact, guardian_authority fields; guardian evidence references if required |
| MedicalHistoryRevision | patient FK; version; allergies/history text or controlled structured schema; clinician/author; reviewed_at; prior_revision FK; unique patient/version |
| PatientAlert | patient FK; category, severity, text, active_from/resolved_at; resolution actor/reason |
| Appointment | patient FK, doctor FK, optional chair under resource policy; UTC start/end; declared status; reason; chair_required snapshot; turnaround_buffer_minutes snapshot; row_version |
| AppointmentEvent | appointment FK; action; old/new time/status snapshot; actor/time; reason; immutable |
| ChairOccupancy | chair FK; appointment/visit source; occupied_from/released_at; cannot have two unreleased occupants; service lock covers real-time claim |
| Visit | patient/doctor FK; appointment nullable unique; start/end/sign times; reviewed_history_revision FK; OPEN/CLOSED status plus note signing state |
| ClinicalNoteRevision | visit FK; version; complaint/examination/advice text; author; signed_at nullable; amendment_of FK; amendment reason required on signed correction |
| Diagnosis | visit FK; code nullable; description required; author; optional finding link; no coding system assumed without approval |
| ToothReference | standard/code/dentition; valid allowed surfaces; seed dataset reviewed; unique standard/code |
| ToothFinding | patient/visit/tooth FK; condition; observation time; doctor; notes; original event; resolved/superseded via linked event |
| FindingSurface | finding FK; declared surface code; unique pair; valid against tooth dentition/type |
| Service | code/name/category; current price M nonnegative; chair_required bool; suggested duration positive minutes; active |
| ServicePolicyVersion | service FK; effective date/version; tax/price/rounding snapshot; completion/milestone billability; deposit suggestion nullable; immutable once used |
| ServiceMilestoneDefinition | policy version FK; stage code/order; value or approved percentage; clinical completion condition; total cap validated against package policy |
| TreatmentPlan | patient FK; optional originating visit FK; current revision FK; status/progress projection; no direct editable accepted total |
| TreatmentPlanRevision | plan FK; version; proposed_at; acceptance type/evidence/terms version; price validity; currency; previous_revision FK |
| TreatmentPlanItem | revision/service FK; Q; unit estimate M; discount/tax snapshots; status; clinical scope; alternative_group nullable; row_version while draft |
| PlanItemTooth / ProcedureTooth | respective parent FK and tooth FK; unique pair; optional separate surface link |
| Procedure | patient/service/doctor FK; optional originating item FK; lifecycle; commenced/completed time; approved price scope |
| ProcedureSession | procedure/visit/doctor FK; performed_at; notes; stage; clinician confirmation; repeated session entry uses unique retry/source identifier |
| BillableCharge | procedure/session FK; kind completion/milestone; source_key unique per clinic; Q/value M; approved_at/by; remaining billing entitlement derived from consumed links |
| LabOrder (proposed, D17) | procedure or plan item FK; lab name; work type; sent/due/received dates; status; internal cost note; never creates a charge |
| Invoice | patient FK; invoice_no nullable draft, unique issued per clinic/period; issue_date/due_date; currency; DRAFT/ISSUED/DISCARDED (draft only); totals M; issue actor/time; policy snapshot |
| InvoiceItem | invoice FK; source service/description/price snapshot; Q; unit price M; line discount/tax/net/total M; discount_reason and approver when above threshold; line order; tax breakdown strategy from approved policy |
| InvoiceChargeLink | invoice item FK; billable source FK; amount/quantity consumed; source total not exceeded; single-use source by default |
| CreditNoteItem | credit note FK; original invoice line FK; amount/tax correction snapshots; reason; cumulative credited line value bounded |
| CreditNote | original invoice/patient FK; unique issued number; reason_code (includes WRITE_OFF, which has its own approval limit) and free-text reason; issue/effective dates; requester/approver; DRAFT/ISSUED; totals M bounded by invoice entitlement |
| Payment | patient/account FK; receipt_no; received_at/business_date; amount M greater than zero; method; reference nullable cash, required where policy demands; posted_by; POSTED/derived reversal state |
| PatientCredit | payment one-to-one; patient/clinic/currency source; original M; source_type RECEIPT; available/remaining computed, not user-editable |
| Allocation | source credit/invoice FK; amount M greater than zero; effective_date/time; actor; retry identity; same patient/clinic/currency |
| AllocationReversal | original allocation FK; M greater than zero; actor/date/reason; sum reversal cannot exceed original |
| Refund | source credit/patient/account FK; amount M; status; reason; requester/approver; requested/approved/completed times; payout reference; retry identity |
| RefundReservation | refund/source FK; amount M; active/released status; creation/release time; reduces spendable funds while active |
| ReceiptReversal | payment FK; actor/date/reason; related unwind events; pilot default full erroneous receipt reversal only, allowed only when no active allocations and no completed refunds exist; partial returns use Refund |
| CashBankAccount | name/code; category CASH/BANK; institution/reference optional; supported methods; active; no editable patient balance |
| ReconciliationBatch | account FK; local business_date/range; state; expected/verified/variance M; closed_by/at; reason on reopen |
| ReconciliationItem | batch FK; typed posted source ID with FK/validated model strategy; included amount/effect; active closed-batch uniqueness |
| DocumentVersion | document FK; version; private storage key; checksum; byte size; actual MIME; quarantine status; uploader/time; original filename escaped for display |
| Document | patient FK; type and optional visit/procedure links; current_version FK; retention status; filename/label escaped; actual bytes owned by version |
| Prescription | visit/patient/doctor FK; version; DRAFT/SIGNED/AMENDED; signed_at/by; previous signed version FK and amendment reason |
| PrescriptionItem | prescription FK; drug, strength, dose, route, frequency, duration, instructions as clinician-confirmed values; no automatic clinical recommendation |
| ConsentRecord | patient/procedure/plan reference; template version; signer/guardian; timestamp; evidence document version; scope; explicit exception reference if policy allows |
| ConsentTemplateVersion | clinic/template_code/version unique; immutable text/required fields; active policy reference |
| FindingResolutionEvent | finding FK; RESOLVED/SUPERSEDED; replacement finding optional; reason; clinician; occurred_at; preserve prior event |
| AccountingExportRecord | clinic/period/mapping version; run UUID; source posting ID list or immutable query manifest; generated_by/at; file checksum; access audit |
| ExportMapping | clinic/destination/version unique; versioned field/account mapping; approved_by/at; no unspecified full general-ledger posting |
| AuditEvent | tenant/actor/request; action; entity type/UUID; timestamp; reason; protected diff; immutable to application role |
| IdempotencyRecord | clinic/operation/key unique; request hash; result record reference; committed outcome; different payload with same key conflicts |

`remaining_amount`, invoice settlement status and report totals are projections. If cached in columns, update only through posting services, lock consistently and verify against events. A normal row CHECK cannot validate an aggregate across many allocation/refund rows; implement aggregate control through serialized services and reviewed database enforcement, and test competing writes.

**Effective-date policy proposed:** financial postings preserve immutable business date and actual creation time. Routine staff cannot backdate into a closed reconciliation date. Corrections in a closed period are new authorized postings in an open period or use a documented reopen operation. As-of reports sum events up to their effective date, including reversal effects; they never infer past balances from today's cached remaining amount.

### Core action contracts

All IDs below are UUIDs resolved within the verified actor's clinic. Money is serialized as decimal strings; timestamps include timezone offsets. POST retry keys are mandatory for critical postings; successful first create returns 201 and repeated identical requests return the saved result without another posting. Errors use a stable `code`, safe `message`, optional `field_errors` and `request_id`; no internal traceback.

| Action | Minimum input | Server-derived output / safeguards |
| --- | --- | --- |
| Create staff member | email, display_name, requested role codes | user/membership IDs; allowed grants only; initial credentials never echoed/logged; activation/reset delivery is configured |
| Create patient | full_name, contact or reason unavailable, optional DOB/dated age and guardian | patient ID/no; duplicate warnings; no clinic or patient number trusted from client |
| Book appointment | patient_id, doctor_id, start/end, service/reason, chair selection if required | appointment ID/status/version and effective resource interval; final overlap check under lock |
| Start visit | patient_id, doctor_id, optional appointment_id | visit ID/state; repeated appointment start resolves same Visit; chair claim verified |
| Sign clinical note | note_id, expected_version, explicit confirmation | immutable signed version/author/time; unsigned stale client content rejected |
| Accept plan | plan_id, revision_id, accepted item IDs, signer/evidence, terms version | accepted revision and item states; cannot silently accept a superseded version |
| Complete procedure/session milestone | procedure/session ID, expected_version, stage/evidence | completion event and unique billable charge where rule permits; clinician/consent checks |
| Draft/issue invoice | patient_id, source_charge_ids, due_date, allowed line adjustments; issue includes expected_version | immutable issued number/totals/snapshots/source links; no duplicate consumed charge |
| Receive payment | patient_id, amount, received_at/business_date, method/account/reference, optional target invoice amounts, retry key | receipt ID/no, source ID, allocations, remaining/spendable credit and target balances; sum allocations never exceeds receipt |
| Allocate credit | source_credit_id, invoice_id, amount, retry key | posting ID and recalculated source/invoice balances; locks and same-patient/currency checks |
| Issue credit note | invoice_id, original line reductions, reason, required approval, retry key | note ID/no and any allocation-release events; adjustments bounded by uncredited line entitlement |
| Request/approve refund | source_id, amount, reason, method/account; separate approval action | reservation and workflow state; approver permission/separation policy |
| Complete refund | approved refund ID, payout reference/evidence, retry key | completed refund event and source/cash effects; reservation released atomically; cannot double complete |
| Reverse erroneous receipt | payment_id, reason, retry key | reversal event; reject if active allocations or completed refunds exist, or closed-period/policy controls prohibit; never also post a cash refund |
| Close reconciliation | batch_id, expected_version, verified totals, variance evidence | closed batch and posting coverage; atomic conflict check and immutable closure |
| Upload intent/finalize | patient/type/size; then authorized object reference/checksum | private generated key; validated version/status; object presence/type/size confirmed server-side |

Financial actions do not accept a client's actor, original amount, audit record, remaining credit or invoice balance as authority. Simple catalogue/draft fields use validated forms/serializers with the same service contracts. The implemented API schema is published from these contracts during each phase and reviewed for deviations.

## 23. Reviewable screen specifications and journey scripts

These are low-fidelity wireframe contracts rather than rendered designs. They specify what must be present and actionable. A rendered visual design can be produced after workflow review; no visual mockup in this planning document implies a working feature.

| Screen ID | Top area | Main area | Primary action / checks |
| --- | --- | --- | --- |
| UI01 Login | Clinic branding, login/reset | Email/password; safe error | Sign in; no clinic list leakage |
| UI02 Admin setup | Setup status, clinic identity | Staff/doctor/chair/policy sections | Save reviewed configuration; audit |
| UI03 Reception home | Local date, patient search | Single-chair timeline; doctor availability; arrivals queue | New booking/check in; lock/conflict feedback |
| UI04 Register patient | Search existing patients first | Demographics; contact/guardian; duplicate candidates | Create; never auto-merge |
| UI05 Patient workspace | Patient no/name/age/contact; role-appropriate alerts | Overview, visits/chart, plans, billing/payments, documents/prescriptions | Context-specific permitted actions |
| UI06 Book appointment | Patient and doctor | Local start/end; chair/resource; buffer/conflict preview | Save/reschedule with final server check |
| UI07 Clinical visit | Patient/history alert; visit doctor/status | Complaint, examination, chart, diagnosis, advice; prior visits | Save draft / Sign; stale-save message |
| UI08 Dental chart | Dentition and legend/orientation | Tooth grid; selected tooth/surfaces; history panel | Add/resolve finding; clinician attribution |
| UI09 Treatment plan | Version, proposed/accepted state | Items/teeth/prices; accepted/pending/completed/billed totals | Propose/accept revision; evidence |
| UI10 Procedure | Plan/source and patient | Session timeline; work recorded; required consent | Add session/complete; no automatic duplicate charge |
| UI11 Invoice | Patient; draft/issued number | Unbilled sources; lines; tax/discount; totals/due date | Issue with unique source consumption |
| UI12 Receive money | Patient and transaction mode | Account/method/reference; amount; selected invoices; credit remainder preview | Post receipt once; retry-safe |
| UI13 Apply credit | Patient's sources and available/reserved totals | Source and invoice selection; proposed allocation | Confirm; no silent netting |
| UI14 Statement/refund | Separate invoice due, remaining/spendable/reserved credit, net | Chronological postings and allocation detail; refund workflow | Print / Request refund; role checks |
| UI15 Daily accounting | Business date/account | Receipts, refunds, expected/verified/variance; detail | Verify/close; variance/reopen control |
| UI16 Reports | Role-scoped report menu | Filters, totals, detail, empty state | Print/export; audit and scoping |

Every screen includes permission denial, empty data, invalid input, saving/timeout, duplicate retry and conflict states where relevant. A timed-out receipt must offer verification/retry using the same key, not ask staff to create a fresh payment blindly.

### User acceptance journeys

**J01 — Single-visit treatment:** Reception registers patient → assigns free doctor and chair slot → arrival → dentist starts Visit and reviews history → chart/diagnosis → accepted treatment or documented direct service → procedure completion → unique charge → issued invoice → verified payment and explicit allocation → paid invoice → daily reconciliation.

**J02 — Multi-visit advance:** Accepted versioned plan → agreed advance receipt → source credit visible without false service invoice → actual sessions → completed billable milestone → invoice and confirmed source allocation → remaining work/credit shown separately → final completed balance billed once.

**J03 — Late payment and unused refund:** Partial payment → overdue invoice remains → later separate receipt settles it without new service sale → unrelated advance remains available → refund requested/reserved → authorized approval → payout completion → source/cash statement reconciles.

**J04 — Single-chair conflict:** Dentist A booking occupies chair 10:00–10:45 plus configured buffer → Dentist B competing booking rejected/rescheduled → actual treatment runs late → second start is blocked while chair occupied; the next booked appointment is flagged DELAY_RISK with a projected start and reception chooses wait or reschedule (logged) → release event permits next patient.

**J05 — Correction and restore:** Signed note corrected through amendment → paid invoice reduced through credit note and allocation release → refund if approved → restore database/files in rehearsal → note versions, posted balances and evidence files agree.

## 24. Implementation readiness and decision checklist

The plan is complete enough for detailed agent review; it is not automatically approved for code. Checklists separate architectural approval from local policy and live deployment. No agent should disguise unknown clinic facts as defaults.

| Gate ID | Decision / evidence | Status now | Blocks |
| --- | --- | --- | --- |
| G01 | One new Nepal pilot, four dentists, one chair, ~five patients/day, no records | Confirmed by user | None |
| G02 | Django modular monolith; templates/Tailwind; PostgreSQL; module boundaries | Proposed | Foundation approval |
| G03 | Phase 1 foundation-only; custom User schema timing | Specified for review | Foundation approval |
| G04 | User grants, owner clinical access, doctor care scope and support policy | Proposed | Phase 2/clinical permission approval |
| G05 | Unified credit allocation, no manual balances, reversal/reservation rules | Proposed | Financial schema approval |
| G06 | Single-chair resource locks, buffer and actual occupancy behavior | Proposed; buffer/hours unknown | Appointment approval |
| G07 | Real doctor names/availability and real services/prices | Not supplied; no invented production data | Clinic setup and treatment validation |
| G08 | Tooth chart convention, clinical templates, prescription/consent review | Dentist review pending | Clinical approval |
| G09 | Service-specific invoice timing/deposit/milestones/discount/refund terms | Proposed; no universal deposit percentage | Financial implementation |
| G10 | Nepal invoice/tax/e-billing/retention requirements from primary evidence | Verification pending | Billing approval/live use |
| G11 | Vercel commercial-plan eligibility/cost or revised hosting choice (including a self-managed VPS) | Unresolved no-budget preference | Live deployment; local work only if explicitly approved |
| G12 | External PostgreSQL, private storage/scan, region and backup provider | Pending compatibility/cost decision | Production deployment |
| G13 | Accounting export destination/mapping | Pending | Final export acceptance |
| G14 | Recovery targets, retention and downtime procedure | Proposed; clinic acceptance pending | Pilot readiness |
| G15 | Reviewer blockers disposition and final approved version | Pending | Application implementation authorization |
| G16 | Post-launch ownership and recurring cost (section 14A) | Proposed | Pilot readiness |

Phase 1 can be technically isolated from real clinic configuration and paid hosting, but starting it still requires the user's explicit approval of this plan or a specifically authorized foundation subset. The user's current request is for the reviewable plan only.

### Definition of done for each module/phase

- Approved scope and dependencies satisfied; actual behavior implemented without fake functional controls.
- Models, migrations, constraints and service interfaces agree with this document.
- UI/API, permissions, validation, audit and error/conflict states work together.
- Meaningful unit, PostgreSQL integration/concurrency and journey tests appropriate to the module pass.
- Documentation, API contracts and implementation-status register updated with evidence.
- Any new critical risk or altered business rule returns to review rather than being silently changed by the coder.
- No unapproved external deployment, subscriptions, real patient import or messages to third parties.

### Phase report template

```text
Plan version / approved scope:
Phase and modules completed:
Business behavior now available:
Model/migration changes:
Permission and tenant-isolation evidence:
UI/API actions verified:
Automated tests and commands/results:
Financial or clinical examples verified (if applicable):
Known limitations / unresolved findings:
Changed files and documentation:
Next phase dependencies:
Review gate reached; further work authorization:
```

## 25. Independent agent review package

This section is intended to be copied to other agents with this complete document attached. No independent-agent review has been performed or claimed as part of preparing this file. The user may collect reviews from any preferred tools; those reviewers must stay in review mode.

### General review prompt — copy and paste

```text
Review the attached Dental Clinic module-based implementation plan independently.
Do not implement, deploy, create paid services, or silently rewrite approved scope.

Context: new Nepal dental clinic; four dentists; one chair; approximately five
patients/day; no existing data. First release includes patient billing, advances,
refunds, reconciliation and accounting exports, not full general-ledger accounting.
Preferred initial host is Vercel; commercial-plan/budget conflict remains explicit.
Phase 1 must be foundation-only as specified, with minimal custom User schema
created before dependent migrations. No application implementation is authorized.

Evaluate:
1. Missing or contradictory requirements and dependencies.
2. Module ownership, schema fields, states and server/database constraints.
3. Patient clinical history, mixed dentition, signed notes and multi-visit treatment.
4. Single-chair scheduling and real occupancy across different doctors.
5. Source-fund conservation, allocations, credit notes, reversals, refunds and
   concurrent writes; recalculate the supplied financial examples independently.
6. Authentication, tenant/role isolation, documents and sensitive-data exposure.
7. Vercel compatibility, persistent storage, migrations, backups, commercial
   plan eligibility and cost assumptions, using current primary documentation.
8. Whether each phase has concrete implementation steps and measurable acceptance.

Return a concise executive assessment followed by a finding table:
Finding ID | Severity | Section/module/phase | Failure scenario |
Recommended correction | Required test | Blocks phase/live use?

Severity: Critical (money/data/security loss), High (wrong core behavior),
Medium (rework/usability/operational gap), Low (clarity/optional improvement).
Separate confirmed defects from proposed preferences and facts requiring verification.
Identify the smallest necessary fixes. Avoid replacing the chosen stack without
showing a concrete requirement it cannot meet. Do not claim approval on the user's
behalf. End with Ready for review / Ready after listed fixes / Not ready,
and identify any remaining decision the user must make.
```

### Specialist reviewer assignments

These may be sent to separate agents; parallel implementation is not implied.

| Reviewer | Focus | Required independent output |
| --- | --- | --- |
| Architecture/schema reviewer | Sections 4–5, 20–22; ownership, constraints, migration order | Contradictions, missing FK/field/invariant and circular dependencies |
| Finance reviewer | Sections 6, 6A, 11, M11/M12, Phase 8/9 | Recalculate all scenarios; conservation/credit-note/refund/as-of tests; accounting scope accuracy |
| Clinical workflow reviewer | M03/M06–M10, chart/consent/signing and J01/J02 | Unsafe workflow assumptions, missing clinician decisions; dentist review checklist |
| Security reviewer | M01/M13/M15; API/forms/files/exports/support paths | Threat scenarios, RLS/role/pool/tenant-link gaps and required denial tests |
| Deployment reviewer | Section 4A, M16, Phase 1/10 | Current Vercel fit, DB/storage adapter compatibility, costs/migration/restore gaps |
| Reception/usability reviewer | UI03–UI06/UI12–UI15, shared chair and payment retries | Click-flow friction, confusing due/credit display, conflict/error recovery |

### Consolidation and approval procedure

1. Give each reviewer this same version and context. Do not feed one reviewer's opinion as a fact to another.
2. Log each finding with source reviewer, severity, concrete failure and affected phase.
3. Resolve Critical/High implementation findings before the affected phase. Live-use blockers remain explicit even if local-only foundation is separately approved.
4. Accept/reject/defer each recommendation with a reason. Preserve fixed user facts and intentional scope boundaries.
5. Update one master document; do not keep incompatible architecture/finance alternatives as simultaneous instructions.
6. Re-run the necessary specialist review after material schema/financial/security changes.
7. Present the revised version and unresolved nonblocking decisions to the user; request explicit approval before application implementation.

| Finding ID | Reviewer | Severity | Affected module/phase | Accepted/rejected/deferred | Correction/evidence | Re-review result |
| --- | --- | --- | --- | --- | --- | --- |
| To be populated | — | — | — | — | — | — |

### Foundation implementation prompt — use only after approval

```text
Implement Phase 1 only from the approved version of this Dental Clinic plan.
Inspect the target repository and preserve existing work. Build the local Django,
PostgreSQL and Docker foundation, split settings, pinned dependencies, custom User
schema before dependent migrations, neutral templates/Tailwind assets, health checks,
safe logging/errors, PostgreSQL tests, CI definition and README.

Follow steps 1.1–1.11 and the Phase 1 acceptance checklist. Do not implement patient,
appointment, clinical, billing or financial workflows. Do not build user/role/clinic
administration screens yet. No paid accounts, external deployment or real patient data.
Add Vercel compatibility configuration and document production dependencies only.

Run migrations, checks, migration-drift validation, asset build and tests. Fix failures.
Return the phase report template with actual evidence and stop at the agreed gate.
If approved decisions conflict or a prerequisite is absent, report the exact blocker
instead of choosing a new architecture or continuing into Phase 2.
```

### Later module implementation prompt template

```text
Implement only Phase [number] / modules [IDs] of the approved plan version [version].
Read its module contracts, dependencies, shared constraints and acceptance criteria.
Inspect existing code; reuse established models/services and do not create duplicate
patient, doctor, account, invoice, money-source or balance tables.
Implement schema/migrations, transactional services, scoped UI/API, audit, validation
and meaningful tests together. Preserve immutable clinical/financial history.
Do not enlarge scope, alter an approved policy or start the next phase.
Run the phase checks, fix failures, update documentation/status and return evidence.
Stop at the approved review gate. No external deployment unless separately authorized.
```

## 26. Changes in version 0.4 (revision after review)

Contradictions fixed:

- M09/M10 circular dependency resolved with a `ConsentRequirement` interface and a two-part M10 delivery (Phase 7 order updated).
- Visit state unified: Visit is OPEN/CLOSED; note signing is a separate DRAFT/SIGNED state.
- Invoice VOID removed in favor of DRAFT/DISCARDED and credit notes; VOID only if G10 requires it.
- Receipt reversal defined: blocked while active allocations or completed refunds exist.
- Remaining opening-credit references removed (out of scope).
- Section 2 references now say "PDF §" to avoid clashing with this document's numbering.

Gaps filled:

- New financial examples: credit note after a partial refund, receipt reversal with allocations, and an approved write-off.
- Write-off, discount approval, plan alternatives and minimal LabOrder tracking added to the entity plan (items marked proposed need approval, D17).
- Chair overrun behavior (DELAY_RISK flag, no automatic moves).
- Clinical-record view auditing and break-glass access.
- Small-clinic fallback for approval separation.
- Nepal localization: BS fiscal-year data, Saturday weekly holiday, festival closures, UTC+05:45 tests.

Scope and risk changes:

- REST API made optional; the service layer is the contract. DRF removed from the baseline.
- Serverless pooling and RLS risks called out, with a Phase 2 spike using local PgBouncer and a recorded fallback.
- Self-managed VPS added as a hosting option to compare at G11/G12.
- Antivirus scanning turned into a decision (G12) instead of an implicit blocker.
- Added minimum approval to start Phase 1, an optional early scheduling milestone, a parallel long-lead workstream table and a post-launch operations section (14A, D16/G16).
- Section 22 declared the schema authority to limit drift across sections 5, 20 and 22.

Unchanged: confirmed pilot scope, the corrected statement, the unified Allocation model, Vercel cost caveats and the rule that no application code, deployment or independent review result is claimed. Vendor pricing and limits cited in sections 4A and 19 were not re-verified in this revision and must be rechecked before G11.
