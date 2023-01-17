import config from "./config";

const http = (path: string, init?: RequestInit) => {
  const url = new URL(
    `serverless_lambda_stage/${path.startsWith("/") ? path.slice(1) : path}`,
    config.api_base_url
  );
  return fetch(url, init);
};

export type HelloResponse = {
  message: string;
  timestamp: number;
};
export async function hello() {
  try {
    const response = await http("/hello", { mode: "cors", method: "GET" });
    const data: HelloResponse = await response.json();
    return {
      message: data.message,
      date: new Date(data.timestamp),
    };
  } catch (err) {
    console.error(err);
    return null;
  }
}

export type DowngradeResponse =
  | {
      success: false;
      message: string;
    }
  | {
      success: true;
      css: string;
    };
export async function downgradeCss(css: string) {
  try {
    const headers = new Headers();
    headers.append("content-type", "application/json");
    const response = await http("/downgrade-css", {
      method: "POST",
      headers,
      mode: "cors",
      body: JSON.stringify({ css }),
    });
    const data: DowngradeResponse = await response.json();
    if (!data.success) throw new Error(data.message);
    return {
      input: css,
      output: data.css,
    };
  } catch (err) {
    console.error(err);
    return null;
  }
}
