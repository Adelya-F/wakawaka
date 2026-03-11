variable "private_subnet_ids" { type = list(string) }
variable "sg_lambda_id"       { type = string }
variable "rds_endpoint"       { type = string }
variable "s3_orders_bucket"   { type = string }
variable "sns_topic_arn"      { type = string }
variable "db_password"        { type = string; sensitive = true }
variable "aws_region"         { type = string }
variable "state_machine_arn"  { type = string; default = "" }
