
output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.pool_client.id
  description = "Cognito user pool ID"
}

output "function_names" {
  description = "Name of the deployed lambda functions."
  value       = [for k, v in var.endpoints : aws_lambda_function.lambda[k].function_name]
}
output "api_base_url" {
  description = "Base URL for API Gateway stage."
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}

output "auth_domain" {
  value       = "${aws_cognito_user_pool_domain.pool_domain.domain}.auth.${var.region}.amazoncognito.com"
  description = "URL to request for authentication in the frontend"
}

output "frontend_url" {
  value       = "https://${aws_amplify_branch.prod_branch.branch_name}.${aws_amplify_app.frontend.id}.amplifyapp.com"
  description = "URL to redirect an authenticated user"
}
