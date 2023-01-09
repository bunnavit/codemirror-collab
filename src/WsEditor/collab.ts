import {
  sendableUpdates,
  getSyncedVersion,
  Update,
  receiveUpdates,
  collab,
} from "@codemirror/collab";
import { ChangeSet, Extension } from "@codemirror/state";
import { ViewPlugin, ViewUpdate } from "@codemirror/view";
import { basicSetup } from "@uiw/react-codemirror";
import { EditorView } from "codemirror";
import { DocConnection } from "../hooks/useDocConnection";
import { SessionMessageHandler, SessionSendHandler } from "../websocket/types";

function peerExtension(
  docConnection: DocConnection,
  sendMessage: SessionSendHandler
) {
  const { version, connectionID, docID } = docConnection;
  let plugin = ViewPlugin.fromClass(
    class {
      private pushing = false;
      private done = false;

      constructor(private view: EditorView) {
        // this.pull();
      }

      update(update: ViewUpdate) {
        console.log("updating");
        if (update.docChanged) {
          console.log("pushing", update);
          this.push();
        }
      }

      async push() {
        console.log("pushing");
        const updates = sendableUpdates(this.view.state);
        const formattedUpdates = updates.map((u: Update) => {
          const { changes, clientID } = u;
          return {
            changes,
            connectionID: clientID,
          };
        });
        if (this.pushing || !updates.length) return;
        this.pushing = true;
        let syncVersion = getSyncedVersion(this.view.state);
        sendMessage({
          reqType: "push",
          connectionID,
          docID,
          version: syncVersion,
          updates: formattedUpdates,
        });
        // await pushUpdates(connection, version, updates);
        this.pushing = false;
        // Regardless of whether the push failed or new updates came in
        // while it was running, try again if there's updates remaining
        if (sendableUpdates(this.view.state).length) {
          setTimeout(() => this.push(), 600);
        }
      }

      // async pull() {
      //   while (!this.done) {
      //     let version = getSyncedVersion(this.view.state);
      //     let updates: readonly Update[] = [];
      //     // let updates = await pullUpdates(connection, version);
      //     this.view.dispatch(receiveUpdates(this.view.state, updates));
      //   }
      // }

      destroy() {
        this.done = true;
      }
    }
  );
  return [collab({ startVersion: version, clientID: connectionID }), plugin];
}

export const getCollabExtensions = (
  sendMessage: SessionSendHandler,
  onMessage: SessionMessageHandler,
  docConnection: DocConnection
): Extension[] => {
  const extensions: Extension[] = [
    ...basicSetup(),
    peerExtension(docConnection, sendMessage),
  ];
  return extensions;
};

export const getNormalExtensions = (): Extension[] => {
  return basicSetup();
};
