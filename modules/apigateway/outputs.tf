output "api_name"      { value = aws_api_gateway_rest_api.main.name }
output "api_id"        { value = aws_api_gateway_rest_api.main.id }
output "invoke_url"    { value = "${aws_api_gateway_stage.production.invoke_url}" }
output "api_key_value" { value = aws_api_gateway_api_key.main.value; sensitive = true }
output "api_key_id"    { value = aws_api_gateway_api_key.main.id }
