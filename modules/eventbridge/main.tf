# ─────────────────────────────────────────────
# RULE 1: Daily Report — cron(59 23 * * ? *)
# ─────────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "daily_report" {
  name                = "lks-eventbridge-daily-report"
  description         = "Trigger lks-lambda-generate-report at 23:59 UTC daily"
  schedule_expression = "cron(59 23 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "daily_report" {
  rule      = aws_cloudwatch_event_rule.daily_report.name
  target_id = "GenerateReportLambda"
  arn       = var.lambda_generate_report_arn
}

resource "aws_lambda_permission" "daily_report" {
  statement_id  = "AllowEventBridgeDailyReport"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_generate_report_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report.arn
}

# ─────────────────────────────────────────────
# RULE 2: Order Status Events — custom pattern
# Triggers send_notification on order state changes
# ─────────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "order_status" {
  name        = "lks-eventbridge-order-status"
  description = "Capture order status changes and notify"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source      = ["order.system"]
    "detail-type" = ["OrderStatusChanged"]
    detail = {
      status = ["ORDER_CREATED", "ORDER_PAID", "ORDER_SHIPPED", "ORDER_FAILED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "order_status" {
  rule      = aws_cloudwatch_event_rule.order_status.name
  target_id = "SendNotificationLambda"
  arn       = var.lambda_send_notification_arn
}

resource "aws_lambda_permission" "order_status" {
  statement_id  = "AllowEventBridgeOrderStatus"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_send_notification_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.order_status.arn
}

# ─────────────────────────────────────────────
# RULE 3: Low Stock Check — rate(1 hour)
# Also triggered from update_inventory via put_events
# ─────────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "low_stock" {
  name                = "lks-eventbridge-low-stock"
  description         = "Hourly low stock inventory check"
  schedule_expression = "rate(1 hour)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "low_stock" {
  rule      = aws_cloudwatch_event_rule.low_stock.name
  target_id = "SendNotificationLambdaLowStock"
  arn       = var.lambda_send_notification_arn

  input = jsonencode({
    notification_type = "low_stock"
    source            = "scheduled-check"
  })
}

resource "aws_lambda_permission" "low_stock" {
  statement_id  = "AllowEventBridgeLowStock"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_send_notification_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.low_stock.arn
}
