import { APIGatewayEvent, APIGatewayProxyResultV2 } from "aws-lambda";

export async function handler(
  event: APIGatewayEvent
): Promise<APIGatewayProxyResultV2> {
  console.log("Event: ", event);
  const message = "Hello, World!";
  const timestamp = Date.now();

  return {
    statusCode: 200,
    body: JSON.stringify({
      message,
      timestamp,
    }),
  };
}
