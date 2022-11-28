import { Grid, GridItem } from "@chakra-ui/react";
import React from "react";
import { Editor } from "./Editor";
import { ChangeSet, Text } from "@codemirror/state";
import { Update } from "@codemirror/collab";

function App() {
  return (
    <Grid
      height="100vh"
      width="100vw"
      templateColumns="repeat(1,1fr)"
      templateRows="repeat(1,1fr)"
    >
      <GridItem rowSpan={1} colSpan={1}>
        <Editor />
      </GridItem>
    </Grid>
  );
}

export default App;
