output "order_management_arn"        { value = aws_lambda_function.order_management.arn }
output "order_management_invoke_arn" { value = aws_lambda_function.order_management.invoke_arn }
output "order_management_name"       { value = aws_lambda_function.order_management.function_name }

output "process_payment_arn"         { value = aws_lambda_function.process_payment.arn }
output "process_payment_name"        { value = aws_lambda_function.process_payment.function_name }

output "update_inventory_arn"        { value = aws_lambda_function.update_inventory.arn }
output "update_inventory_name"       { value = aws_lambda_function.update_inventory.function_name }

output "send_notification_arn"       { value = aws_lambda_function.send_notification.arn }
output "send_notification_name"      { value = aws_lambda_function.send_notification.function_name }

output "generate_report_arn"         { value = aws_lambda_function.generate_report.arn }
output "generate_report_name"        { value = aws_lambda_function.generate_report.function_name }

output "init_database_arn"           { value = aws_lambda_function.init_database.arn }
output "init_database_name"          { value = aws_lambda_function.init_database.function_name }

output "all_lambda_names" {
  value = [
    aws_lambda_function.order_management.function_name,
    aws_lambda_function.process_payment.function_name,
    aws_lambda_function.update_inventory.function_name,
    aws_lambda_function.send_notification.function_name,
    aws_lambda_function.generate_report.function_name,
    aws_lambda_function.init_database.function_name,
  ]
}
