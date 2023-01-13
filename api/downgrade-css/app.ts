import { APIGatewayEvent, APIGatewayProxyResultV2 } from "aws-lambda";
import { Processor } from "postcss";
import presetEnvPlugin = require("postcss-preset-env");

function validate(
  body: string
): { err: true; body: null } | { err: false; body: { css: string } } {
  try {
    const asJson = JSON.parse(body);
    if (typeof asJson === "object" && asJson !== null) {
      if (asJson.css && typeof asJson.css === "string") {
        const parsedBody = asJson as { css: string; [key: string]: unknown };
        return {
          err: false,
          body: {
            css: parsedBody.css,
          },
        };
      }
    }
  } catch (error) {
    console.error("Error::InvalidBody: ", body);
    return {
      err: true,
      body: null,
    };
  }
}

export async function handler(
  event: APIGatewayEvent
): Promise<APIGatewayProxyResultV2> {
  console.log("Event: ", event);
  // validate body
  const { err, body } = validate(event.body);
  if (err) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        success: false,
        message: "malformatted body",
      }),
    };
  }
  const postcss = new Processor([presetEnvPlugin({ stage: 0 })]);
  try {
    const styles = await postcss.process(body.css);

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        css: styles.css,
      }),
    };
  } catch (_err) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        success: false,
        message: "css not parseable",
      }),
    };
  }
}
