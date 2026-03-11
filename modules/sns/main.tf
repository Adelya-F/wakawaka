resource "aws_sns_topic" "orders" {
  name = "lks-sns-order-notifications"
  tags = { Name = "lks-sns-order-notifications" }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
