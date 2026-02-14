name := "EsimAnalytics"

version := "0.1"

scalaVersion := "2.12.18"

val sparkVersion = "3.5.0"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % sparkVersion % "provided",
  "org.apache.spark" %% "spark-sql" % sparkVersion % "provided",
  "com.google.cloud.spark" %% "spark-bigquery-with-dependencies" % "0.34.0"
)


