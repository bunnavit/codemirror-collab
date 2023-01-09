import React, { useState } from "react";
import {
  Button,
  ButtonGroup,
  Flex,
  Grid,
  GridItem,
  Input,
  Stack,
  Text,
} from "@chakra-ui/react";

import { Editor } from "./Editor";
import { ChangeSet } from "@codemirror/state";
import { receiveUpdates, Update } from "@codemirror/collab";
import { useSession } from "./websocket";
import { Data, Message } from "./websocket/types";
import { WsEditor } from "./WsEditor";
import { EditorView } from "codemirror";
import { useDocConnection } from "./hooks/useDocConnection";

type Response = {
  connectionId?: string;
  connectionID?: string;
  docID?: string;
  reqType?: string;
  statusCode?: number;
  message?: string;
  doc?: string;
  version?: number;
};

function App() {
  const [ws, setWs] = useState<WebSocket>();
  const [isConnecting, setIsConnecting] = useState(false);
  const [docIDInput, setDocIDInput] = useState<string>();

  const docConnection = useDocConnection();

  const {
    connectionID,
    docID,
    doc,
    version,
    editorView,
    setEditorView,
    updateDoc,
    disconnectDoc,
  } = docConnection;

  const onOpen = (e: Event) => {
    console.log("open", e);
    if (e.type === "open") {
      setWs(e.currentTarget as WebSocket);
      sendError();
      setIsConnecting(false);
    }
  };

  const onClose = (e: Event) => {
    console.log("close", e);
    if (e.type === "close") {
      setWs(undefined);
      disconnectDoc();
    }
  };

  const onMessage = (e: MessageEvent) => {
    console.log("message", e);
    const data: Response = JSON.parse(e.data);
    updateDoc(data);
    // this.view.dispatch(receiveUpdates(this.view.state, updates));
    if (!data) return;
  };

  const [connect, sendMessage, sendError, close] = useSession(
    onOpen,
    onMessage,
    onClose
  );

  const handleConnect = () => {
    setIsConnecting(true);
    connect();
    // TODO: do some request handling to set isConnecting to false i guess (timeout maybe)
  };

  const handleCreate = () => {
    const currentDoc = editorView?.state.doc;
    if (!currentDoc) return;
    const data: Data = {
      reqType: "create",
      connectionID,
      doc: currentDoc,
    };
    sendMessage(data);
  };

  const handleSubscribe = () => {
    if (!docIDInput) return;
    const data: Data = {
      reqType: "subscribe",
      connectionID,
      docID: docIDInput,
    };
    sendMessage(data);
  };

  return (
    <Grid
      height="100vh"
      width="100vw"
      templateColumns="repeat(4,1fr)"
      templateRows="repeat(1,1fr)"
    >
      <GridItem rowSpan={1} colSpan={3} m={10}>
        <WsEditor
          docConnection={docConnection}
          setEditorView={setEditorView}
          initialDoc={doc}
          docID={docID}
          // TODO: should not happen (but should refactor(type guard maybe))
          version={version!}
          sendMessage={sendMessage}
          onMessage={onMessage}
        />
      </GridItem>
      <GridItem rowSpan={1} colSpan={1} m={10}>
        <Stack alignItems="center" gap="6">
          <Text>connectionID: {connectionID ?? "undefined"}</Text>
          <Text>documentID: {docID ?? undefined} </Text>
          <Stack spacing="6">
            <Button
              disabled={!!ws}
              onClick={handleConnect}
              isLoading={isConnecting}
            >
              Connect to server
            </Button>
            <Button disabled={!ws} onClick={close}>
              Disconnect
            </Button>
            <Button disabled={!ws} onClick={handleCreate}>
              Create document
            </Button>
            <Flex>
              <Input
                disabled={!ws}
                placeholder="documentId"
                onChange={(e) => {
                  setDocIDInput(e.target.value);
                }}
                mr={4}
              />
              <Button disabled={!ws || !!docID} onClick={handleSubscribe}>
                Connect
              </Button>
            </Flex>
          </Stack>
        </Stack>
      </GridItem>
    </Grid>
  );
}

export default App;
