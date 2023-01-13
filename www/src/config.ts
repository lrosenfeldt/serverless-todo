// You can obtain these values by running:
// aws cloudformation describe-stacks --stack-name <YOUR STACK NAME> --query "Stacks[0].Outputs[]"

const config = {
  aws_user_pools_web_client_id: "7c0fpv5f41aeup265325thsq73", // CognitoClientID
  api_base_url:
    "https://2w2fhl3gu0.execute-api.eu-central-1.amazonaws.com/serverless_lambda_stage", // TodoFunctionApi
  cognito_hosted_domain: "serverless-todo.auth.eu-central-1.amazoncognito.com", // CognitoDomainName
  redirect_url: "https://master.d7dy61m1sol1h.amplifyapp.com", // AmplifyURL
} as const;

export default config;
