
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
