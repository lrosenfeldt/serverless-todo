// You can obtain these values by running:
// aws cloudformation describe-stacks --stack-name <YOUR STACK NAME> --query "Stacks[0].Outputs[]"

const config = {
  aws_user_pools_web_client_id: "36na2ssttoh62lt13r3d36e29f", // CognitoClientID
  api_base_url:
    "https://wykyzwln7h.execute-api.eu-central-1.amazonaws.com/serverless_lambda_stage", // TodoFunctionApi
  cognito_hosted_domain: "serverless-todo.auth.eu-central-1.amazoncognito.com", // CognitoDomainName
  redirect_url: "https://master.d1pka7or1wopsp.amplifyapp.com", // AmplifyURL
} as const;

export default config;
