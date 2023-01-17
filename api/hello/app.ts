import { APIGatewayEvent, APIGatewayProxyResultV2 } from "aws-lambda";

export async function handler(
  event: APIGatewayEvent
): Promise<APIGatewayProxyResultV2> {
  console.log("Event: ", event);
  const message = "Hello, World!";
  const timestamp = Date.now();

  return {
    statusCode: 200,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      message,
      timestamp,
    }),
  };
}
