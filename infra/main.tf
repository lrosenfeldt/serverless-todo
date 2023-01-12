terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
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


resource "aws_amplify_branch" "frontend_amplify_branch" {
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
  deletion_protection = "INACTIVE"
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
  username_attributes = ["email"]
  username_configuration {
    case_sensitive = false
  }
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  domain       = aws_amplify_app.frontend.id
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "pool_client" {
  access_token_validity                = 60
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "email",
    "openid",
    "phone"
  ]
  callback_urls                                 = ["https://${aws_amplify_branch.frontend_amplify_branch.branch_name}.${aws_amplify_app.frontend.id}.amplifyapp.com", "http://localhost:8080", "http://localhost:3000"]
  enable_propagate_additional_user_context_data = false
  enable_token_revocation                       = true
  explicit_auth_flows                           = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  generate_secret                               = false
  id_token_validity                             = 60
  logout_urls                                   = []
  name                                          = aws_amplify_app.frontend.name
  prevent_user_existence_errors                 = "ENABLED"
  read_attributes                               = ["email", "email_verified", "name"]
  supported_identity_providers                  = ["COGNITO"]
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
  user_pool_id     = aws_cognito_user_pool.pool.id
  write_attributes = ["email"]
}

output "auth_domain" {
  value       = "${aws_cognito_user_pool_domain.pool_domain.domain}.auth.${var.region}.amazoncognito.com"
  description = "URL to request for authentication in the frontend"
}

output "frontend_url" {
  value       = "https://${aws_amplify_branch.frontend_amplify_branch.branch_name}.${aws_amplify_app.frontend.id}.amplifyapp.com"
  description = "URL to redirect an authenticated user"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.pool_client.id
  description = "Cognito user pool ID"
}
