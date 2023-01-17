import React, { useEffect, useState } from "react";
import { Button, Container } from "reactstrap";
import * as api from "./api";

const Hello: React.FC<{}> = function () {
  const [message, setMessage] = useState("Loading...");
  const [inputCss, setInputCss] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [outputCss, setOutputCss] = useState("");

  useEffect(() => {
    const getData = async () => {
      const res = await api.hello();
      if (!res) {
        setMessage("Failed to get message :(");
        return;
      }
      setMessage(`${res.date.toLocaleDateString()}: ${res.message}`);
    };
    getData();
  }, []);

  const onSubmit = async (ev: React.FormEvent<HTMLFormElement>) => {
    ev.preventDefault();
    if (isSubmitting) return;
    setIsSubmitting(true);
    const res = await api.downgradeCss(inputCss);
    if (!res) {
      setOutputCss("Failed :(");
      setIsSubmitting(false);
      return;
    }
    setOutputCss(res.output);
    setIsSubmitting(false);
  };

  return (
    <Container>
      <h1>Welcome to the App</h1>
      <p>{message}</p>
      <form onSubmit={onSubmit}>
        <div style={{ display: "flex", flexDirection: "column" }}>
          <label htmlFor="input-css">Input CSS</label>
          <textarea
            style={{ height: "10rem" }}
            value={inputCss}
            onChange={(ev) => setInputCss(ev.target.value)}
            id="input-css"
          />
        </div>
        <div style={{ display: "flex", flexDirection: "column" }}>
          <label htmlFor="output-css">output CSS</label>
          <textarea
            style={{ height: "10rem" }}
            value={outputCss}
            onChange={(ev) => setOutputCss(ev.target.value)}
            id="output-css"
          />
        </div>
        <Button type="submit" className="my-4">
          Submit
        </Button>
      </form>
    </Container>
  );
};
export default Hello;
