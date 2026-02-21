-- ==============================================================================
-- 🚀 BigQuery Sample Queries for eSIM Analytics
--
-- These queries demonstrate the value of having your KPI data in BigQuery.
-- You can run these directly in the BigQuery Console to gain instant insights
-- without needing to spin up a Spark cluster.
--
-- Note: Replace `[YOUR_PROJECT_ID]` with your actual GCP Project ID.
-- ==============================================================================

-- 1. 📉 Identify Problematic Devices
-- Find device models with the highest failure rate. This is crucial for 
-- customer support and technical teams to identify hardware compatibility issues.
-- We filter for total_orders > 10 to ignore statistical noise from rare devices.
SELECT 
    device_model, 
    total_orders, 
    successful_activations,
    failure_rate 
FROM `[YOUR_PROJECT_ID].esim_analytics.device_stats`
WHERE total_orders > 10
ORDER BY failure_rate DESC
LIMIT 10;


-- 2. 📈 Monitor Daily Performance Trends
-- Track the success rate and average provisioning time over the last 7 days.
-- This query acts as the backbone for a daily monitoring dashboard (e.g., Looker).
SELECT 
    date, 
    total_orders,
    success_rate, 
    avg_provisioning_time_sec 
FROM `[YOUR_PROJECT_ID].esim_analytics.daily_kpis`
WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY date DESC;


-- 3. ⏱️ Provisioning Time Analysis
-- Check if high provisioning time correlates with lower success rates on a daily basis.
SELECT 
    date,
    avg_provisioning_time_sec,
    success_rate,
    IF(avg_provisioning_time_sec > 30, 'High Latency', 'Normal') as latency_category
FROM `[YOUR_PROJECT_ID].esim_analytics.daily_kpis`
ORDER BY avg_provisioning_time_sec DESC
LIMIT 15;


-- 4. 📱 Market Share Analysis (Top 5 Most Popular Devices)
-- Understand which devices are driving the most eSIM orders.
SELECT
    device_model,
    total_orders,
    ROUND((total_orders / SUM(total_orders) OVER()) * 100, 2) AS market_share_percentage
FROM `[YOUR_PROJECT_ID].esim_analytics.device_stats`
ORDER BY total_orders DESC
LIMIT 5;
