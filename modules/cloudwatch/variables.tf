variable "sns_topic_arn"                   { type = string }
variable "lambda_order_management_name"    { type = string }
variable "api_gateway_name"                { type = string }
variable "stepfunctions_state_machine_arn" { type = string }
variable "rds_instance_id"                 { type = string }
variable "lambda_names"                    { type = list(string) }
