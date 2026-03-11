data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_region" "current" {}

# ─────────────────────────────────────────────
# LAMBDA LAYER
# ─────────────────────────────────────────────
resource "aws_lambda_layer_version" "dependencies" {
  filename            = "${path.module}/../../layer/dependencies.zip"
  layer_name          = "lks-layer-dependencies"
  compatible_runtimes = ["python3.11"]
  description         = "psycopg2-binary, boto3, requests, pandas, openpyxl"
}

# ─────────────────────────────────────────────
# LAMBDA: ORDER MANAGEMENT  (lks-lambda-order-management)
# Source: lambda/order_management/lambda_function.py
# ─────────────────────────────────────────────
data "archive_file" "order_management" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/order_management"
  output_path = "${path.module}/../../lambda/order_management.zip"
}

resource "aws_lambda_function" "order_management" {
  filename         = data.archive_file.order_management.output_path
  function_name    = "lks-lambda-order-management"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  memory_size      = 512
  timeout          = 30
  source_code_hash = data.archive_file.order_management.output_base64sha256

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_lambda_id]
  }

  environment {
    variables = {
      DB_HOST           = var.rds_endpoint
      DB_NAME           = "ordersdb"
      DB_USER           = "dbadmin"
      DB_PASSWORD       = var.db_password
      S3_BUCKET         = var.s3_orders_bucket
      SNS_TOPIC_ARN     = var.sns_topic_arn
      STATE_MACHINE_ARN = var.state_machine_arn
    }
  }

  tags = { Name = "lks-lambda-order-management" }
}

# ─────────────────────────────────────────────
# LAMBDA: PROCESS PAYMENT  (lks-lambda-process-payment)
# Source: lambda/process_payment/lambda_function.py
# ─────────────────────────────────────────────
data "archive_file" "process_payment" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/process_payment"
  output_path = "${path.module}/../../lambda/process_payment.zip"
}

resource "aws_lambda_function" "process_payment" {
  filename         = data.archive_file.process_payment.output_path
  function_name    = "lks-lambda-process-payment"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  memory_size      = 512
  timeout          = 30
  source_code_hash = data.archive_file.process_payment.output_base64sha256

  layers = [aws_lambda_layer_version.dependencies.arn]

  tags = { Name = "lks-lambda-process-payment" }
}

# ─────────────────────────────────────────────
# LAMBDA: UPDATE INVENTORY  (lks-lambda-update-inventory)
# Source: lambda/update_inventory/lambda_function.py
# ─────────────────────────────────────────────
data "archive_file" "update_inventory" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/update_inventory"
  output_path = "${path.module}/../../lambda/update_inventory.zip"
}

resource "aws_lambda_function" "update_inventory" {
  filename         = data.archive_file.update_inventory.output_path
  function_name    = "lks-lambda-update-inventory"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  memory_size      = 256
  timeout          = 45
  source_code_hash = data.archive_file.update_inventory.output_base64sha256

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_lambda_id]
  }

  environment {
    variables = {
      DB_HOST     = var.rds_endpoint
      DB_NAME     = "ordersdb"
      DB_USER     = "dbadmin"
      DB_PASSWORD = var.db_password
    }
  }

  tags = { Name = "lks-lambda-update-inventory" }
}

# ─────────────────────────────────────────────
# LAMBDA: SEND NOTIFICATION  (lks-lambda-send-notification)
# Source: lambda/send_notification/lambda_function.py
# ─────────────────────────────────────────────
data "archive_file" "send_notification" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/send_notification"
  output_path = "${path.module}/../../lambda/send_notification.zip"
}

resource "aws_lambda_function" "send_notification" {
  filename         = data.archive_file.send_notification.output_path
  function_name    = "lks-lambda-send-notification"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  memory_size      = 256
  timeout          = 60
  source_code_hash = data.archive_file.send_notification.output_base64sha256

  layers = [aws_lambda_layer_version.dependencies.arn]

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = { Name = "lks-lambda-send-notification" }
}

# ─────────────────────────────────────────────
# LAMBDA: GENERATE REPORT  (lks-lambda-generate-report)
# Source: lambda/generate_report/lambda_function.py
# ─────────────────────────────────────────────
data "archive_file" "generate_report" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/generate_report"
  output_path = "${path.module}/../../lambda/generate_report.zip"
}

resource "aws_lambda_function" "generate_report" {
  filename         = data.archive_file.generate_report.output_path
  function_name    = "lks-lambda-generate-report"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  memory_size      = 1024
  timeout          = 60
  source_code_hash = data.archive_file.generate_report.output_base64sha256

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_lambda_id]
  }

  environment {
    variables = {
      DB_HOST     = var.rds_endpoint
      DB_NAME     = "ordersdb"
      DB_USER     = "dbadmin"
      DB_PASSWORD = var.db_password
      S3_BUCKET   = var.s3_orders_bucket
    }
  }

  tags = { Name = "lks-lambda-generate-report" }
}

# ─────────────────────────────────────────────
# LAMBDA: INIT DATABASE  (lks-lambda-init-db)
# Source: lambda/init_database/lambda_function.py
# ─────────────────────────────────────────────
data "archive_file" "init_database" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/init_database"
  output_path = "${path.module}/../../lambda/init_database.zip"
}

resource "aws_lambda_function" "init_database" {
  filename         = data.archive_file.init_database.output_path
  function_name    = "lks-lambda-init-db"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  memory_size      = 512
  timeout          = 300
  source_code_hash = data.archive_file.init_database.output_base64sha256

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_lambda_id]
  }

  environment {
    variables = {
      DB_HOST     = var.rds_endpoint
      DB_NAME     = "ordersdb"
      DB_USER     = "dbadmin"
      DB_PASSWORD = var.db_password
    }
  }

  tags = { Name = "lks-lambda-init-db" }
}

# ─────────────────────────────────────────────
# CLOUDWATCH LOG GROUPS
# ─────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = {
    order_management  = "/aws/lambda/lks-lambda-order-management"
    process_payment   = "/aws/lambda/lks-lambda-process-payment"
    update_inventory  = "/aws/lambda/lks-lambda-update-inventory"
    send_notification = "/aws/lambda/lks-lambda-send-notification"
    generate_report   = "/aws/lambda/lks-lambda-generate-report"
    init_database     = "/aws/lambda/lks-lambda-init-db"
  }
  name              = each.value
  retention_in_days = 7
}
