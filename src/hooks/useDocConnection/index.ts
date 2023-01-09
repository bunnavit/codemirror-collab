import { receiveUpdates } from "@codemirror/collab";
import { ChangeSet } from "@codemirror/state";
import { EditorView } from "codemirror";
import { useCallback, useEffect, useState } from "react";

export type DocResponse = {
  connectionId?: string;
  connectionID?: string;
  docID?: string;
  reqType?: string;
  statusCode?: number;
  message?: string;
  doc?: string;
  version?: number;
  updates?: string;
};

export type DocConnection = {
  editorView?: EditorView;
  connectionID?: string;
  docID?: string;
  doc?: string;
  version?: number;
  setEditorView: (view: EditorView) => void;
  updateDoc: (resp: DocResponse) => void;
  disconnectDoc: () => void;
};

export const useDocConnection = (): DocConnection => {
  const [editorView, setEditorView] = useState<EditorView>();
  const [connectionID, setConnectionID] = useState<string>();
  const [docID, setDocID] = useState<string>();
  const [doc, setDoc] = useState<string>();
  const [version, setVersion] = useState<number>();

  const updateDoc = useCallback(
    (resp: DocResponse) => {
      const {
        connectionID,
        connectionId,
        docID,
        reqType,
        statusCode,
        message,
        doc,
        version,
        updates,
      } = resp;
      // should fix inconsistent naming
      if (connectionID) setConnectionID(connectionID);
      if (connectionId) setConnectionID(connectionId);
      if (doc) setDoc(doc);
      if (docID) setDocID(docID);
      if (version) setVersion(version);

      // on update
      if (updates) {
        console.log("receving updates", resp);
        // TODO: fix types
        const formattedUpdates = JSON.parse(updates).map((u: any) => {
          return {
            changes: ChangeSet.fromJSON(u.changes),
            clientID: u.connectionID,
          };
        });
        editorView?.dispatch(
          receiveUpdates(editorView.state, formattedUpdates)
        );
      }
    },
    [editorView]
  );

  useEffect(() => {
    setDoc(editorView?.state.doc.sliceString(0));
  }, [editorView]);

  const disconnectDoc = useCallback(() => {
    setConnectionID(undefined);
    setDocID(undefined);
    setDoc(undefined);
    setVersion(undefined);
  }, []);

  return {
    editorView,
    connectionID,
    docID,
    doc,
    version,
    setEditorView,
    updateDoc,
    disconnectDoc,
  };
};
