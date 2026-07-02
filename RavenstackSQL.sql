-- Phase 1

DROP database if exists ravenstack;
CREATE DATABASE ravenstack;
USE ravenstack;

CREATE TABLE accounts (
    account_id       VARCHAR(20),
    account_name     VARCHAR(100),
    industry         VARCHAR(50),
    country          VARCHAR(10),
    signup_date      VARCHAR(20),
    referral_source  VARCHAR(20),
    plan_tier        VARCHAR(20),
    seats            VARCHAR(10),
    is_trial         VARCHAR(10),
    churn_flag       VARCHAR(10)
);

CREATE TABLE subscriptions (
    subscription_id    VARCHAR(20),
    account_id         VARCHAR(20),
    start_date         VARCHAR(20),
    end_date           VARCHAR(20),
    plan_tier          VARCHAR(20),
    seats              VARCHAR(10),
    mrr_amount         VARCHAR(20),
    arr_amount         VARCHAR(20),
    is_trial           VARCHAR(10),
    upgrade_flag       VARCHAR(10),
    downgrade_flag     VARCHAR(10),
    churn_flag         VARCHAR(10),
    billing_frequency  VARCHAR(20),
    auto_renew_flag    VARCHAR(10)
);

CREATE TABLE feature_usage (
    usage_id              VARCHAR(20),
    subscription_id       VARCHAR(20),
    usage_date            VARCHAR(20),
    feature_name          VARCHAR(50),
    usage_count           VARCHAR(10),
    usage_duration_secs   VARCHAR(10),
    error_count           VARCHAR(10),
    is_beta_feature       VARCHAR(10)
);

CREATE TABLE support_tickets (
    ticket_id                     VARCHAR(20),
    account_id                    VARCHAR(20),
    submitted_at                  VARCHAR(30),
    closed_at                     VARCHAR(30),
    resolution_time_hours         VARCHAR(20),
    priority                      VARCHAR(20),
    first_response_time_minutes   VARCHAR(10),
    satisfaction_score            VARCHAR(10),
    escalation_flag               VARCHAR(10)
);

CREATE TABLE churn_events (
    churn_event_id             VARCHAR(20),
    account_id                 VARCHAR(20),
    churn_date                 VARCHAR(20),
    reason_code                VARCHAR(30),
    refund_amount_usd          VARCHAR(20),
    preceding_upgrade_flag     VARCHAR(10),
    preceding_downgrade_flag   VARCHAR(10),
    is_reactivation            VARCHAR(10),
    feedback_text              TEXT
);

SET SQL_SAFE_UPDATES = 0;

-- accounts
UPDATE accounts SET is_trial = CASE WHEN is_trial='True' THEN 1 WHEN is_trial='False' THEN 0 END;
UPDATE accounts SET churn_flag = CASE WHEN churn_flag='True' THEN 1 WHEN churn_flag='False' THEN 0 END;

-- subscriptions
UPDATE subscriptions SET end_date = NULL WHERE end_date IN ('', 'NULL');
UPDATE subscriptions SET is_trial = CASE WHEN is_trial='True' THEN 1 WHEN is_trial='False' THEN 0 END;
UPDATE subscriptions SET upgrade_flag = CASE WHEN upgrade_flag='True' THEN 1 WHEN upgrade_flag='False' THEN 0 END;
UPDATE subscriptions SET downgrade_flag = CASE WHEN downgrade_flag='True' THEN 1 WHEN downgrade_flag='False' THEN 0 END;
UPDATE subscriptions SET churn_flag = CASE WHEN churn_flag='True' THEN 1 WHEN churn_flag='False' THEN 0 END;
UPDATE subscriptions SET auto_renew_flag = CASE WHEN auto_renew_flag='True' THEN 1 WHEN auto_renew_flag='False' THEN 0 END;

-- feature_usage
UPDATE feature_usage SET is_beta_feature = CASE WHEN is_beta_feature='True' THEN 1 WHEN is_beta_feature='False' THEN 0 END;

-- support_tickets
UPDATE support_tickets SET satisfaction_score = NULL WHERE satisfaction_score = '';
UPDATE support_tickets SET closed_at = NULL WHERE closed_at = '';
UPDATE support_tickets SET escalation_flag = CASE WHEN escalation_flag='True' THEN 1 WHEN escalation_flag='False' THEN 0 END;

-- churn_events
UPDATE churn_events SET preceding_upgrade_flag = CASE WHEN preceding_upgrade_flag='True' THEN 1 WHEN preceding_upgrade_flag='False' THEN 0 END;
UPDATE churn_events SET preceding_downgrade_flag = CASE WHEN preceding_downgrade_flag='True' THEN 1 WHEN preceding_downgrade_flag='False' THEN 0 END;
UPDATE churn_events SET is_reactivation = CASE WHEN is_reactivation='True' THEN 1 WHEN is_reactivation='False' THEN 0 END;

SET SQL_SAFE_UPDATES = 1;

-- Convert columns to proper data types
-- --------------------------------------------
ALTER TABLE accounts
    MODIFY signup_date DATE,
    MODIFY seats INT,
    MODIFY is_trial BOOLEAN,
    MODIFY churn_flag BOOLEAN;

