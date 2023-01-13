terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
  cloud {
    organization = "lrosenfeldt-personal"

    workspaces {
      name = "opencampus-devops"
    }
  }

  required_version = ">= 1.2.0"
}

variable "region" {
  type        = string
  description = "AWS region to deploy to."
  default     = "eu-central-1"
}

provider "aws" {
  region = var.region
}

variable "gh_access_token" {
  type        = string
  description = "GitHub access token for the repository published to AWS."
  sensitive   = true
}

resource "aws_amplify_app" "frontend" {
  name         = "serverless-todo-www"
  access_token = var.gh_access_token
  build_spec   = file("${path.module}/amplify.yml")
  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }
  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|ttf|map|json)$)([^.]+$)/>"
    status = "200"
    target = "/index.html"
  }
  environment_variables = {
    "AMPLIFY_DIFF_DEPLOY"       = "false"
    "AMPLIFY_MONOREPO_APP_ROOT" = "www"
  }
  repository = "https://github.com/lrosenfeldt/serverless-todo"
}


resource "aws_amplify_branch" "prod_branch" {
  app_id                      = aws_amplify_app.frontend.id
  branch_name                 = "master"
  enable_pull_request_preview = true
  framework                   = "React"
  stage                       = "PRODUCTION"
}

resource "aws_cognito_user_pool" "pool" {
  name = "serverless-todo-pool"
  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection      = "INACTIVE"
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  mfa_configuration = "OFF"
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true
    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }
  username_configuration {
    case_sensitive = false
  }
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  domain       = "serverless-todo"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "pool_client" {
  access_token_validity                = 60
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "aws.cognito.signin.user.admin",
    "profile",
    "email",
    "openid",
    "phone"
  ]
  callback_urls                                 = ["http://localhost:3000/", "http://localhost:8080", "https://${aws_amplify_branch.prod_branch.branch_name}.${aws_amplify_app.frontend.id}.amplifyapp.com"]
  enable_propagate_additional_user_context_data = false
  enable_token_revocation                       = true
  explicit_auth_flows                           = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  generate_secret                               = false
  id_token_validity                             = 60
  logout_urls                                   = []
  name                                          = "serverless-todo-www"
  prevent_user_existence_errors                 = "ENABLED"
  read_attributes = [
    "address",
    "birthdate",
    "email",
    "email_verified",
    "family_name",
    "gender",
    "given_name",
    "locale",
    "middle_name",
    "name",
    "nickname",
    "phone_number",
    "phone_number_verified",
    "picture",
    "preferred_username",
    "profile",
    "updated_at",
    "website",
    "zoneinfo"
  ]
  supported_identity_providers = ["COGNITO"]
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
  user_pool_id = aws_cognito_user_pool.pool.id
  write_attributes = [
    "address",
    "birthdate",
    "email",
    "family_name",
    "gender",
    "given_name",
    "locale",
    "middle_name",
    "name",
    "nickname",
    "phone_number",
    "picture",
    "preferred_username",
    "profile",
    "updated_at",
    "website",
    "zoneinfo"
  ]
}

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

data "archive_file" "lambda_hello" {
  type        = "zip"
  source_dir  = "${path.module}/functions/hello"
  output_path = "${path.module}/hello.zip"
}

resource "aws_s3_object" "lambda_hello" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "hello.zip"
  source = data.archive_file.lambda_hello.output_path
  etag   = filemd5(data.archive_file.lambda_hello.output_path)
}

resource "aws_lambda_function" "hello" {
  function_name    = "Hello"
  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_hello.key
  runtime          = "nodejs14.x"
  handler          = "app.handler"
  source_code_hash = data.archive_file.lambda_hello.output_base64sha256
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

resource "aws_apigatewayv2_integration" "hello" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    = aws_lambda_function.hello.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "hello" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "serverless-todo/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

output "auth_domain" {
  value       = "${aws_cognito_user_pool_domain.pool_domain.domain}.auth.${var.region}.amazoncognito.com"
  description = "URL to request for authentication in the frontend"
}

output "frontend_url" {
  value       = "https://${aws_amplify_branch.prod_branch.branch_name}.${aws_amplify_app.frontend.id}.amplifyapp.com"
  description = "URL to redirect an authenticated user"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.pool_client.id
  description = "Cognito user pool ID"
}

output "function_hello" {
  description = "Name of the hello lambda function."
  value       = aws_lambda_function.hello.function_name
}

output "api_base_url" {
  description = "Base URL for API Gateway stage."
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}
