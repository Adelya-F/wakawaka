# ─────────────────────────────────────────────
# ALARMS
# ─────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lks-alarm-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda errors > 5 in 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  dimensions          = { FunctionName = var.lambda_order_management_name }
}

resource "aws_cloudwatch_metric_alarm" "apigw_4xx" {
  alarm_name          = "lks-alarm-apigw-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway 4XX errors > 10 in 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  dimensions          = { ApiName = var.api_gateway_name }
}

resource "aws_cloudwatch_metric_alarm" "stepfunctions_failures" {
  alarm_name          = "lks-alarm-stepfunctions-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 600
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Step Functions failures > 3 in 10 minutes"
  alarm_actions       = [var.sns_topic_arn]
  dimensions          = { StateMachineArn = var.stepfunctions_state_machine_arn }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "lks-alarm-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU > 80% for 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
}

# ─────────────────────────────────────────────
# DASHBOARD
# ─────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "lks-dashboard-serverless"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x = 0; y = 0; width = 12; height = 6
        properties = {
          title   = "Lambda - Invocations & Errors"
          view    = "timeSeries"
          period  = 300
          stat    = "Sum"
          metrics = [for name in var.lambda_names : ["AWS/Lambda", "Invocations", "FunctionName", name]]
        }
      },
      {
        type   = "metric"
        x = 12; y = 0; width = 12; height = 6
        properties = {
          title   = "API Gateway - Requests & Errors"
          view    = "timeSeries"
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/ApiGateway", "Count",    "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "4XXError", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_name]
          ]
        }
      },
      {
        type   = "metric"
        x = 0; y = 6; width = 12; height = 6
        properties = {
          title   = "Step Functions - Executions"
          view    = "timeSeries"
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/States", "ExecutionsStarted",  "StateMachineArn", var.stepfunctions_state_machine_arn],
            ["AWS/States", "ExecutionsSucceeded", "StateMachineArn", var.stepfunctions_state_machine_arn],
            ["AWS/States", "ExecutionsFailed",   "StateMachineArn", var.stepfunctions_state_machine_arn]
          ]
        }
      },
      {
        type   = "metric"
        x = 12; y = 6; width = 12; height = 6
        properties = {
          title   = "RDS - CPU & Connections"
          view    = "timeSeries"
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "CPUUtilization",     "DBInstanceIdentifier", var.rds_instance_id],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id]
          ]
        }
      }
    ]
  })
}