ALTER TABLE subscriptions
    MODIFY start_date DATE,
    MODIFY end_date DATE,
    MODIFY seats INT,
    MODIFY mrr_amount DECIMAL(10,2),
    MODIFY arr_amount DECIMAL(10,2),
    MODIFY is_trial BOOLEAN,
    MODIFY upgrade_flag BOOLEAN,
    MODIFY downgrade_flag BOOLEAN,
    MODIFY churn_flag BOOLEAN,
    MODIFY auto_renew_flag BOOLEAN;

ALTER TABLE feature_usage
    MODIFY usage_date DATE,
    MODIFY usage_count INT,
    MODIFY usage_duration_secs INT,
    MODIFY error_count INT,
    MODIFY is_beta_feature BOOLEAN;

ALTER TABLE support_tickets
    MODIFY submitted_at DATETIME,
    MODIFY closed_at DATETIME,
    MODIFY resolution_time_hours FLOAT,
    MODIFY first_response_time_minutes INT,
    MODIFY satisfaction_score INT,
    MODIFY escalation_flag BOOLEAN;

ALTER TABLE churn_events
    MODIFY churn_date DATE,
    MODIFY refund_amount_usd DECIMAL(10,2),
    MODIFY preceding_upgrade_flag BOOLEAN,
    MODIFY preceding_downgrade_flag BOOLEAN,
    MODIFY is_reactivation BOOLEAN;

SELECT 'accounts' AS table_name, COUNT(*) AS row_count FROM accounts
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL SELECT 'feature_usage', COUNT(*) FROM feature_usage
UNION ALL SELECT 'support_tickets', COUNT(*) FROM support_tickets
UNION ALL SELECT 'churn_events', COUNT(*) FROM churn_events;

-- Phase B — Master Table Build

CREATE TABLE account_master AS
WITH usage_agg AS (
    -- feature_usage links to accounts THROUGH subscriptions, so join first
    SELECT
        s.account_id,
        AVG(f.usage_duration_secs) AS avg_session_secs,
        AVG(f.usage_count)         AS avg_usage_count,
        SUM(f.error_count)         AS total_errors,
        COUNT(f.usage_id)          AS total_usage_events
    FROM subscriptions s
    LEFT JOIN feature_usage f ON s.subscription_id = f.subscription_id
    GROUP BY s.account_id
),
subs_agg AS (
    SELECT
        account_id,
        AVG(mrr_amount) AS avg_mrr,
        AVG(arr_amount) AS avg_arr,
        COUNT(subscription_id) AS num_subs,
        AVG(seats) AS avg_seats,
        MAX(CASE WHEN billing_frequency = 'annual' THEN 1 ELSE 0 END) AS has_annual,
        MAX(upgrade_flag)   AS upgrade_flag,
        MAX(downgrade_flag) AS downgrade_flag
    FROM subscriptions
    GROUP BY account_id
),
tickets_agg AS (
    SELECT
        account_id,
        COUNT(ticket_id) AS num_tickets,
        AVG(resolution_time_hours) AS avg_resolution_hrs,
        AVG(satisfaction_score) AS avg_satisfaction,
        AVG(escalation_flag) AS escalation_rate
    FROM support_tickets
    GROUP BY account_id
),
churn_agg AS (
    -- flag any account that had a downgrade in the 90 days before a churn event
    SELECT
        account_id,
        MAX(preceding_downgrade_flag) AS preceding_downgrade
    FROM churn_events
    GROUP BY account_id
)
SELECT
    a.account_id,
    a.industry,
    a.country,
    a.referral_source,
    a.plan_tier,
    a.seats,
    a.is_trial,
    DATEDIFF('2025-01-01', a.signup_date) AS tenure_days,
    ua.avg_session_secs,
    ua.avg_usage_count,
    ua.total_errors,
    ua.total_usage_events,
    sa.avg_mrr,
    sa.avg_arr,
    sa.num_subs,
    sa.avg_seats,
    sa.has_annual,
    sa.upgrade_flag,
    sa.downgrade_flag,
    COALESCE(ta.num_tickets, 0) AS num_tickets,
    ta.avg_resolution_hrs,
    ta.avg_satisfaction,
    COALESCE(ta.escalation_rate, 0) AS escalation_rate,
    COALESCE(ca.preceding_downgrade, 0) AS preceding_downgrade,
    a.churn_flag
FROM accounts a
LEFT JOIN usage_agg   ua ON a.account_id = ua.account_id
LEFT JOIN subs_agg    sa ON a.account_id = sa.account_id
LEFT JOIN tickets_agg ta ON a.account_id = ta.account_id
LEFT JOIN churn_agg   ca ON a.account_id = ca.account_id;

SELECT
    COUNT(*) AS total_accounts,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM account_master;

-- Quick insight check: avg session duration, churned vs retained
SELECT
    churn_flag,
    COUNT(*) AS accounts,
    ROUND(AVG(avg_session_secs), 0) AS avg_session_secs,
    ROUND(AVG(avg_usage_count), 1) AS avg_usage_count
FROM account_master
GROUP BY churn_flag;