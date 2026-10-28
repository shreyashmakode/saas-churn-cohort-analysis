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