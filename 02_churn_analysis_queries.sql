-- ========================  SaaS Churn Analysis Project ========================
use project2;
-- ---------------------------------------------------------------------------------

-- accounts --

create table accounts
(
	account_id varchar(50) primary key,
    account_name varchar(50),
    industry varchar(50),
    country varchar(50),
    signup_date date,
    referral_source varchar(50),
    plan_tier varchar(50),
    seats int,
    is_trial boolean,
    churn_flag boolean
);

-- -----------------------------------------------------------------------------------------------

-- churn_event --

create table churn_event
(
	churn_event_id varchar(50) primary key,
    account_id varchar(50),
    churn_date date,
    reason_code varchar(50),
    refund_amount_usd decimal(10,2),
    preceding_upgrade_flag boolean,
    preceding_downgrade_flag boolean,
    is_reactivation boolean,
    feedback_text varchar(255),
    foreign key (account_id) references accounts(account_id)
);

-- -------------------------------------------------------------------------------------------------------

-- feature_use --

create table feature_use
(
	usage_id varchar(50) primary key,
    subscription_id varchar(50),
    usage_date date,
    feature_name varchar(50),
    usage_count int,
    usage_duration_secs int,
    error_count int,
    is_beta_feature boolean,
    foreign key (subscription_id) references subcription(subscription_id)
);

-- -------------------------------------------------------------------------------------------------

-- subscription --

create table subcription
(
	subscription_id varchar(50) primary key,
    account_id varchar(50),
    start_date date,
    end_date date,
    plan_tier varchar(50),
    seats int,
    mrr_amount decimal(10,2),
    arr_amount decimal(10,2),
    is_trial boolean,
    upgrad_flag boolean,
    downgrad_flag boolean,
    churn_flag boolean,
    billing_frequency varchar(50),
    auto_renew_flag boolean,
    foreign key (account_id) references accounts(account_id)
);

-- ----------------------------------------------------------------------------------------------

-- support_ticket --

create table support_ticket
(
	ticket_id varchar(50) primary key,
    account_id varchar(50),
    submitted_at date,
    closed_at datetime,
    resolution_time_hours int,
    priority varchar(50),
    first_response_time_minutes int,
    satisfaction_score int,
    escalation_flag boolean,
    foreign key (account_id) references accounts(account_id)
);

-- ------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------
-- Data Loading --
SET GLOBAL local_infile = 1;
-- -----------------------------------------
-- accounts --

LOAD DATA LOCAL INFILE "C:\Users\shraddha makode\Downloads\archive\ravenstack_accounts.csv"
INTO TABLE accounts
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(account_id, account_name, industry, country, @signup_date, referral_source, plan_tier, seats, @is_trial, @churn_flag)
SET
    signup_date = STR_TO_DATE(@signup_date, '%d-%m-%Y'),
    is_trial = CASE WHEN @is_trial = 'TRUE' THEN 1 ELSE 0 END,
    churn_flag = CASE WHEN @churn_flag = 'TRUE' THEN 1 ELSE 0 END;
    
-- --------------------------------------------------------------------------------------------------------------------------

-- 2. subscriptions (end_date has blanks -> NULL

LOAD DATA LOCAL INFILE "C:\Users\shraddha makode\Downloads\archive\ravenstack_subscriptions.csv"
INTO TABLE subscriptions
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(subscription_id, account_id, @start_date, @end_date, plan_tier, seats, mrr_amount, arr_amount,
 is_trial, upgrade_flag, downgrade_flag, churn_flag, billing_frequency, auto_renew_flag)
SET start_date = STR_TO_DATE(@start_date, '%d-%m-%Y'),
    end_date   = NULLIF(STR_TO_DATE(@end_date, '%d-%m-%Y'), '0000-00-00');

-- ------------------------------------------------------------------------------------------------------------

-- 3. feature_usage

LOAD DATA LOCAL INFILE "C:\Users\shraddha makode\Downloads\archive\ravenstack_feature_usage.csv"
INTO TABLE feature_usage
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(usage_id, subscription_id, @usage_date, feature_name, usage_count, usage_duration_secs, error_count, is_beta_feature)
SET usage_date = STR_TO_DATE(@usage_date, '%d-%m-%Y');

-- ---------------------------------------------------------------------------------------------------------------------

-- 4. support_tickets 

LOAD DATA LOCAL INFILE "C:\Users\shraddha makode\Downloads\archive\ravenstack_support_tickets.csv"
INTO TABLE support_tickets
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ticket_id, account_id, @submitted_at, @closed_at, resolution_time_hours, priority,
 first_response_time_minutes, @satisfaction_score, escalation_flag)
