use paper_data;
-- Transaction Anomalies: Write a query to identify transactions with values far outside the normal range for each buyer/seller pair.
WITH TransactionStats AS (
    SELECT
        buyer_id,
        seller_id,
        AVG(transaction_amount) AS avg_transaction_amount,
        STDDEV(transaction_amount) AS std_transaction_amount
    FROM
        cleaned_merged_data
    GROUP BY
        buyer_id, seller_id
),
AnomalousTransactions AS (
    SELECT
        c.*,
        ts.avg_transaction_amount,
        ts.std_transaction_amount,
        CASE
            WHEN ABS(c.transaction_amount - ts.avg_transaction_amount) > 3 * ts.std_transaction_amount
            THEN 1
            ELSE 0
        END AS is_anomalous
    from cleaned_merged_data c
    INNER join TransactionStats ts
    ON c.buyer_id = ts.buyer_id AND c.seller_id = ts.seller_id
)
SELECT * from AnomalousTransactions
where is_anomalous = 1;

-- Buyer-Seller Relationship Analysis: Find buyer-seller pairs with unusually high transaction frequencies or amounts, suggesting possible collusion.
WITH BuyerSellerStats AS (
    SELECT
        buyer_id,
        seller_id,
        COUNT(*) AS total_transaction_count,
        SUM(transaction_amount) AS total_transaction_amount,
        AVG(transaction_amount) AS avg_transaction_amount_per_pair
    FROM
        cleaned_merged_data
    GROUP BY
        buyer_id, seller_id
),
GlobalStats AS (
    SELECT
        AVG(total_transaction_count) AS avg_transaction_count,
        STDDEV(total_transaction_count) AS std_transaction_count,
        AVG(total_transaction_amount) AS avg_transaction_amount,
        STDDEV(total_transaction_amount) AS std_transaction_amount
    FROM
        BuyerSellerStats
),
FlaggedPairs AS (
    SELECT
        bs.*,
        gs.avg_transaction_count,
        gs.std_transaction_count,
        gs.avg_transaction_amount,
        gs.std_transaction_amount,
        CASE
            WHEN bs.total_transaction_count > gs.avg_transaction_count + 3 * gs.std_transaction_count
              OR bs.total_transaction_amount > gs.avg_transaction_amount + 3 * gs.std_transaction_amount
            THEN 1
            ELSE 0
        END AS is_potential_collusion
    FROM
        BuyerSellerStats bs
    CROSS JOIN
        GlobalStats gs
)
select * from FlaggedPairs
where is_potential_collusion = 1;

-- Promotion Misuse Detection: Detect cases where users excessively used promotions or discounts within a short period of time.
WITH PromotionUsage AS (
    SELECT
        buyer_id,
        promotion_code,
        COUNT(*) AS promo_usage_count,
        SUM(transaction_promo_cashback_amount) AS total_promo_cashback,
        DATE(transaction_created_datetime) AS usage_date
    FROM
        cleaned_merged_data
    WHERE
        promotion_code IS NOT NULL
    GROUP BY
        buyer_id, promotion_code, DATE(transaction_created_datetime)
),
GlobalPromoStats AS (
    SELECT
        AVG(promo_usage_count) AS avg_promo_usage,
        STDDEV(promo_usage_count) AS std_promo_usage,
        AVG(total_promo_cashback) AS avg_promo_cashback,
        STDDEV(total_promo_cashback) AS std_promo_cashback
    FROM
        PromotionUsage
),
FlaggedPromotionUsage AS (
    SELECT
        pu.*,
        gs.avg_promo_usage,
        gs.std_promo_usage,
        gs.avg_promo_cashback,
        gs.std_promo_cashback,
        CASE
            WHEN pu.promo_usage_count > gs.avg_promo_usage + 3 * gs.std_promo_usage
              OR pu.total_promo_cashback > gs.avg_promo_cashback + 3 * gs.std_promo_cashback
            THEN 1
            ELSE 0
        END AS is_potential_misuse
    FROM
        PromotionUsage pu
    CROSS JOIN
        GlobalPromoStats gs
)
SELECT
    *
FROM
    FlaggedPromotionUsage
WHERE
    is_potential_misuse = 1;
   
--  Suspicious Timing: Identify transactions occurring at irregular hours or intervals (e.g., many transactions in a short time span). 
WITH TransactionTimeStats AS (
    SELECT
        buyer_id,
        seller_id,
        DATE(transaction_created_datetime) AS transaction_date,
        HOUR(transaction_created_datetime) AS transaction_hour,
        COUNT(*) AS transaction_count_per_hour
    FROM
        cleaned_merged_data
    GROUP BY
        buyer_id, seller_id, DATE(transaction_created_datetime), HOUR(transaction_created_datetime)
),
GlobalTimeStats AS (
    SELECT
        AVG(transaction_count_per_hour) AS avg_transaction_count,
        STDDEV(transaction_count_per_hour) AS std_transaction_count
    FROM
        TransactionTimeStats
),
FlaggedTransactions AS (
    SELECT
        tts.*,
        gts.avg_transaction_count,
        gts.std_transaction_count,
        CASE
            WHEN tts.transaction_count_per_hour > gts.avg_transaction_count + 3 * gts.std_transaction_count
                 OR tts.transaction_hour IN (0, 1, 2, 3, 4) -- Transactions during unusual hours
            THEN 1
            ELSE 0
        END AS is_suspicious
    FROM
        TransactionTimeStats tts
    CROSS JOIN
        GlobalTimeStats gts
)
SELECT
    c.*,
    ft.is_suspicious
