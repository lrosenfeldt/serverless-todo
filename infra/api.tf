resource "random_pet" "lambda_bucket_name" {
  prefix = "lambda"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

variable "endpoints" {
  type = map(object({
    route  = string
    method = string
    name   = string
  }))
  description = "(optional) describe your variable"
  default = {
    "hello" = {
      method = "GET"
      route  = "hello"
      name   = "Hello"
    },
    "downgrade-css" = {
      method = "POST"
      route  = "downgrade-css"
      name   = "Downgrade-CSS"
    }
  }
}

data "archive_file" "lambda" {
  for_each    = var.endpoints
  type        = "zip"
  source_dir  = "${path.module}/functions/${each.key}"
  output_path = "${path.module}/${each.key}.zip"
}

resource "aws_s3_object" "lambda" {
  for_each = var.endpoints
  bucket   = aws_s3_bucket.lambda_bucket.id
  key      = "${each.key}.zip"
  source   = data.archive_file.lambda[each.key].output_path
  etag     = filemd5(data.archive_file.lambda[each.key].output_path)
}

resource "aws_lambda_function" "lambda" {
  for_each         = var.endpoints
  function_name    = each.value.name
  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda[each.key].key
  runtime          = "nodejs16.x"
  handler          = "app.handler"
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["http://localhost:8080", "http://localhost:3000", "https://${aws_amplify_branch.prod_branch.branch_name}.${aws_amplify_app.frontend.id}.amplifyapp.com"]
    allow_headers = ["content-type"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = "serverless_lambda_stage"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each               = var.endpoints
  api_id                 = aws_apigatewayv2_api.lambda.id
  integration_uri        = aws_lambda_function.lambda[each.key].invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda" {
  for_each  = var.endpoints
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "${each.value.method} /${each.key}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "serverless-todo/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gw" {
  for_each      = var.endpoints
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