SET submitted_at = STR_TO_DATE(@submitted_at, '%d-%m-%Y'),
    closed_at    = STR_TO_DATE(@closed_at, '%d-%m-%Y %H:%i'),
    satisfaction_score = NULLIF(@satisfaction_score, '');

-- -------------------------------------------------------------------------------------------------------------------

-- 5. churn_events 

LOAD DATA LOCAL INFILE "C:\Users\shraddha makode\Downloads\archive\ravenstack_churn_events.csv"
INTO TABLE churn_events
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(churn_event_id, account_id, @churn_date, reason_code, refund_amount_usd,
 preceding_upgrade_flag, preceding_downgrade_flag, is_reactivation, @feedback_text)
SET churn_date = STR_TO_DATE(@churn_date, '%d-%m-%Y'),
    feedback_text = NULLIF(@feedback_text, '');


-- -------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------

-- 1. What is the overall account-level churn rate?
select * from accounts;

with churn_count as (
select count(*) as no_of_churn
from accounts
where churn_flag = "1"
),
no_of_acc as (
select count(*) as no_ofaccount
from accounts
)

select round(no_of_churn / no_ofaccount * 100,1) as Churn_Rate
from churn_count
join no_of_acc;

-- --------------------------------------------------------------------------------------------------

-- 2. What is the subscription-level churn rate? Does it match the account-level rate?

select * from subcription;

with churn_count as (
select count(*) as churn_count
from subcription
where churn_flag = "1"
),
total_subs as (
select count(*) as total_sub
from subcription
)

select round(churn_count / total_sub *100,1) as churn_rate
from churn_count
join total_subs;

-- --------------------------------------------------------------------------------------------------

-- 3. What percentage of churn events are reactivations?
select * from churn_event;

with total_react as (
select count(*) as reactive_count
from churn_event
where is_reactivation = "1"
),
total_chu as (
select count(*) as total_churn
from churn_event
)

select round(reactive_count / total_churn * 100,1) as react_rate
from total_react
join total_chu;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. How many accounts have churned more than once (i.e. churned, came back, churned again)?

select * from churn_event;

select account_id,count(*) as more_churn
from churn_event
group by account_id
having more_churn > 1
order by more_churn desc;

-- --------------------------------------------------------------------------------------------------------------------------------------

-- 5. What's the latest signup date and latest churn date in the data (needed to know which cohorts are too recent to judge)?

select * from accounts;
select * from churn_event;

select max(s.signup_date) as latest_start,max(c.churn_date) as latest_churn
from accounts as s
join churn_event as c
on s.account_id = c.account_id;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- 6. For each signup month, what % of accounts are still retained at 1, 3, and 6 months 
-- (using first-churn-only logic)?

select * from accounts;
select * from churn_event;


with first_churn as (
	select account_id,min(churn_date) as first_churn_date
    from churn_event
    group by account_id
),
cohort_base as (
	select a.account_id,date_format(a.signup_date, '%Y-%m') as cohort_month,
    a.signup_date,
    fc.first_churn_date
from accounts as a
left join first_churn as fc
on a.account_id = fc.account_id
)
select 
	cohort_month,
    count(*) as cohort_size,
    round(sum(case when first_churn_date is null or first_churn_date > date_add(signup_date, interval 1 month)
    then 1 else 0 end) / count(*) * 100, 1) as retained_1mo_pct,
    round(sum(case when first_churn_date is null or first_churn_date > date_add(signup_date, interval 3 month)
    then 1 else 0 end) / count(*) * 100, 1) as retained_3mo_pct,
    round(sum(case when first_churn_date is null or first_churn_date > date_add(signup_date, interval 6 month)
    then 1 else 0 end) / count(*) * 100, 1) as retained_6mo_pct,
    max(case when date_add(signup_date, interval 6 month) <= '2024-12-31' then 'Yes' else 'Too Recent' end) 
    as can_judge_6mo
    from cohort_base
    group by cohort_month
    order by cohort_month;
