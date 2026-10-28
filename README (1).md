# SaaS Customer Churn & Retention Analysis

An end-to-end analysis of customer churn for a subscription (SaaS) business. The analysis was written in **SQL (MySQL)** and the results were visualized in a 3-page **Power BI** dashboard.

**Business question:** Which customers churn, when do they churn, how much revenue does it cost, and which signals (if any) predict it?

---

## Dashboard

| Overview | Who churns | Retention |
|---|---|---|
| ![Overview](screenshots/1_overview.png) | ![Who churns](screenshots/2_who_churns.png) | ![Retention](screenshots/3_retention.png) |

- **Overview:** headline KPIs (churn rates, active MRR, MRR lost), MRR lost by month, active MRR by country
- **Who churns:** churn rate by industry, referral source, plan tier, country and trial status
- **Retention:** monthly signup cohort retention matrix (1, 3 and 6 months) and retention by the plan an account started on

---

## Dataset

The **RavenStack** dataset is a synthetic SaaS dataset with five tables covering January 2023 to December 2024.

| Table | Rows | Description |
|---|---|---|
| `accounts` | 500 | One row per customer account (industry, country, signup date, referral source, plan tier, churn flag) |
| `subscriptions` | 5,000 | Subscription contracts with start/end dates and MRR/ARR |
| `feature_usage` | 25,000 | Product usage events with usage counts and errors |
| `support_tickets` | 2,000 | Support tickets with resolution time, satisfaction and escalation |
| `churn_events` | 600 | Churn events with reason code, refund amount and upgrade/downgrade flags |

Source: *add the dataset link here, and check its license before adding the CSV files to the repository.*

---

## Tools and techniques

- **MySQL / Workbench:** schema design, data loading with `LOAD DATA`, joins, subqueries, CTEs, window functions (`RANK`, `ROW_NUMBER`, `NTILE`, `SUM() OVER`), conditional aggregation, date functions, cohort retention
- **Power BI Desktop:** data modeling (one-to-many relationships), DAX measures and calculated columns, matrix with conditional formatting
- **Analysis approach:** every churn rate is shown with its group size, and results that were not statistically meaningful are labeled as such

---

## Key findings

### Churn and revenue

| Metric | Value |
|---|---|
| Account churn rate | **22.0%** (110 of 500 accounts) |
| Subscription churn rate | 9.7% (486 of 5,000 subscriptions) |
| Reactivation rate | 10.2% of churn events |
| Active MRR | **$10.16M** |
| MRR lost to churned subscriptions | **$1.18M** (11.6% of active MRR) |
| Revenue concentration | The top 10% of accounts hold 27.4% of active MRR |
| Refunds paid on churn | $8,652, about 0.7% of MRR lost |

### Who churns

- **Industry matters.** DevTools churns at 31.0% against 16.0% for Cybersecurity, roughly twice the rate.
- **Acquisition channel matters.** Event-sourced accounts churn at 30.2% against 14.6% for partner-sourced accounts. Inside DevTools the same pattern holds (event 43.5%, ads 38.5%, partner 12.5%), while DevTools churn is spread evenly across countries.
- **Plan tier does not matter.** Churn is about 22% on Basic, Pro and Enterprise.
- **Trial accounts churn somewhat more** (25.8% vs 21.1%).
- **Country gaps come from small groups.** Germany is highest at 32.0%, but it has only 25 accounts.

### When they churn (cohort retention)

- Across measurable cohorts, retention is **83.0% at 1 month, 67.9% at 3 months and 56.0% at 6 months**.
- **Enterprise accounts start strongest but fade fastest.** Retention by starting plan (1 / 3 / 6 months): Enterprise 88.7 / 66.7 / **50.0**, Basic 83.8 / 69.2 / 59.5, Pro 78.2 / 68.8 / 58.3. The flat overall churn rate by plan hides this pattern.
- 2024 cohorts retain worse than 2023 cohorts, but see the data notes below.

### Why they churn

- Stated churn reasons are spread almost evenly (features 19.0%, support 17.3%, budget 17.3%, unknown 15.8%, competitor 15.3%, pricing 15.2%), so there is no single dominant cause.
- A downgrade preceded only 8.8% of churn events, and downgrades were not concentrated in budget or pricing reasons.

### Signals that did not predict churn

Several behavioral measures were nearly identical for churned and retained customers:

| Signal | Churned | Retained |
|---|---|---|
| Average usage per usage event | 10.03 | 10.02 |
| Days since last usage (excluding data quirks) | 140.9 | 138.2 |
| Errors per usage event | 0.566 | 0.564 |
| Support tickets per account, 30 days before the reference date | 0.185 | 0.189 |
| Escalation rate, last ticket vs earlier tickets (churned accounts) | 4.5% | 4.4% |

In this dataset churn tracks **who the customer is and how they were acquired**, not product usage or support experience.

---

## Data notes and limitations

- **Two churn definitions.** `accounts.churn_flag` marks 110 accounts, while `churn_events` contains 352 distinct accounts (75 overlap). The 22.0% headline uses the account flag, and the cohort retention uses each account's first churn date from `churn_events`.
- **Duplicate usage IDs.** The usage file has 21 repeated `usage_id` values (24,979 distinct). They are skipped on load in MySQL and removed in Power BI.
- **Usage after churn.** 164 churned subscriptions have usage dated after their end date. They are excluded from the usage-recency comparison.
- **Late-2024 spike.** MRR lost climbs steeply in the last months of the data (December 2024 is about 3x November). This looks like a data artifact, so December 2024 is excluded from the chart, and the weak Sep to Nov 2024 cohorts should be read with caution.
- **Trial subscriptions carry no revenue.** 778 trial subscriptions have an MRR of 0.
- **Small samples.** Country groups, individual cohort cells and some segment splits contain few accounts, so small gaps are not reliable.
- **Synthetic data.** The dataset is synthetic, so the absence of relationships (for example between errors and churn) should not be generalized to real businesses.

---

## Repository structure

```
saas-churn-analysis/
├── README.md
├── sql/
│   ├── 01_create_and_load.sql          # creates the tables and loads the CSV files
│   └── 02_churn_analysis_queries.sql   # all analysis queries, grouped by theme
├── powerbi/
│   └── saas_churn_dashboard.pbix
└── screenshots/
    ├── 1_overview.png
    ├── 2_who_churns.png
    └── 3_retention.png
```

## How to reproduce

**SQL**
1. Download the dataset and place the five CSV files in a folder.
2. In `01_create_and_load.sql`, replace `C:/path/to/` with your folder path and run the statements one at a time. This needs `local_infile` enabled (see the comments in the file).
3. Run the queries in `02_churn_analysis_queries.sql`.

**Power BI**
1. Open `saas_churn_dashboard.pbix` in Power BI Desktop.
2. If the data source path has changed, update it under Home > Transform data > Data source settings.

---

## Author

**Shreyash Makode**
[LinkedIn](add-your-link-here) | [GitHub](add-your-link-here)
