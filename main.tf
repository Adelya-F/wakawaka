terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────
# VPC & NETWORKING
# ─────────────────────────────────────────────
module "vpc" {
  source          = "./modules/vpc"
  vpc_name        = "lks-vpc-serverless"
  vpc_cidr        = "20.1.0.0/20"
  public_subnets  = ["20.1.0.0/25", "20.1.1.0/25"]
  private_subnets = ["20.1.11.0/25", "20.1.12.0/25"]
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
}

# ─────────────────────────────────────────────
# S3 BUCKETS
# ─────────────────────────────────────────────
module "s3" {
  source    = "./modules/s3"
  your_name = var.your_name
}

# ─────────────────────────────────────────────
# RDS
# ─────────────────────────────────────────────
module "rds" {
  source             = "./modules/rds"
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_rds_id          = module.vpc.sg_rds_id
  db_password        = var.db_password
}

# ─────────────────────────────────────────────
# SNS
# ─────────────────────────────────────────────
module "sns" {
  source             = "./modules/sns"
  notification_email = var.notification_email
}

# ─────────────────────────────────────────────
# STEP FUNCTIONS  (created before Lambda so we have the ARN)
# ─────────────────────────────────────────────
module "stepfunctions" {
  source                       = "./modules/stepfunctions"
  lambda_order_management_arn  = module.lambda.order_management_arn
  lambda_process_payment_arn   = module.lambda.process_payment_arn
  lambda_update_inventory_arn  = module.lambda.update_inventory_arn
  lambda_send_notification_arn = module.lambda.send_notification_arn
}

# ─────────────────────────────────────────────
# LAMBDA FUNCTIONS
# ─────────────────────────────────────────────
module "lambda" {
  source             = "./modules/lambda"
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_lambda_id       = module.vpc.sg_lambda_id
  rds_endpoint       = module.rds.rds_endpoint
  s3_orders_bucket   = module.s3.orders_bucket_name
  sns_topic_arn      = module.sns.topic_arn
  db_password        = var.db_password
  aws_region         = var.aws_region
  # STATE_MACHINE_ARN will be updated via null_resource after stepfunctions is created
  state_machine_arn  = module.stepfunctions.state_machine_arn
}

# ─────────────────────────────────────────────
# API GATEWAY
# ─────────────────────────────────────────────
module "apigateway" {
  source                             = "./modules/apigateway"
  lambda_order_management_arn        = module.lambda.order_management_arn
  lambda_order_management_invoke_arn = module.lambda.order_management_invoke_arn
  aws_region                         = var.aws_region
}

# ─────────────────────────────────────────────
# EVENTBRIDGE
# ─────────────────────────────────────────────
module "eventbridge" {
  source                        = "./modules/eventbridge"
  lambda_generate_report_arn    = module.lambda.generate_report_arn
  lambda_send_notification_arn  = module.lambda.send_notification_arn
  lambda_generate_report_name   = module.lambda.generate_report_name
  lambda_send_notification_name = module.lambda.send_notification_name
}

# ─────────────────────────────────────────────
# CLOUDWATCH
# ─────────────────────────────────────────────
module "cloudwatch" {
  source                          = "./modules/cloudwatch"
  sns_topic_arn                   = module.sns.topic_arn
  lambda_order_management_name    = module.lambda.order_management_name
  api_gateway_name                = module.apigateway.api_name
  stepfunctions_state_machine_arn = module.stepfunctions.state_machine_arn
  rds_instance_id                 = module.rds.rds_instance_id
  lambda_names                    = module.lambda.all_lambda_names
}
