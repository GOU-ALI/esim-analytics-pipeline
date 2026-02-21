package com.telecom

import org.apache.spark.sql.{SparkSession, functions => F}
import org.apache.spark.sql.types._

object EsimKpiJob {
  def main(args: Array[String]): Unit = {
    // Initialize Spark Session
    val spark = SparkSession.builder()
      .appName("EsimKpiJob")
      .getOrCreate()

    import spark.implicits._

    // Configuration (Passed as args in prod)
    if (args.length < 3) {
      System.err.println("Usage: EsimKpiJob <projectId> <bucketName> <bqDataset>")
      System.exit(1)
    }

    val projectId = args(0)
    val bucket = args(1)
    val bqDataset = args(2)
    
    // GCS Paths
    val ordersPath = s"gs://$bucket/raw/esim_orders.csv"
    val activationsPath = s"gs://$bucket/raw/esim_activations.csv"
    // val usagePath = s"gs://$bucket/raw/esim_usage.csv" // For future use

    // 1. Load Data
    val ordersDf = spark.read
      .option("header", "true")
      .option("inferSchema", "true")
      .csv(ordersPath)

    val activationsDf = spark.read
      .option("header", "true")
      .option("inferSchema", "true")
      .csv(activationsPath)

    // 2. Transformation: Join Orders & Activations
    // Clean timestamps
    val orders = ordersDf
      .withColumn("order_ts", F.to_timestamp($"order_timestamp"))
      .drop("order_timestamp")

    val activations = activationsDf
      .withColumn("activation_ts", F.to_timestamp($"activation_timestamp"))
      .drop("activation_timestamp")

    val enrichedDf = orders.join(activations, Seq("order_id"), "left")

    // 3. KPI 1: Daily Activation Success Rate & Avg Provisioning Time
    val dailyKpis = enrichedDf
      .withColumn("date", F.to_date($"order_ts"))
      .groupBy("date")
      .agg(
        F.count("order_id").as("total_orders"),
        F.sum(F.when($"status" === "SUCCESS", 1).otherwise(0)).as("successful_activations"),
        F.avg("provisioning_duration_sec").as("avg_provisioning_time_sec")
      )
      .withColumn("success_rate", ($"successful_activations" / $"total_orders") * 100)
      .orderBy("date")

    // 4. KPI 2: Device Stats (Adoption by Model)
    val deviceStats = enrichedDf
      .groupBy("device_model")
      .agg(
        F.count("order_id").as("total_orders"),
        F.sum(F.when($"status" === "SUCCESS", 1).otherwise(0)).as("successful_activations")
      )
      .withColumn("failure_rate", (($"total_orders" - $"successful_activations") / $"total_orders") * 100)
      .orderBy(F.desc("total_orders"))

    // Show results in logs
    println("--- Daily KPIs ---")
    dailyKpis.show(5)
    println("--- Device Stats ---")
    deviceStats.show(5)

    // 5. Write to BigQuery (Temporary bucket for BQ load)
    val tempBucket = s"$bucket/temp"
    
    dailyKpis.write
      .format("bigquery")
      .option("temporaryGcsBucket", tempBucket)
      .option("table", s"$projectId:$bqDataset.daily_kpis")
      .mode("overwrite")
      .save()

    deviceStats.write
      .format("bigquery")
      .option("temporaryGcsBucket", tempBucket)
      .option("table", s"$projectId:$bqDataset.device_stats")
      .mode("overwrite")
      .save()

    println("Job Completed Successfully. Data written to BigQuery.")
    spark.stop()
  }
}
