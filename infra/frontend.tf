variable "gh_access_token" {
  type        = string
  description = "GitHub Access Token for the serverless-todo repo"
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
