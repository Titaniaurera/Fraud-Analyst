# Fraud-Analyst🚀🔍

## Overview 📌

This project focuses on data preparation and feature engineering for fraud detection in a digital payment system. The dataset consists of multiple CSV files that are cleaned, merged, and processed to identify fraudulent transactions based on buyer-seller relationships and transaction frequency. 💰💡

## Steps Performed ✅

### 1. Data Preparation 🛠️

#### **📂 dim_paper_company**
- Load `dim__paper__company.csv`.
- Check data structure and missing values.

#### **📂 dim_paper_promotion**
- Load `dim__paper__promotion.csv`.
- Fill missing values in specific columns with 'unknown'.
- Save the cleaned dataset as `updated_dim__paper__promotion.csv`. 🧹

#### **📂 fact_paper_digital_payment_request**
- Load `fact__paper__digital_payment_request.csv`.
- Check for missing values.

#### **📂 fact_paper_digital_payment_transaction**
- Load `fact__paper__digital_payment_transaction.csv`.
- Fill missing values in `dpt_promotion_id` column.
- Save the updated dataset as `fact__paper__digital_payment_transaction_update.csv`. 🔄

### 2. Data Hashing for Security 🔐
- Use SHA-256 hashing to verify if a `promotion_id` matches an expected hash.

### 3. Data Merging 🔗
- Merge `dim_paper_company`, `dim_paper_promotion`, `fact_paper_digital_payment_request`, and `fact_paper_digital_payment_transaction`.
- Remove encrypted `dpt_promotion` column.
- Rename duplicate columns.
- Save the merged dataset as `combined_dataset.csv`. 📊
- Filter relevant columns and save as `processed_combined_dataset.csv`.

### 4. Feature Engineering 🏗️

#### **👥 Buyer-Seller Relationship Score**
- Compute daily transaction counts per `buyer_id` and `seller_id`.
- Label transactions as fraud if the daily count exceeds 1,250. 🚨
- Save as `fact__paper__digital_payment_transaction1.csv`.

#### **📈 Transaction Frequency Metrics**
- Compute time differences between consecutive transactions for each buyer.
- Label transactions as fraud if the interval is less than 60 seconds or more than 604,800 seconds (7 days).
- Save the final dataset as `fact__paper__digital_payment_transaction_with_fraud_detection.csv`. 🚦

### 5. Outlier Handling 🎯
- Identify and process outliers in selected numerical columns (`transaction_amount`, `total_fee_amount`, `daily_transaction_count`, and `time_diff`).
- Compare the original dataset with a processed version where outliers have been replaced.
- Visualize the distributions before and after outlier handling using histograms. 📊

### 6. Normalization 📏
- After outlier handling, the processed dataset undergoes normalization using Min-Max Scaling to standardize values between 0 and 1.
- Visualize the distributions before and after normalization to ensure the data is well-prepared for further analysis. 🎨

### 7. Exploratory Data Analysis (EDA) 🔎
- **Transaction distribution analysis** 📊
- **Fraud vs. non-fraud comparison** ⚖️
- **Boxplots to detect outliers in transaction amounts** 📦
- **Heatmaps for correlation analysis** 🔥

### 8. Visualization 🎨
- **📊 Bar charts**: Showing daily fraud transaction counts
- **📉 Time series plots**: Analyzing transaction volume trends
- **📌 Scatter plots**: Identifying fraud patterns based on amount and frequency
- **📊 Histograms**: Distribution of transaction amounts

### 9. Fraud Flag Aggregation 🚨
- 🔢 Count occurrences of each fraud flag across different columns.
- 👥 Aggregate fraud flags for each `buyer-seller` pair.
- 🔝 Identify the top `buyer-seller` pairs with the highest fraud indicators.
- 💾 Save the summary as `fraudulent_buyer_seller_summary.csv`.
- 📊 Visualize the top fraudulent buyer-seller pairs with bar charts for better insights. 🔥

## SQL Implementation 🖥️

### 1. Identifying Transaction Anomalies ❗
**Purpose**:
- Detect transactions with values significantly different from the usual amount for each buyer-seller pair.

**Method**:
- Compute average and standard deviation of transaction amounts per buyer-seller pair.
- Flag transactions that deviate more than 3 standard deviations from the mean. 🚩

### 2. Buyer-Seller Relationship Analysis 👥
**Purpose**:
- Identify buyer-seller pairs with unusually high transaction frequencies or amounts, which may indicate collusion.

**Method**:
- Calculate total transaction count and sum of amounts per buyer-seller pair.
- Compare these statistics to global averages and standard deviations.
- Flag pairs that exceed the threshold. 🕵️

### 3. Promotion Misuse Detection 🎁
**Purpose**:
- Detect excessive use of promotions within a short period, indicating potential fraud.

**Method**:
- Count promotion usage per buyer per day.
- Compare against global averages and standard deviations.
- Flag buyers exceeding thresholds. 🚩

### 4. Suspicious Timing Analysis ⏳
**Purpose**:
- Identify transactions occurring at irregular hours or intervals, such as high volumes in short durations.

**Method**:
- Count transactions per hour.
- Identify those exceeding global averages by 3 standard deviations.
- Flag transactions occurring during unusual hours (e.g., midnight to early morning). 🌙

### 5. Top Fraudulent Buyer-Seller Pairs 🔝
**Purpose**:
- Summarize the most suspicious buyer-seller relationships based on frequency and transaction amount.

**Method**:
- Sum up fraud flags per buyer-seller pair.
- Rank buyer-seller pairs by total fraud flags. 🚦
- Store results for further investigation. 📝
- 📈 Generate reports with visualization to highlight the most frequent fraudulent interactions. 🔥
