---
name: tax-prep
version: 0.1.0
description: |
  Canadian tax preparation assistant. Reads all tax documents from a folder,
  identifies and classifies each document, cross-references against CRA requirements,
  flags missing documents and optimization opportunities, and generates a comprehensive
  tax preparation plan with a detailed checklist for filing or taking to an accountant.
  Use when asked to "prepare my taxes", "organize tax documents", "tax prep",
  "review my tax documents", or "help with my Canadian taxes".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

# Canadian Tax Preparation Assistant

**CRITICAL DISCLAIMER — DISPLAY AT START OF EVERY SESSION:**

> **This tool is NOT a substitute for professional tax advice.** It organizes your
> documents, flags potential issues, and builds a preparation plan — but tax law is
> complex and penalties for errors are real. Always verify amounts against your
> original slips. If your situation involves anything non-trivial (self-employment,
> rental income, capital gains, foreign income, trusts, or amounts over $50K in any
> category), **consult a CPA or tax professional before filing.**
>
> This tool does NOT file your taxes. It prepares you to file accurately.

---

## Step 0: Gather Context

Ask the user for the tax document folder path. If they invoked the skill with an argument (a path), use that.

```bash
TAX_YEAR="2025"
FILING_YEAR="2026"
echo "Tax year: $TAX_YEAR (filing in $FILING_YEAR)"
echo "Filing deadline (employed): April 30, $FILING_YEAR"
echo "Filing deadline (self-employed): June 15, $FILING_YEAR"
echo "Payment deadline (all): April 30, $FILING_YEAR"
date "+Current date: %Y-%m-%d"
```

Use AskUserQuestion to confirm:

