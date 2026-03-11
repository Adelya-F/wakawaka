output "rds_endpoint"    { value = split(":", aws_db_instance.main.endpoint)[0] }
output "rds_instance_id" { value = aws_db_instance.main.id }
output "rds_arn"         { value = aws_db_instance.main.arn }
