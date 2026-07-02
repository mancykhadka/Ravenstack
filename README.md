# Ravenstack
Customer Churn Prediction &amp; Retention Optimization (SaaS)

# Customer Churn Prediction & Retention Optimization (SaaS)

An end-to-end churn prediction pipeline for a B2B SaaS company, from five raw relational tables to a deployed risk segmentation framework with prescribed retention actions, built for a graduate Business Analytics capstone.

## Overview

RavenStack, a B2B SaaS collaboration platform with 500 accounts across five industry verticals, loses 22% of its customer base annually, putting roughly $249K in monthly recurring revenue at risk every year, with no structured way to identify at-risk accounts before they cancel. This project builds that early-warning system through a three-phase pipeline: descriptive analytics to diagnose churn patterns, a predictive logistic regression model to score every account's churn risk, and a prescriptive risk segmentation framework that translates those scores into specific, prioritized retention actions.

**Dataset:** 5 relational tables, 33,100 total records (accounts, subscriptions, feature usage, support tickets, churn events), sourced from Kaggle (MIT license)

## Tech Stack

- **Python** — pandas, scikit-learn (Pipeline, ColumnTransformer, LogisticRegression)
- **Google Colab** — reproducible notebook environment
- **Matplotlib / Seaborn** — visualization

## The Process

**1. Data integration** — Merged 5 source tables (500 to 25,000 rows each) into a single 500-row, 27-column account-level master table via a sequence of left joins anchored to the accounts table, aggregating usage, subscription, and support data to account level first since each contained multiple rows per account.

**2. Descriptive analytics (Phase A)** — Disaggregated the 22% portfolio churn rate across industry, acquisition channel, plan tier, tenure, and geography to surface the "what" before modeling. Found DevTools churns at 31% (highest), event-acquired customers churn at 30.2% vs. 14.6% for partner referrals, and two notable **null findings**: plan tier and customer tenure have virtually no effect on churn, challenging common retention assumptions.

**3. Predictive modeling (Phase B)** — Built a logistic regression model (scikit-learn Pipeline + ColumnTransformer, balanced class weighting, 70/30 stratified split) chosen deliberately over higher-complexity ensemble methods for interpretability at this sample size. Achieved ROC-AUC of 0.589 and recall of 57.6%, correctly flagging 19 of 33 churning accounts in the validation set before exit.

**4. Coefficient analysis** — Identified the strongest churn risk and protective factors. The most analytically interesting finding: `avg_usage_count` (+0.43, risk) and `avg_session_secs` (-0.55, protective) point in opposite directions, high action counts with short sessions likely signal navigational frustration, while long session duration signals productive use.

**5. Prescriptive segmentation (Phase C)** — Scored all 500 accounts and classified them into Low/Medium/High risk tiers with specific prescribed actions per tier. Observed churn rates rose monotonically from 10.7% (Low) to 39.6% (High), confirming the model's scores reflect genuine differential risk. The Medium Risk tier, 381 accounts holding $864K MRR (77% of the portfolio), emerged as the highest-priority target since it combines meaningful risk with the largest revenue concentration.

## Key Findings

- **DevTools vertical** churns at 31%, nine points above average, independent of all other features (model coefficient +0.44)
- **Session depth beats session frequency** as a retention signal, an unusual and actionable finding that runs counter to common engagement-metric assumptions
- **Plan tier and tenure are non-predictive** (null findings), suggesting retention resources are often misallocated toward assumed-safe accounts
- **Annual billing is a structural retention lever** independent of account size or industry (coefficient -0.32)
- Model identifies **$43K/month in recoverable MRR** through timely intervention on flagged accounts

## Strategic Recommendations (Model-Derived)

1. Convert month-to-month Medium Risk accounts to annual contracts
2. Build a dedicated customer success function for DevTools accounts
3. Implement automated 48-hour outreach protocols triggered by plan downgrades
4. Shift engagement measurement from session frequency to session depth

## Author
Mancy Khadka