1. **Document folder path** — where are your tax documents? (PDFs, images, scans)
2. **Province/territory of residence** on December 31 of the tax year
3. **Filing situation** — are you employed, self-employed, both, retired, student, or a combination?
4. **Marital status** on December 31 — single, married/common-law, separated, divorced, widowed?
5. **Do you have dependents?** — children under 18, disabled dependents, elderly dependents?
6. **Any of these situations?** (check all that apply):
   - Rental property income
   - Capital gains/losses (sold investments, property, crypto)
   - Foreign income or foreign property over $100K CAD
   - Self-employment or freelance income
   - Home office expenses
   - Medical expenses
   - Disability (yours or a dependent's)
   - Moving expenses (for work or school, 40km+ closer)
   - Tuition/education (you or transferred from a dependent)
   - RRSP contributions
   - Charitable donations
   - First-time home buyer
   - Climate Action Incentive (rural supplement)

Store all answers — they determine which phases to activate and which documents to expect.

---

## Step 1: Document Inventory & Classification

### 1a: Scan the folder

Read every file in the provided folder. For PDFs, read and extract text. For images, read them visually. For each document:

1. **Identify the document type** from the CRA taxonomy below
2. **Extract key data points** (amounts, dates, box numbers, issuer names)
3. **Flag any quality issues** (blurry scans, partial documents, missing pages)
4. **Note the tax year** — flag if any document is NOT for the current tax year

### 1b: CRA Document Taxonomy

Classify each document into one of these categories:

**INCOME SLIPS (T-slips)**

| Slip | Full Name | What It Reports | Key Boxes |
|------|-----------|-----------------|-----------|
| T4 | Statement of Remuneration Paid | Employment income | Box 14 (employment income), Box 16 (CPP contributions), Box 18 (EI premiums), Box 22 (income tax deducted), Box 24 (EI insurable earnings), Box 26 (CPP pensionable earnings), Box 40 (taxable benefits), Box 44 (union dues), Box 46 (charitable donations) |
| T4A | Statement of Pension, Retirement, Annuity, and Other Income | Pensions, scholarships, self-employed commissions, CERB/CRB, other income | Box 016 (pension), Box 018 (lump-sum payments), Box 020 (self-employed commissions), Box 022 (income tax deducted), Box 028 (other income), Box 048 (fees for services), Box 105 (scholarships/bursaries), Box 130 (wage-loss replacement), Box 197-204 (COVID benefits) |
| T4A(OAS) | Statement of Old Age Security | OAS payments | Box 18 (OAS pension), Box 22 (tax deducted) |
| T4A(P) | Statement of Canada Pension Plan Benefits | CPP/QPP benefits | Box 20 (CPP/QPP benefits), Box 22 (tax deducted) |
| T4E | Statement of Employment Insurance Benefits | EI benefits | Box 14 (EI benefits), Box 15 (regular benefits), Box 22 (tax deducted) |
| T4RIF | Statement of Income from a RRIF | RRIF withdrawals | Box 16 (taxable amounts), Box 22 (tax deducted) |
| T4RSP | Statement of RRSP Income | RRSP withdrawals | Box 16 (taxable amounts for HBP), Box 22 (tax deducted), Box 26 (taxable amounts) |
| T3 | Statement of Trust Income | Trust distributions (mutual funds in non-reg accounts, income trusts, estate income) | Box 21 (capital gains), Box 23 (actual capital gains), Box 25 (foreign business income), Box 26 (other income), Box 32 (foreign non-business income tax paid), Box 49 (eligible dividends), Box 50 (actual dividends) |
| T5 | Statement of Investment Income | Interest, dividends, royalties | Box 11 (taxable dividends - other than eligible), Box 13 (interest), Box 14 (other income), Box 24 (eligible dividends), Box 25 (actual eligible dividends), Box 26 (actual other dividends) |
| T5007 | Statement of Benefits | Social assistance, workers' comp | Box 10 (benefits) |
| T5008 | Statement of Securities Transactions | Proceeds from sale of securities | Box 20 (proceeds), Box 21 (cost/book value) |
| T5013 | Statement of Partnership Income | Partnership income/loss | Various boxes depending on income type |
| T2202 | Tuition and Enrolment Certificate | Tuition amounts, months enrolled | Box A (tuition fees), Box B (months part-time), Box C (months full-time) |
| RC62 | Universal Child Care Benefit | UCCB income | Box 10 (UCCB), Box 12 (UCCB repayment) |
| RC210 | Tax Instalment Reminder/Receipt | Tax instalments paid | Instalment amounts by quarter |
| T1204 | Government Service Contract Payments | Payments for government contracts | Box 22 (contract payments) |
| T2200/T2200S | Declaration of Conditions of Employment | Employer certification for employment expense claims | Not a slip — a signed form from employer |
| RL-slips (Quebec) | Releve slips | Quebec provincial equivalents of federal T-slips | Various |

**RECEIPTS & SUPPORTING DOCUMENTS**

| Document | Purpose | What to Extract |
|----------|---------|----------------|
| RRSP contribution receipts | Deduction claim | Amount, contribution date (before/after March 3), contributor name, plan holder name |
| RRSP unused contribution room | Previous year NOA | Available room from prior year Notice of Assessment |
| Charitable donation receipts | Tax credit claim | Charity name, registration number, amount, date, whether it's a gift in kind |
| Medical expense receipts | Medical expense tax credit | Provider, amount, date, patient name, nature of expense |
| Child care receipts | Child care expense deduction | Provider name/SIN/business number, child name, amount, period |
| Transit passes (if applicable) | Transit credit (check if still available) | Amount, period |
| Moving expense receipts | Moving expense deduction | Each expense type, amount, old/new addresses |
| Home accessibility receipts | Home accessibility tax credit | Contractor, amount, nature of renovation |
| Digital news subscription receipts | Digital news tax credit | Publication name, amount, qualifying status |
| Property tax bill | Various credits (provincial) | Amount paid, municipal address |
| Rent receipts | Provincial credits (ON, MB, etc.) | Monthly amounts, landlord name/address |
| Professional/union dues receipts | Line 21200 | Organization, amount |
| Interest paid on student loans | Line 31900 | Lender, interest amount |
| Tuition receipts (foreign institutions) | Tuition tax credit | Institution, amount in foreign currency, exchange rate |
| Home Buyers' Plan (HBP) tracking | RRSP repayment | Prior year HBP balance, repayment amount |
| Lifelong Learning Plan (LLP) tracking | RRSP repayment | Prior year LLP balance, repayment amount |
| Prior year Notice of Assessment (NOA) | RRSP room, loss carryforwards, HBP/LLP balance | Assessed amounts, RRSP deduction limit, carryforward balances |
| T1135 Foreign Income Verification | Foreign property > $100K CAD | Property type, country, cost, income, gain/loss |
| T1134 Information Return for Foreign Affiliates | Foreign affiliate ownership | Ownership details, income amounts |
| Sale of principal residence documentation | Principal residence exemption | Purchase date/price, sale date/price, years designated |
| Rental income/expense records | Rental income reporting | Gross rent, each expense category, property address, CCA class |
| Business income/expense records | Self-employment (T2125) | Revenue, each expense category, vehicle logs, home office % |

### 1c: Document Inventory Output

After scanning all documents, produce a structured inventory:

```
DOCUMENT INVENTORY
══════════════════════════════════════════════════════════════
Tax Year: 2025 | Province: [province] | Documents Found: N

INCOME SLIPS FOUND:
  [x] T4 — [Employer Name] — Employment income: $XX,XXX.XX
  [x] T5 — [Bank Name] — Interest: $X,XXX.XX, Dividends: $X,XXX.XX
  [x] T3 — [Fund Name] — Capital gains: $X,XXX.XX
  ...

RECEIPTS & SUPPORTING DOCS FOUND:
  [x] RRSP contribution receipts — Total: $X,XXX.XX (N receipts)
  [x] Charitable donation receipts — Total: $X,XXX.XX (N receipts)
  [x] Medical expense receipts — Total: $X,XXX.XX (N receipts)
  ...

QUALITY ISSUES:
  [!] document_name.pdf — [issue description]
  ...

WRONG TAX YEAR:
  [!] document_name.pdf — This is for tax year 20XX, not 2025
  ...

UNCLASSIFIED DOCUMENTS:
  [?] document_name.pdf — Could not identify document type
  ...
══════════════════════════════════════════════════════════════
```

---

## Step 2: Gap Analysis — Missing Documents

Based on the user's filing situation (from Step 0), determine what documents are **expected but missing**.

### 2a: Universal Requirements (everyone needs these)

- [ ] At least one T4, T4A, or other income slip (unless no income)
- [ ] Prior year Notice of Assessment (for RRSP room, carryforwards)
- [ ] SIN confirmation (not a document to scan, but confirm they have it)

### 2b: Situation-Specific Requirements

**If employed:**
- [ ] T4 from EVERY employer worked for in the tax year
- [ ] T2200/T2200S if claiming employment expenses
- [ ] Vehicle log if claiming vehicle expenses for work

**If self-employed:**
- [ ] All invoices/revenue records OR accounting summary
- [ ] All business expense receipts organized by category
- [ ] GST/HST collected and paid (if registered)
- [ ] Vehicle log with business vs. personal km
- [ ] Home office measurements (dedicated space square footage vs. total)
- [ ] Business-use-of-home expenses (utilities, insurance, property tax, mortgage interest, rent)

**If investments/capital gains:**
- [ ] T5008 from each brokerage
- [ ] T3 from each mutual fund/trust
- [ ] T5 from each bank/institution paying interest or dividends
- [ ] Adjusted cost base (ACB) records for sold securities
- [ ] Sale/purchase records for real property sold
- [ ] Crypto transaction records (each disposition is a taxable event)

**If rental property:**
- [ ] Rental income records (lease agreements, bank deposits)
- [ ] Expense receipts by category (insurance, maintenance, property tax, utilities, mortgage interest, management fees, advertising, legal/accounting, travel to property)
- [ ] CCA schedule from prior year
- [ ] Details of any capital improvements vs. repairs

**If foreign income/property:**
- [ ] Foreign income documentation with amounts in original currency
- [ ] Bank of Canada exchange rates for each transaction date
- [ ] T1135 data if total cost of foreign property > $100K CAD at any time in the year
- [ ] Foreign tax paid documentation (for foreign tax credit)

**If student:**
- [ ] T2202 from each educational institution
- [ ] Student loan interest statement
- [ ] T4A for scholarships/bursaries

**If medical expenses:**
- [ ] All medical/dental receipts (only expenses > 3% of net income OR $2,759 for 2025, whichever is less, qualify)
- [ ] Private health insurance premiums paid
- [ ] Travel expenses for medical care (40km+ one way)
- [ ] Prescribed medication receipts

**If moved (40km+ closer to new work/school):**
- [ ] Moving company receipts OR vehicle log for self-move
- [ ] Travel expenses (meals, accommodation during move)
- [ ] Temporary living expenses (up to 15 days)
- [ ] Lease cancellation fees, legal fees for new home
- [ ] Old and new address documentation
- [ ] Connection/disconnection fees for utilities

**If first-time home buyer:**
- [ ] Purchase agreement or closing statement
- [ ] Date of purchase
- [ ] Confirmation neither you nor spouse owned a home in the prior 4 years

**If childcare expenses:**
- [ ] Receipts from each childcare provider
- [ ] Provider's SIN or business number
- [ ] Child's date of birth
- [ ] Confirmation of eligibility (generally must be claimed by lower-income spouse)

### 2c: Missing Document Report

```
MISSING DOCUMENT ANALYSIS
══════════════════════════════════════════════════════════════

CRITICAL (cannot file accurately without these):
  [!] T4 from [Employer B] — You mentioned two employers but only one T4 found
  [!] Prior year NOA — Needed for RRSP deduction limit
  ...

RECOMMENDED (may reduce tax or cause issues if missing):
  [~] RRSP contribution receipts — You mentioned RRSP contributions
  [~] T5008 — You mentioned selling investments but no T5008 found
  ...

OPTIONAL (nice to have, may qualify for additional credits):
  [i] Rent receipts — Your province offers a renter's credit
  [i] Transit pass receipts — Check if provincial credit available
  ...

ACTION ITEMS:
  1. Log into CRA My Account to download missing T-slips (available by late February)
  2. Contact [Employer B] payroll for T4
  3. Check your bank's online portal for T5/T3 slips
  4. Request prior year NOA from CRA My Account or call 1-800-959-8281
══════════════════════════════════════════════════════════════
```

---

## Step 3: Tax Situation Analysis & Red Flags

Analyze the collected documents for issues, opportunities, and risks.

### 3a: Income Reconciliation

For each income source:
1. **Cross-reference T-slips** — do amounts on related slips make sense together? (e.g., T4 CPP contributions should match expected rate on employment income)
2. **Check for common errors on slips** — sometimes employers make mistakes. Flag anything unusual:
   - Employment income that seems too high or too low for the period
   - Missing taxable benefits that should be on T4 (e.g., employer-paid health/dental premiums in some provinces)
   - Inconsistent dates
3. **Estimate total income** — sum all income sources for a preliminary total

### 3b: Deduction & Credit Optimization

Review all documents for optimization opportunities:

**RRSP Optimization:**
- Calculate RRSP deduction room (from prior NOA + new room from this year's earned income)
- Compare contributions made vs. available room
- Flag if contributions exceed limit (over-contribution penalty: 1% per month on amount >$2,000 over limit)
- Note: RRSP contributions in first 60 days of the filing year can be claimed in either tax year — flag which year is optimal
- **Spousal RRSP**: If married/common-law with income disparity, flag potential spousal RRSP benefit

**Pension Income Splitting (if applicable):**
- If one spouse has eligible pension income and the other has lower income
- Up to 50% of eligible pension income can be allocated to the other spouse
- Model the tax savings from splitting vs. not splitting

**Dividend Gross-Up & Credit:**
- Eligible dividends are grossed up by 38% then receive a 15.0198% federal credit
- Other than eligible dividends are grossed up by 15% then receive a 9.0301% federal credit
- Flag if dividend income pushes into higher bracket — sometimes this means dividends are tax-inefficient in non-registered accounts

**Capital Gains/Losses:**
- Capital gains inclusion rate: 50% for first $250,000 (2025 rules — **verify current legislation as this may have changed**)
- Check for capital loss carryforwards from prior years
- Flag if losses can offset gains this year
- Flag superficial loss rule violations (repurchased substantially identical property within 30 days before or after)
- **Principal residence exemption**: If a home was sold, check eligibility. Must have been ordinarily inhabited. Only ONE property per family unit per year can be designated.

**Medical Expenses:**
- Calculate if medical expenses exceed the threshold (3% of net income or $2,759 for 2025, whichever is less)
- Suggest which spouse should claim (generally the lower-income spouse)
- Note: 12-month period doesn't have to be the calendar year — optimize the 12-month window
- Flag commonly missed medical expenses: travel for medical care, premiums, dental, vision, prescriptions, medical devices, attendant care

**Charitable Donations:**
- First $200 gets 15% federal credit, amount above $200 gets 29% (33% if income > top bracket)
- Flag if one spouse should claim all donations (generally the higher-income spouse)
- Flag if donations from both spouses should be combined on one return
- Check for donation carryforwards (can carry forward up to 5 years)
- **Super credit for first-time donors** — check eligibility

**Other Credits to Check:**
- Canada Workers Benefit (CWB) — for low-income workers
- GST/HST credit — automatic if you file, but flag if eligible
- Canada Child Benefit (CCB) — needs to file to receive
- Climate Action Incentive Payment — automatic in applicable provinces
- Canada Training Credit — for education expenses, ages 26-65
- Home Accessibility Tax Credit — for seniors/disabled
- Home Buyers' Amount — $10,000 credit for first-time buyers ($1,500 tax reduction)
- Disability Tax Credit (DTC) — T2201 required
- Caregiver Credit — for supporting an infirm dependent
- Canada Caregiver Amount
- Age amount — if 65+ and income below threshold
- Pension income amount — up to $2,000 credit
- Interest on student loans — only federal/provincial student loans qualify, not lines of credit
- Digital News Subscription Credit

### 3c: Red Flags & Audit Risk Factors

Flag items that increase audit risk or require special attention:

```
RED FLAGS & IMPORTANT NOTICES
══════════════════════════════════════════════════════════════

HIGH PRIORITY (get wrong = penalties + interest):
  [!!] Large RRSP over-contribution detected — $X,XXX over limit
       → Penalty: 1% per month. File T1-OVP immediately.
  [!!] Foreign property appears to exceed $100K CAD — T1135 required
       → Penalty for not filing: $25/day, max $2,500
  [!!] Rental loss claimed with personal use — CRA scrutinizes this heavily
  ...

MEDIUM PRIORITY (common audit triggers):
  [!] Home office deduction claimed — ensure T2200 is signed by employer
  [!] Vehicle expenses claimed — CRA requires a contemporaneous log
  [!] Large charitable donations relative to income — may trigger review
  [!] Claiming moving expenses — ensure 40km rule is met (straight-line distance)
  ...

OPTIMIZATION OPPORTUNITIES:
  [+] You may be able to split pension income — estimated savings: $X,XXX
  [+] Medical expenses could be claimed on spouse's return for larger credit
  [+] Capital losses from prior years may offset this year's gains
  [+] RRSP contribution room available — contributing reduces tax by $X,XXX
  ...

TAX LAW ALERTS (2025 tax year changes):
  [i] Capital gains inclusion rate changes — verify current rules
  [i] TFSA contribution limit for 2025 — verify current limit
  [i] Basic personal amount for 2025 — verify indexed amount
  [i] New or changed credits — search CRA for 2025 tax year changes
  ...
══════════════════════════════════════════════════════════════
```

**IMPORTANT:** For any tax law amount, rate, or threshold — always note that values should be verified against current CRA published figures. Tax amounts are indexed annually and legislation changes.

---

## Step 4: Comprehensive Tax Preparation Plan

Generate a detailed, actionable plan the user can follow to file their return or take to their accountant.

### 4a: Income Summary

```
INCOME SUMMARY (2025 Tax Year)
══════════════════════════════════════════════════════════════

EMPLOYMENT INCOME:
  T4 — [Employer A]: $XX,XXX.XX (Box 14)
  T4 — [Employer B]: $XX,XXX.XX (Box 14)
  Subtotal: $XX,XXX.XX

INVESTMENT INCOME:
  T5 — [Bank]: Interest $X,XXX.XX (Box 13)
  T3 — [Fund]: Capital gains $X,XXX.XX (Box 21)
  T5 — [Bank]: Eligible dividends $X,XXX.XX (Box 25, grossed-up: $X,XXX.XX)
  Subtotal: $XX,XXX.XX

SELF-EMPLOYMENT INCOME (if applicable):
  Gross revenue: $XX,XXX.XX
  Total expenses: ($XX,XXX.XX)
  Net self-employment income: $XX,XXX.XX

OTHER INCOME:
  [List each source]
  Subtotal: $XX,XXX.XX

TOTAL INCOME (Line 15000): $XXX,XXX.XX
══════════════════════════════════════════════════════════════
```

### 4b: Deductions Summary

```
DEDUCTIONS (reducing taxable income)
══════════════════════════════════════════════════════════════
RRSP deduction (Line 20800): $XX,XXX.XX
Union/professional dues (Line 21200): $XXX.XX
Child care expenses (Line 21400): $X,XXX.XX
Moving expenses (Line 21900): $X,XXX.XX
Support payments made (Line 22000): $X,XXX.XX
Carrying charges (Line 22100): $XXX.XX
Other deductions: $XXX.XX

TOTAL DEDUCTIONS: $XX,XXX.XX
NET INCOME (Line 23600): $XXX,XXX.XX

Additional deductions from net income:
Social benefits repayment (Line 23500): $X,XXX.XX
Capital gains deduction (Line 25400): $X,XXX.XX
Northern residents deduction (Line 25600): $X,XXX.XX
Other (Line 25000): $XXX.XX

TAXABLE INCOME (Line 26000): $XXX,XXX.XX
══════════════════════════════════════════════════════════════
```

### 4c: Credits Summary

```
NON-REFUNDABLE TAX CREDITS
══════════════════════════════════════════════════════════════
Basic personal amount: $XX,XXX (verify 2025 indexed amount)
CPP/QPP contributions (employee): $X,XXX.XX
CPP/QPP contributions (self-employed): $X,XXX.XX
EI premiums: $XXX.XX
Canada employment amount: $X,XXX (verify 2025 amount)
Pension income amount: $X,XXX.XX
Tuition (from T2202): $X,XXX.XX
Tuition transferred from child: $X,XXX.XX
Medical expenses: $X,XXX.XX (above threshold)
Charitable donations: $X,XXX.XX
Disability amount: $X,XXX.XX
Interest on student loans: $XXX.XX
Home buyers' amount: $XX,XXX
[Other applicable credits]

Total credits at 15%: $X,XXX.XX
Charitable donations credit (above $200 at 29/33%): $X,XXX.XX
Dividend tax credit (federal): $X,XXX.XX

ESTIMATED FEDERAL TAX: $XX,XXX.XX
══════════════════════════════════════════════════════════════
```

### 4d: Provincial Tax Estimate

```
PROVINCIAL TAX ([Province])
══════════════════════════════════════════════════════════════
[Province] tax on taxable income: $XX,XXX.XX
Provincial credits: ($X,XXX.XX)
Provincial surtax (if applicable): $X,XXX.XX

NET PROVINCIAL TAX: $XX,XXX.XX
══════════════════════════════════════════════════════════════
```

### 4e: Tax Owing / Refund Estimate

```
TAX SUMMARY
══════════════════════════════════════════════════════════════
Federal tax: $XX,XXX.XX
Provincial tax: $XX,XXX.XX
CPP contributions payable (self-employed portion): $X,XXX.XX
EI premiums payable (self-employed, if opted in): $XXX.XX

TOTAL TAX: $XX,XXX.XX

Tax already paid:
  Income tax deducted (from all T4s/T4As): ($XX,XXX.XX)
  Tax instalments paid: ($X,XXX.XX)
  [Other credits paid at source]

TOTAL PAID: ($XX,XXX.XX)

══════════════════════════════════════════════════════════════
ESTIMATED REFUND: $X,XXX.XX
  — OR —
ESTIMATED TAX OWING: $X,XXX.XX (due April 30, FILING_YEAR)
══════════════════════════════════════════════════════════════

NOTE: This is an ESTIMATE. Actual amounts depend on exact CRA
calculations, indexed amounts for the tax year, and any items
not captured in your documents. Use this as a guide, not a
final calculation.
```

---

## Step 5: Detailed Filing Checklist

Generate a comprehensive, ordered checklist the user can follow. Write this to a file in the document folder.

```
TAX FILING CHECKLIST — 2025 TAX YEAR
══════════════════════════════════════════════════════════════
Generated: [date]
Province: [province]
Filing Status: [employed/self-employed/etc.]
Marital Status: [status]

BEFORE YOU START:
[ ] Gather your SIN (and spouse's SIN if applicable)
[ ] Get your CRA My Account login (or register at canada.ca)
[ ] Download any missing T-slips from My Account (available late Feb)
[ ] Get your prior year Notice of Assessment
[ ] [Any situation-specific items from Step 2]

FORMS YOU NEED TO FILE:
[ ] T1 General — Income Tax and Benefit Return
[ ] Schedule 1 — Federal Tax (always required)
[ ] [Province] Provincial Tax Form (Schedule [X])
[Each applicable schedule listed with why it's needed]

REQUIRED SCHEDULES (based on your situation):
[ ] Schedule 2 — Federal Amounts Transferred from Your Spouse
    → Because: [reason]
[ ] Schedule 3 — Capital Gains (or Losses)
    → Because: you sold investments/property
[ ] Schedule 4 — Statement of Investment Income
    → Because: you have T3/T5 income
[ ] Schedule 5 — Details of Dependant
    → Because: you're claiming dependant credits
[ ] Schedule 6 — Working Income Tax Benefit
    → Because: [eligibility reason]
[ ] Schedule 7 — RRSP, PRPP and SPP Unused Contributions,
    Transfers, and HBP or LLP Activities
    → Because: you made RRSP contributions
[ ] Schedule 8 — CPP Contributions on Self-Employment Income
    → Because: you have self-employment income
[ ] Schedule 9 — Donations and Gifts
    → Because: you're claiming charitable donations
[ ] Schedule 11 — Federal Tuition, Education and Textbook Amounts
    → Because: you have tuition amounts
[ ] T2125 — Statement of Business or Professional Activities
    → Because: you have self-employment income
[ ] T776 — Statement of Real Estate Rentals
    → Because: you have rental income
[ ] T1135 — Foreign Income Verification Statement
    → Because: foreign property cost > $100K
[ ] [Any other applicable forms]

STEP-BY-STEP FILING ORDER:
1. [ ] Enter personal information (SIN, name, DOB, address, marital status)
2. [ ] Enter all T4 income (Line 10100)
   - [Employer A]: $XX,XXX (Box 14)
   - [Employer B]: $XX,XXX (Box 14)
3. [ ] Enter all T4A income (if applicable)
4. [ ] Enter investment income from T3/T5 slips
   - Interest: $X,XXX → Line 12100
   - Taxable dividends: $X,XXX → Line 12000
   - Capital gains from T3: $X,XXX → Schedule 3
5. [ ] Complete Schedule 3 for capital gains/losses (if applicable)
   - T5008 proceeds: $XX,XXX
   - Adjusted cost base: $XX,XXX
   - Capital gain/loss: $XX,XXX
   - Taxable capital gain (50%): $XX,XXX → Line 12700
6. [ ] Enter self-employment income (T2125) (if applicable)
   - Gross revenue: $XX,XXX
   - Expenses by category: [list each]
   - Net income: $XX,XXX → Line 13500
7. [ ] Enter rental income (T776) (if applicable)
8. [ ] Enter other income sources
9. [ ] Enter RRSP deduction → Line 20800
   - Contribution: $XX,XXX
   - Available room (from NOA): $XX,XXX
   - Deduction this year: $XX,XXX
10. [ ] Enter other deductions (union dues, child care, etc.)
11. [ ] Calculate net income (Line 23600)
12. [ ] Enter non-refundable tax credits (Schedule 1)
13. [ ] Enter medical expenses (if above threshold)
14. [ ] Enter charitable donations (Schedule 9)
15. [ ] Calculate federal tax
16. [ ] Complete provincial tax form
17. [ ] Enter provincial credits
18. [ ] Calculate total tax owing or refund
19. [ ] Review all entries against original slips
20. [ ] [If joint considerations] Optimize with spouse's return
21. [ ] File electronically via NETFILE or paper

POST-FILING:
[ ] Keep all receipts and documents for 6 years (CRA can audit)
[ ] Note RRSP contribution room for next year
[ ] Set up direct deposit for refund (in My Account)
[ ] Review NOA when received — ensure no discrepancies
[ ] If tax owing: pay by April 30 to avoid interest
[ ] [If self-employed] Consider instalment payments for next year

DEADLINES:
[ ] April 30, FILING_YEAR — Filing deadline (employed) & payment deadline (all)
[ ] June 15, FILING_YEAR — Filing deadline (self-employed)
    ⚠ Even though filing deadline is June 15, tax OWING is still due April 30!
[ ] 60 days into FILING_YEAR — Last day for RRSP contributions counting for tax year
══════════════════════════════════════════════════════════════
```

---

## Step 6: Generate Output Files

Write the following files to the user's tax document folder:

### 6a: `tax-preparation-plan.md`
The full plan from Steps 1-5, formatted as a clean markdown document.

### 6b: `document-inventory.md`
The document inventory from Step 1c.

### 6c: `filing-checklist.md`
The detailed checklist from Step 5 as a markdown file with checkboxes.

### 6d: `missing-documents.md`
The gap analysis from Step 2c.

### 6e: `tax-summary.md`
The income/deduction/credit/tax summaries from Step 4.

### 6f: `red-flags-and-opportunities.md`
The red flags and optimization opportunities from Step 3c.

### 6g: `for-your-accountant.md`
A summary document specifically designed to give to an accountant:
- Your filing situation
- All income sources with amounts
- All deductions and credits you believe you qualify for
- Questions you have
- Items you're unsure about
- Red flags that need professional guidance

---

## Step 7: Final Summary

Present a concise summary to the user:

```
TAX PREP COMPLETE
══════════════════════════════════════════════════════════════
Documents found: N
Documents classified: N
Missing documents: N (see missing-documents.md)
Red flags: N
Optimization opportunities: N

Estimated total income: $XXX,XXX
Estimated taxable income: $XXX,XXX
Estimated tax: $XX,XXX
Already paid: $XX,XXX
Estimated refund/owing: $X,XXX [REFUND/OWING]

Files generated in [folder]:
  - tax-preparation-plan.md (comprehensive plan)
  - document-inventory.md (all documents catalogued)
  - filing-checklist.md (step-by-step checklist)
  - missing-documents.md (what you still need)
  - tax-summary.md (income/deduction/credit summary)
  - red-flags-and-opportunities.md (issues & savings)
  - for-your-accountant.md (take this to your CPA)

NEXT STEPS:
1. [Most urgent action — e.g., get missing T4]
2. [Second action]
3. [Third action]

⚠ REMINDER: This is a preparation tool, not tax advice.
  Verify all amounts against original slips before filing.
  Consult a professional if your situation is complex.
══════════════════════════════════════════════════════════════
```

---

## Important Rules

- **ACCURACY IS PARAMOUNT.** A tax error can cost real money in penalties, interest, and missed deductions. Double-check every amount extracted from documents.
- **When in doubt, flag it.** It's better to over-flag than to miss something. The user can always dismiss a flag.
- **Never fabricate numbers.** If you can't read a document clearly, say so. If an amount is ambiguous, note both possibilities.
- **Verify tax law claims.** Tax rates, thresholds, and credit amounts change every year. Always note when an amount needs verification against current CRA publications.
- **Privacy.** Tax documents contain extremely sensitive personal information. Never suggest uploading documents to external services. All processing is local.
- **Provincial differences matter.** Each province has its own tax rates, credits, and forms. Always account for the user's province.
- **The 12-month medical expense rule.** Medical expenses can be claimed for ANY 12-month period ending in the tax year. Optimize the window.
- **Spousal optimization.** Many credits/deductions are more valuable when claimed by a specific spouse. Always consider both returns together.
- **Carryforward awareness.** Tuition, donations, capital losses, and other amounts can be carried forward. Always check if prior year carryforwards exist.
- **CCA (Capital Cost Allowance).** For rental properties and self-employment, CCA is optional and strategic. Claiming CCA on a rental property prevents the principal residence exemption on that property. Flag this risk.
- **Superficial loss rule.** If securities are sold at a loss and substantially identical securities are acquired within 30 days before or after, the loss is denied. Flag any T5008 losses near year-end.
- **Attribution rules.** Income earned on funds given/loaned to a spouse or minor child may be attributed back to the transferor. Flag potential attribution issues.
- **TFSA over-contributions.** TFSAs don't generate tax slips but over-contributions are penalized 1% per month. If the user mentions TFSA, ask about contribution room.
