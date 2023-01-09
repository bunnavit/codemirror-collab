import React, { useState } from "react";
import { Box, Flex, Text } from "@chakra-ui/react";
import ReactCodeMirror from "@uiw/react-codemirror";

import { getCollabExtensions, getNormalExtensions } from "./collab";
import { EditorView } from "codemirror";
import { SessionMessageHandler, SessionSendHandler } from "../websocket/types";
import { DocConnection } from "../hooks/useDocConnection";

type WsEditorProps = {
  docConnection: DocConnection;
  initialDoc?: string;
  docID?: string;
  version: number;
  setEditorView: (view: EditorView) => void;
  sendMessage: SessionSendHandler;
  onMessage: SessionMessageHandler;
};

export const WsEditor = (props: WsEditorProps) => {
  const {
    docConnection,
    initialDoc,
    docID,
    version,
    setEditorView,
    sendMessage,
    onMessage,
  } = props;

  return (
    <Box>
      {!docID ? (
        <ReactCodeMirror
          height="90vh"
          extensions={getNormalExtensions()}
          onCreateEditor={(view) => {
            setEditorView(view);
          }}
          theme="dark"
          value={initialDoc}
        />
      ) : (
        <ReactCodeMirror
          height="90vh"
          extensions={getCollabExtensions(
            sendMessage,
            onMessage,
            docConnection
          )}
          onCreateEditor={(view) => {
            setEditorView(view);
          }}
          theme="dark"
          value={initialDoc}
        />
      )}
    </Box>
  );
};
