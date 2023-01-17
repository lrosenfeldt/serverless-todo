import React, { useState, useEffect } from "react";
import { Container, Jumbotron, Row, Col, Alert, Button } from "reactstrap";
import axios from "axios";

import "./App.css";
import logo from "./assets/aws.png";

import config from "./config";
import Todo from "./Todo";

function App() {
  const [alert, setAlert] = useState("");
  const [alertStyle, setAlertStyle] = useState("info");
  const [alertVisible, setAlertVisible] = useState(false);
  const [alertDismissable, setAlertDismissable] = useState(false);
  const [idToken, setIdToken] = useState("");
  const [toDos, setToDos] = useState([]);

  useEffect(() => {
    getIdToken();
    if (idToken.length > 0) {
      getAllTodos();
    }
  }, [idToken]);

  axios.interceptors.response.use(
    (response) => {
      console.log("Response was received");
      return response;
    },
    (error) => {
      window.location.href = config.redirect_url;
      return Promise.reject(error);
    }
  );

  function onDismiss() {
    setAlertVisible(false);
  }

  const clearCredentials = () => {
    window.location.href = config.redirect_url;
  };

  const getIdToken = () => {
    const hash = window.location.hash.substring(1);
    const objects = hash.split("&");
    objects.forEach((object) => {
      const keyVal = object.split("=");
      if (keyVal[0] === "id_token") {
        setIdToken(keyVal[1]);
      }
    });
  };

  const getAllTodos = async () => {
    const result = await axios({
      url: `${config.api_base_url}/item/`,
      headers: {
        Authorization: idToken,
      },
    }).catch((error) => {
      console.log(error);
    });

    console.log(result);

    if (result && result.status === 401) {
      clearCredentials();
    } else if (result && result.status === 200) {
      console.log(result.data.Items);
      setToDos(result.data.Items);
    }
  };

  return (
    <div className="App">
      <Container>
        <Alert
          color={alertStyle}
          isOpen={alertVisible}
          toggle={alertDismissable ? onDismiss : undefined}
        >
          <p dangerouslySetInnerHTML={{ __html: alert }}></p>
        </Alert>
        <Jumbotron>
          <Row>
            <Col md="6" className="logo">
              <h1>Serverless Todo</h1>
              <p>This is a demo that showcases AWS serverless.</p>
              <p>
                The application is built using the SAM CLI toolchain, and uses
                AWS Lambda, Amazon DynamoDB, and Amazon API Gateway for API
                services and Amazon Cognito for identity.
              </p>

              <img src={logo} alt="Logo" />
            </Col>
            <Col md="6">
              <Todo />
              {/* {idToken.length > 0 ? (
                <Todo />
              ) : (
                <Button
                  href={`https://${config.cognito_hosted_domain}/login?response_type=token&client_id=${config.aws_user_pools_web_client_id}&redirect_uri=${config.redirect_url}`}
                  color="primary"
                  className="mt-5 float-center"
                >
                  Log In
                </Button>
              )} */}
            </Col>
          </Row>
        </Jumbotron>
      </Container>
    </div>
  );
}

export default App;
