# ─────────────────────────────────────────────
# REST API
# Routes match lambda_function.py routing:
# GET/POST  /orders
# GET/PUT/DELETE /orders/{id}
# GET /status/{id}
# GET /customers
# GET /products
# GET /executions
# ─────────────────────────────────────────────
resource "aws_api_gateway_rest_api" "main" {
  name        = "lks-api-orders"
  description = "LKS Serverless Order Management REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = { Name = "lks-api-orders" }
}

# ─── RESOURCES ───────────────────────────────
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_resource" "order_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.orders.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "status_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.status.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "customers" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "customers"
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_resource" "executions" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "executions"
}

# ─── LAMBDA INTEGRATION URI ──────────────────
locals {
  lambda_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_order_management_arn}/invocations"

  endpoints = {
    "GET-orders"      = { resource_id = aws_api_gateway_resource.orders.id,     http_method = "GET" }
    "POST-orders"     = { resource_id = aws_api_gateway_resource.orders.id,     http_method = "POST" }
    "GET-order-id"    = { resource_id = aws_api_gateway_resource.order_id.id,   http_method = "GET" }
    "PUT-order-id"    = { resource_id = aws_api_gateway_resource.order_id.id,   http_method = "PUT" }
    "DELETE-order-id" = { resource_id = aws_api_gateway_resource.order_id.id,   http_method = "DELETE" }
    "GET-status-id"   = { resource_id = aws_api_gateway_resource.status_id.id,  http_method = "GET" }
    "GET-customers"   = { resource_id = aws_api_gateway_resource.customers.id,  http_method = "GET" }
    "GET-products"    = { resource_id = aws_api_gateway_resource.products.id,   http_method = "GET" }
    "GET-executions"  = { resource_id = aws_api_gateway_resource.executions.id, http_method = "GET" }
  }
}

# ─── METHODS ─────────────────────────────────
resource "aws_api_gateway_method" "methods" {
  for_each         = local.endpoints
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = each.value.resource_id
  http_method      = each.value.http_method
  authorization    = "NONE"
  api_key_required = true
}

# ─── INTEGRATIONS ────────────────────────────
resource "aws_api_gateway_integration" "integrations" {
  for_each                = local.endpoints
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = each.value.resource_id
  http_method             = aws_api_gateway_method.methods[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

# ─── OPTIONS (CORS) for each resource ────────
locals {
  cors_resources = {
    orders      = aws_api_gateway_resource.orders.id
    order_id    = aws_api_gateway_resource.order_id.id
    status_id   = aws_api_gateway_resource.status_id.id
    customers   = aws_api_gateway_resource.customers.id
    products    = aws_api_gateway_resource.products.id
    executions  = aws_api_gateway_resource.executions.id
  }
}

resource "aws_api_gateway_method" "options" {
  for_each      = local.cors_resources
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options_200[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ─── LAMBDA PERMISSION ───────────────────────
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_order_management_invoke_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# ─── DEPLOYMENT & STAGE ──────────────────────
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode(merge(local.endpoints, local.cors_resources)))
  }

  lifecycle { create_before_destroy = true }
  depends_on = [aws_api_gateway_integration.integrations, aws_api_gateway_integration.options]
}

resource "aws_api_gateway_stage" "production" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "production"
  tags          = { Name = "production" }
}

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/lks-api-orders"
  retention_in_days = 7
}

# ─── API KEY & USAGE PLAN ────────────────────
resource "aws_api_gateway_api_key" "main" {
  name    = "lks-api-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "main" {
  name = "lks-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.production.stage_name
  }

  throttle_settings {
    rate_limit  = 1000
    burst_limit = 2000
  }

  quota_settings {
    limit  = 100000
    period = "MONTH"
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
