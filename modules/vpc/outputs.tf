output "vpc_id"             { value = aws_vpc.main.id }
output "public_subnet_ids"  { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "sg_lambda_id"       { value = aws_security_group.lambda.id }
output "sg_rds_id"          { value = aws_security_group.rds.id }
output "sg_vpc_endpoint_id" { value = aws_security_group.vpc_endpoint.id }
