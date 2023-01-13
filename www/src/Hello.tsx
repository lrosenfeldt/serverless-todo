import { useState } from "react";
import { Container } from "reactstrap";

const Hello: React.FC<{}> = function () {
  const [message, setMessage] = useState("Loading");

  return (
    <Container>
      <h1>Welcome to the App</h1>
      <p>{message}</p>
    </Container>
  );
};
export default Hello;
