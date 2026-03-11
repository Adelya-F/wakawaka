output "orders_bucket_name" { value = aws_s3_bucket.orders.bucket }
output "orders_bucket_arn"  { value = aws_s3_bucket.orders.arn }
output "logs_bucket_name"   { value = aws_s3_bucket.logs.bucket }
output "logs_bucket_arn"    { value = aws_s3_bucket.logs.arn }
