output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "rds_endpoint" {
  description = "RDS endpoint (host only)"
  value       = module.rds.rds_endpoint
}

output "api_gateway_url" {
  description = "API Gateway invoke URL - use this in Amplify env vars (API_ENDPOINT)"
  value       = module.apigateway.invoke_url
}

output "api_key_value" {
  description = "API Key - use this in Amplify env vars (API_KEY)"
  value       = module.apigateway.api_key_value
  sensitive   = true
}

output "s3_orders_bucket" {
  description = "S3 bucket for order documents"
  value       = module.s3.orders_bucket_name
}

output "s3_logs_bucket" {
  description = "S3 bucket for application logs"
  value       = module.s3.logs_bucket_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = module.sns.topic_arn
}

output "step_functions_arn" {
  description = "Step Functions state machine ARN"
  value       = module.stepfunctions.state_machine_arn
}

output "cloudwatch_dashboard" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=lks-dashboard-serverless"
}

output "setup_instructions" {
  description = "Next steps after terraform apply"
  value       = <<-EOT
    ============================================================
    NEXT STEPS AFTER TERRAFORM APPLY
    ============================================================
    1. Initialize database:
       aws lambda invoke --function-name lks-lambda-init-db \
         --payload '{"insert_sample_data": true}' \
         --region us-east-1 response.json && cat response.json

    2. Get API URL and Key for Amplify:
       terraform output api_gateway_url
       terraform output -raw api_key_value

    3. Connect GitHub repository to AWS Amplify:
       - App name: lks-amplify-order-app
       - Branch: master (or main)
       - amplify.yml is already in repo root

    4. Set Amplify environment variables:
       - API_ENDPOINT = (output from step 2)
       - API_KEY      = (output from step 2)
       
    5. Add GitHub Secrets for CI/CD:
       - AWS_ACCESS_KEY_ID
       - AWS_SECRET_ACCESS_KEY
       - AWS_SESSION_TOKEN
    ============================================================
  EOT
}
