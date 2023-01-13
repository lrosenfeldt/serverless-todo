// You can obtain these values by running:
// aws cloudformation describe-stacks --stack-name <YOUR STACK NAME> --query "Stacks[0].Outputs[]"

const config = {
  aws_user_pools_web_client_id: "63r3tb0hlr658ccc237h4421im", // CognitoClientID
  api_base_url: "None", // TodoFunctionApi
  cognito_hosted_domain: "serverless-todo.auth.eu-central-1.amazoncognito.com", // CognitoDomainName
  redirect_url: "https://master.d2h5jfasl3mgxo.amplifyapp.com", // AmplifyURL
};

export default config;
