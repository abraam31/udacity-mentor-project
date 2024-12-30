resource "aws_s3_object" "file_upload" {
  bucket = "uda-abraam-data"
  key    = "script/fraud_detector_model_trainer.py"
  source = "${path.module}/../fraud_detector_model_trainer.py"
  etag   = "${filemd5("${path.module}/../fraud_detector_model_trainer.py")}"
}

resource "aws_glue_job" "fraudapi-glue" {
  name     = "udacity-glue-abraam"
  role_arn = "arn:aws:iam::174361135196:role/glue-s3-access"
  execution_class = "STANDARD"
  default_arguments = {
          "--TempDir"                          = "s3://aws-glue-assets-174361135196-us-east-1/temporary/"
          "--enable-continuous-cloudwatch-log" = "true"
          "--enable-glue-datacatalog"          = "true"
          "--enable-job-insights"              = "true"
          "--enable-metrics"                   = "true"
          "--enable-observability-metrics"     = "true"
          "--job-bookmark-option"              = "job-bookmark-disable"
          "--job-language"                     = "python"
          "--spark-event-logs-path"            = "s3://aws-glue-assets-174361135196-us-east-1/sparkHistoryLogs/"
  }
  command {
    script_location = "s3://uda-abraam-data/script/fraud_detector_model_trainer.py"
  }
}

#terraform import aws_glue_job.fraudapi-glue udacity-glue-abraam
