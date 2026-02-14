# eSIM Data Analytics Pipeline on GCP

This project demonstrates a complete Data Engineering pipeline on Google Cloud Platform (GCP) to analyze eSIM lifecycle events.

## 🎯 Goal
Ingest, process, and analyze eSIM data (Orders, Activations, Usage) to calculate Key Performance Indicators (KPIs) such as **Activation Success Rate** and **Provisioning Time**.

## 🏗 Architecture
1.  **Ingestion**: Python script generates synthetic CSV data.
2.  **Storage**: Data is uploaded to **Cloud Storage (GCS)**.
3.  **Processing**: **Apache Spark** job (Scala) on **Cloud Dataproc** processes data and calculates KPIs.
4.  **Warehousing**: Results are loaded into **BigQuery** for analysis.
5.  **Visualization**: Dashboard in **Looker Studio** (optional).
6.  **IaC**: Infrastructure managed via **Terraform**.

## 🛠 Tech Stack
-   **Language**: Scala (Spark), Python (Data Gen), HCL (Terraform)
-   **GCP Services**: GCS, Dataproc, BigQuery
-   **Tools**: SBT, gcloud CLI

## 🚀 How to Run

### Prerequisites
-   GCP Project with Billing enabled.
-   `gcloud` CLI installed and authenticated.
-   `terraform` and `sbt` installed.

### 1. Infrastructure Setup (Terraform)
```bash
cd terraform
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

### 2. Build & Deploy
Use the helper script to generate data, build the Jar, upload to GCS, and submit the Spark job:

```bash
# Update PROJECT_ID in scripts/deploy_and_run.sh before running!
sh scripts/deploy_and_run.sh
```

### 3. Check Results (BigQuery)
Go to BigQuery Console and query the `esim_analytics.daily_kpis` table:

```sql
SELECT * FROM esim_analytics.daily_kpis ORDER BY date DESC;
```

## 🧹 Cleanup
To avoid billing charges, destroy the infrastructure:
```bash
cd terraform
terraform destroy -var="project_id=YOUR_PROJECT_ID"
```
