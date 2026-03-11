output "daily_report_rule_arn" { value = aws_cloudwatch_event_rule.daily_report.arn }
output "order_status_rule_arn" { value = aws_cloudwatch_event_rule.order_status.arn }
output "low_stock_rule_arn"    { value = aws_cloudwatch_event_rule.low_stock.arn }