FROM
    cleaned_merged_data c
INNER JOIN
    FlaggedTransactions ft
ON
    c.buyer_id = ft.buyer_id
    AND c.seller_id = ft.seller_id
    AND DATE(c.transaction_created_datetime) = ft.transaction_date
    AND HOUR(c.transaction_created_datetime) = ft.transaction_hour
WHERE
    ft.is_suspicious = 1;
   
-- Flagged User Connections: Write queries to detect users with repeated fraud flags or those blacklisted, and track their interactions with other users.
   WITH FlaggedUsers AS (
    SELECT
        buyer_id,
        COUNT(CASE WHEN user_fraud_flag = 1 THEN 1 END) AS fraud_flag_count,
        MAX(CASE WHEN blacklist_account_flag = 1 THEN 1 ELSE 0 END) AS is_blacklisted
    FROM
        cleaned_merged_data
    GROUP BY
        buyer_id
    HAVING
        fraud_flag_count > 1 OR is_blacklisted = 1
),
FlaggedInteractions AS (
    SELECT
        c.buyer_id AS flagged_buyer_id,
        c.seller_id AS interacting_seller_id,
        COUNT(*) AS transaction_count,
        SUM(transaction_amount) AS total_transaction_amount,
        MAX(user_fraud_flag) AS seller_fraud_flag,
        MAX(blacklist_account_flag) AS seller_blacklisted_flag
    FROM
        cleaned_merged_data c
    INNER JOIN
        FlaggedUsers f
    ON
        c.buyer_id = f.buyer_id
    GROUP BY
        c.buyer_id, c.seller_id
)
SELECT
    *
FROM
    FlaggedInteractions
WHERE
    seller_fraud_flag = 1 OR seller_blacklisted_flag = 1 OR transaction_count > 5;
   
-- 2. SQL Joins for User-Company Fraud Insights:
-- Join transactions with company and user flag data to investigate if certain companies are more prone to fraud based on their KYC/KYB status or fraud flag history.
  SELECT 
    company_id,
    company_kyc_status_name,
    company_kyb_status_name,
    company_type_group,
    user_fraud_flag,
    testing_account_flag,
    blacklist_account_flag,
    COUNT(transaction_amount) AS total_transactions,
    SUM(transaction_amount) AS total_transaction_amount,
    AVG(transaction_amount) AS avg_transaction_amount,
    SUM(CASE WHEN user_fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_transactions
FROM 
    cleaned_merged_data
GROUP BY 
    company_id, company_kyc_status_name, company_kyb_status_name, company_type_group, 
    user_fraud_flag, testing_account_flag, blacklist_account_flag
ORDER BY 
    fraud_transactions DESC;
    

-- Top Fraudulent Buyer-Seller Pairs: View summarizing the most suspicious buyer-seller relationships, including transaction frequency and amounts.
CREATE VIEW TopFraudulentBuyerSellerPairs AS
WITH BuyerSellerSummary AS (
    SELECT
        buyer_id,
        seller_id,
        COUNT(*) AS transaction_count,
        SUM(transaction_amount) AS total_transaction_amount,
        AVG(transaction_amount) AS avg_transaction_amount,
        MAX(transaction_amount) AS max_transaction_amount,
        MAX(frequency_fraud) AS max_frequency_fraud,
        MAX(transaction_count_fraud) AS max_transaction_count_fraud
    FROM
        cleaned_merged_data
    GROUP BY
        buyer_id, seller_id
),
SuspiciousPairs AS (
    SELECT
        *,
        CASE
            WHEN transaction_count > 10 AND total_transaction_amount > 100000 THEN 'High Suspicion'
            WHEN transaction_count > 5 AND total_transaction_amount > 50000 THEN 'Moderate Suspicion'
            ELSE 'Low Suspicion'
        END AS suspicion_level
    FROM
        BuyerSellerSummary
)
SELECT
    buyer_id,
    seller_id,
    transaction_count,
    total_transaction_amount,
    avg_transaction_amount,
    max_transaction_amount,
    max_frequency_fraud,
    max_transaction_count_fraud,
    suspicion_level
FROM
    SuspiciousPairs
WHERE
    suspicion_level IN ('High Suspicion', 'Moderate Suspicion')
ORDER BY
    suspicion_level DESC, transaction_count DESC, total_transaction_amount DESC;
    
select * from TopFraudulentBuyerSellerPairs;

-- Flagged Users and Their Transactions: A detailed view of transactions involving flagged or blacklisted users.
CREATE VIEW flagged_users_transactions AS
SELECT 
    company_id,
    company_kyc_status_name,
    company_kyb_status_name,
    company_type_group,
    company_phone_verified_flag,
    company_email_verified_flag,
    user_fraud_flag,
    testing_account_flag,
    blacklist_account_flag,
    package_active_name,
    company_registered_datetime,
    dpt_id,
    dpt_promotion_id,
    buyer_id,
    seller_id,
    transaction_amount,
    payment_method_name,
    payment_provider_name,
    transaction_created_datetime,
    transaction_updated_datetime,
    time_diff,
    frequency_fraud,
    daily_transaction_count,
    transaction_count_fraud,
    total_fee_amount,
    document_type_name,
    promotion_code,
    promotion_name,
    transaction_promo_cashback_amount,
    promotion_fraud_label
FROM 
    cleaned_merged_data
WHERE 
    user_fraud_flag = 1 OR blacklist_account_flag = 1;

select * from flagged_users_transactions;