-- --------------------------------------------------------------------------------------------------------------------------------------------------

-- 7. Which signup cohort has the worst 3-month retention?

select * from churn_event;
select * from accounts;


WITH first_churn AS (
    SELECT account_id, MIN(churn_date) AS first_churn_date
    FROM churn_event
    GROUP BY account_id
),
cohort_base AS (
    SELECT a.account_id,
           DATE_FORMAT(a.signup_date, '%Y-%m') AS cohort_month,
           a.signup_date,
           fc.first_churn_date
    FROM accounts AS a
    LEFT JOIN first_churn AS fc ON a.account_id = fc.account_id
),
cohort_retention AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size,
        ROUND(SUM(CASE WHEN first_churn_date IS NULL
                         OR first_churn_date > DATE_ADD(signup_date, INTERVAL 3 MONTH)
                    THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS retained_3mo_pct,
        MAX(CASE WHEN DATE_ADD(signup_date, INTERVAL 3 MONTH) <= '2024-12-31'
                 THEN 'Yes' ELSE 'Too Recent' END) AS can_judge_3mo
    FROM cohort_base
    GROUP BY cohort_month
)
SELECT *
FROM cohort_retention
WHERE can_judge_3mo = 'Yes'
ORDER BY retained_3mo_pct ASC
LIMIT 1;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. Does retention differ by plan tier when broken into cohorts (e.g. Enterprise vs Basic retention curves)?

select * from subcription;
select * from churn_event;
select * from accounts;

with first_subs as (
	select f.account_id, plan_tier as signup_plan_tier
    from subcription as f
    join (
		select account_id,min(start_date) as first_start
        from subcription
        group by account_id
        ) as e
        on f.account_id = e.account_id
        and f.start_date = e.first_signup
),
first_churn as (
	select 
    account_id,
	min(churn_date) as first_churn_date
	from churn_event
	group by account_id
),

chort_base as (
select a.account_id,
date_format(a.signup_date, '%Y-%m') as chort_month,
a.signup_date,
fs.signup_plan_tier,
fc.first_churn_date
from accounts as a
left join first_subs as fs
on a.account_id = fs.account_id
left join first_churn as fc
on a.account_id = fc.account_id
)

select 
signup_plan_tier,
count(*) as n,
round(sum(case when first_churn_date is null
		or first_churn_date > date_add(signup_date, interval 1 month)
	then 1 else 0 end) / count(*) * 100, 1) as retained_1mo_pct,
rount(sum(case when first_churn_date is null
		or first_churn_date > date_add(signup_date, interval 3 month)
	then 1 else 0 end) / count(*) * 100, 1) as retained_3mo_pct,
rount(sum(case when first_churn_date is null
		or first_churn_date > date_add(signup_date, interval 6 month)
	then 1 else 0 end) / count(*) * 100, 1) as retained_6mo_pct
    
from chort_base
where date_add(signup_date, interval 6 month) <= '2024-12-31'
group by signup_plan_tier
order  by retained_6mo_pct desc;

-- ----------------------------------------------------------------------------------------------------------------------------------------------

-- 9.	What is the total current active MRR (from subscriptions with no end_date)?

select * from subcription;

select sum(mrr_amount) as total_monthly_revenue
from subcription
where end_date is null;

-- -----------------------------------------------------------------------------------------------------------------------------------------------

-- 10.	What is the total MRR lost from churned subscriptions?

select * from subcription;

with mrr as (
	select sum(mrr_amount) as monthly_rev
    from subcription
    where end_date is null
),
cmrr as (
	select sum(mrr_amount) as churn_amount
    from subcription
    where churn_flag = 1
)
select m.monthly_rev,c.churn_amount
from mrr as m
join cmrr as c;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 11.	What % of total MRR does the top 10% of accounts (by MRR) represent? (revenue concentration)

select * from subcription;

with account_mrr as (
select account_id,sum(mrr_amount) as total_mrr
from subcription
where end_date is null
group by account_id
),
ranked as (
	select account_id,total_mrr,
    ntile(10) over (order by total_mrr desc) as top_10
    from account_mrr
)
select 
	round(sum(case when top_10 = 1 then total_mrr else 0 end) / sum(total_mrr) * 100,1) as top_10_share
    from ranked;
    
-- ------------------------------------------------------------------------------------------------------------------------------------

-- 12.	How does MRR lost to churn trend month over month?

select * from subcription;

select date_format(end_date, '%Y-%m') as churn_month,sum(mrr_amount) as mrr_lost
from subcription
where churn_flag = 1
group by date_format(end_date, '%Y-%m')
order by churn_month;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------

-- 13.	What is the total refund amount paid out due to churn, and how does 
--      it compare to MRR lost?

select * from churn_event;
select * from subcription;

with total_mrr_lo as (
select sum(mrr_amount) as total_mrr_lost
from subcription
where churn_flag = 1
),
total_refund as (
select sum(refund_amount_usd) as total_refund
from churn_event
)

select t.total_mrr_lost,r.total_refund,
round(r.total_refund / t.total_mrr_lost * 100,1) as mrr_lost_percentage
from total_mrr_lo as t
join total_refund as r;

-- ----------------------------------------------------------------------------------------------------------------------------------------

-- 14.	What is the churn rate broken down by industry?
select * from accounts;
select * from churn_event;

select industry,count(*) as total_accounts,
sum(case when churn_flag = 1 then 1 else 0 end) as churn_accounts,
round(sum(case when churn_flag = 1 then 1 else 0 end) / count(*) * 100,1) as churn_rate
from accounts
group by industry
order by churn_rate desc;

-- -------------------------------------------------------------------------------------------------------------------------------------------------

-- 15.	What is the churn rate broken down by referral source?
select * from accounts;

select referral_source,
count(*) as total_accounts,
sum(case when churn_flag = 1 then 1 else 0 end) as churn_accounts,
round(sum(case when churn_flag = 1 then 1 else 0 end) / count(*) * 100,1) as churn_rate
from accounts
group by referral_source
order by churn_rate desc;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 16.	What is the churn rate broken down by country?
select * from accounts;

select country,
count(*) as total_accounts,
sum(case when churn_flag = 1 then 1 else 0 end) as total_churn,
round(sum(case when churn_flag = 1 then 1 else 0 end) / count(*) * 100,1) as churn_rate
from accounts
group by country
order by churn_rate desc;

-- -------------------------------------------------------------------------------------------------------------------------------------------

-- 17.	What is the churn rate broken down by plan tier?
select * from subcription;

select plan_tier,
count(*) as total_accounts,
sum(case when churn_flag = 1 then 1 else 0 end) as total_churn,
round(sum(case when churn_flag = 1 then 1 else 0 end) / count(*) * 100,1) as churn_rate
from accounts
group by plan_tier
order by churn_rate;

-- ------------------------------------------------------------------------------------------------------------------------------------

-- 18	Is churn rate higher for trial accounts than non-trial?
select * from accounts;

select is_trial,count(*) as total_accounts,
sum(case when churn_flag = 1 then 1 else 0 end) as total_churn,
round(sum(case when churn_flag = 1 then 0 else 0 end) / count(*) * 100,1) as churn_rate
from accounts
group by is_trial;

-- ------------------------------------------------------------------------------------------------------------------------------------

-- 19.	Within the highest-churn industry (DevTools), is churn concentrated in a 
-- specific country or referral source, or spread evenly?
select * from accounts;

select country,count(*) as total_accounts,
sum(case when churn_flag = 1 then 1 else 0 end) as total_churn_accounts,
round(sum(case when churn_flag = 1 then 1 else 0 end) / count(*) * 100,1) as churn_rate
from accounts
where industry = "DevTools"
group by country
order by churn_rate desc;

select referral_source,count(*) as total_accounts,
sum(case when churn_flag = 1 then 1 else 0 end) as total_churn,
round(sum(case when churn_flag = 1 then 1 else 0 end) / count(*) * 100,1) as churn_rate
from accounts
where industry = "DevTools"
group by referral_source
order by churn_rate desc;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 20.	What is the distribution of reason_code across all churn events?
select * from churn_event;

select reason_code,count(*) as total_churn,
round(count(*) / (select count(*) from churn_event) * 100,1) as churn_rate
from churn_event
group by reason_code
order by total_churn desc;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------

-- 21.	Does the most common churn reason differ by industry?
select * from accounts;
select * from churn_event;

select a.industry,c.reason_code,count(*) as no_of_events,
round(count(*) / sum(count(*)) over (partition by a.industry) * 100,1) as share
from accounts as a
join churn_event as c
on a.account_id = c.account_id
group by a.industry,c.reason_code
order by no_of_events desc;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------

-- 22.	Does the most common churn reason differ by plan tier?
select * from churn_event;
select * from accounts;

select a.plan_tier,c.reason_code,count(*) as no_of_churn,
round(count(*) / sum(count(*)) over (partition by a.plan_tier) * 100,1) as share
from accounts as a
join churn_event as c
on a.account_id = c.account_id
group by a.plan_tier,c.reason_code
order by no_of_churn desc;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 23.	What % of churn events were preceded by a downgrade?
select * from churn_event;

select round(sum(case when preceding_downgrade_flag = 1 then 1 else 0 end) / count(*) * 100,1) as downgrade_rate
from churn_event;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------

-- 24.	Do accounts that downgraded before churning cluster around a particular 
-- reason_code (e.g. "budget" or "pricing")?

select * from churn_event;

select reason_code,count(*) as total_events,
round(sum(case when preceding_downgrade_flag = 1 then 1 else 0 end) / count(*) * 100,1) as downgrade_rate
from churn_event
group by reason_code
order by downgrade_rate desc;

-- --------------------------------------------------------------------------------------------------------------------------------------------------

-- 25.	What is each subscription's most recent usage date, and how many days before 
-- churn (or before today, for active accounts) was that?

select * from subcription;
select * from feature_use;

with last_usage as (
select subscription_id,max(usage_date) as last_usage_date
from feature_use
group by subscription_id
)
select s.subscription_id,s.churn_flag,s.end_date,e.last_usage_date,
COALESCE(s.end_date, '2024-12-31') AS reference_date,
DATEDIFF(COALESCE(s.end_date, '2024-12-31'), e.last_usage_date) AS days_since_last_usage
FROM subcription AS s
left join last_usage as e
on s.subscription_id = e.subscription_id;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 26. Do churned accounts show a longer gap since their last usage event, compared to retained accounts?

WITH last_usage AS (
    SELECT subscription_id, MAX(usage_date) AS last_usage_date
    FROM feature_use
    GROUP BY subscription_id
),
gaps AS (
    SELECT s.subscription_id,
           s.churn_flag,
           DATEDIFF(COALESCE(s.end_date, '2024-12-31'), lu.last_usage_date) AS days_since_last_usage
    FROM subcription AS s
    LEFT JOIN last_usage AS lu ON s.subscription_id = lu.subscription_id
)
SELECT churn_flag,
       COUNT(*) AS subs,
       COUNT(days_since_last_usage) AS subs_with_gap,
       ROUND(AVG(days_since_last_usage), 1) AS avg_gap_days,
       MIN(days_since_last_usage) AS min_gap,
       MAX(days_since_last_usage) AS max_gap
FROM gaps
WHERE days_since_last_usage >= 0
GROUP BY churn_flag;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 27	Which feature_name has the highest average usage among retained vs churned accounts?
select * from feature_use;
select * from subcription;

select feature_name,
sum(case when s.churn_flag = 1 then 1 else 0 end) as churned_rows,
sum(case when s.churn_flag = 0 then 1 else 0 end) as retained_rows,
round(avg(case when s.churn_flag = 1 then f.usage_count end),2) as avg_churned,
round(avg(case when s.churn_flag = 1 then f.usage_count end),2) as avg_retained,
round(avg(case when s.churn_flag = 1 then f.usage_count end) - avg(case when s.churn_flag = 0 then f.usage_count end),2) as diff
from feature_use as f
join subcription as s
on s.subscription_id = f.subscription_id
group by f.feature_name
order by diff desc;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 28	Is there a relationship between error_count and churn?
select * from feature_use;
select * from subcription;

with sub_error as (
	select subscription_id,
    sum(error_count) as total_errors,
    count(*) as usage_event
    from feature_use
    group by subscription_id
)
select s.churn_flag,
count(*) as subscriptions,
round(avg(se.total_errors),2) as avg_per_subs,
round(sum(se.total_errors) / sum(se.usage_event), 3) as errors_per_usage_event
from subcription as s
join sub_error as se
on s.subscription_id = se.subscription_id
group by s.churn_flag;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 29.	Does ticket volume per account increase in the 30-60 days leading up to a churn event, compared to accounts that didn't churn?
select * from churn_event;
select * from accounts;
select * from support_ticket;

WITH first_churn AS (
    SELECT account_id, MIN(churn_date) AS first_churn_date
    FROM churn_event
    GROUP BY account_id
),
account_ref AS (
    SELECT a.account_id,
	CASE WHEN fc.first_churn_date IS NULL THEN 'Not churned' ELSE 'Churned' END AS churn_group,
	COALESCE(fc.first_churn_date, '2024-12-31') AS reference_date
    FROM accounts AS a
    LEFT JOIN first_churn AS fc ON a.account_id = fc.account_id
),
account_tickets AS (
    SELECT ar.account_id, ar.churn_group,
	SUM(CASE WHEN DATEDIFF(ar.reference_date, st.submitted_at) BETWEEN 0 AND 30  THEN 1 ELSE 0 END) AS tickets_0_30,
	SUM(CASE WHEN DATEDIFF(ar.reference_date, st.submitted_at) BETWEEN 31 AND 60 THEN 1 ELSE 0 END) AS tickets_31_60
    FROM account_ref AS ar
    LEFT JOIN support_ticket AS st ON ar.account_id = st.account_id
    GROUP BY ar.account_id, ar.churn_group
)
SELECT churn_group,
       COUNT(*) AS accounts,
       ROUND(AVG(tickets_0_30), 3)  AS avg_tickets_0_30,
       ROUND(AVG(tickets_31_60), 3) AS avg_tickets_31_60
FROM account_tickets
GROUP BY churn_group;

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 30. Is escalation rate or satisfaction score noticeably different in an account’s last ticket before churning, versus their earlier tickets?

select * from churn_event;


WITH first_churn AS (
    SELECT account_id, MIN(churn_date) AS first_churn_date
    FROM churn_event
    GROUP BY account_id
),
ranked AS (
    SELECT st.account_id, st.escalation_flag, st.satisfaction_score,
           ROW_NUMBER() OVER (PARTITION BY st.account_id
                              ORDER BY st.submitted_at DESC, st.ticket_id DESC) AS rn,
           COUNT(*) OVER (PARTITION BY st.account_id) AS tickets_before_churn
    FROM support_ticket AS st
    JOIN first_churn AS fc ON st.account_id = fc.account_id
    WHERE st.submitted_at <= fc.first_churn_date
)
SELECT CASE WHEN rn = 1 THEN 'Last ticket' ELSE 'Earlier tickets' END AS ticket_position,
       COUNT(*) AS tickets,
       SUM(escalation_flag) AS escalated,
       ROUND(AVG(escalation_flag) * 100, 1) AS escalation_rate,
       COUNT(satisfaction_score) AS scored_tickets,
       ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction
FROM ranked
WHERE tickets_before_churn >= 2
GROUP BY ticket_position;


   SELECT end_date, COUNT(*) AS subs_ended
   FROM subcription
   WHERE churn_flag = 1 AND end_date >= '2024-12-01'
   GROUP BY end_date
   ORDER BY end_date;
   
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------