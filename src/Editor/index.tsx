import React, { useEffect, useRef } from "react";
import { EditorView, basicSetup } from "codemirror";
import { createWorkerFactory } from "@shopify/react-web-worker";
import { addPeer } from "./collab";

const createWorker = createWorkerFactory(() => import("./worker"));

export const Editor = () => {
  const worker = createWorker();

  useEffect(() => {
    const asyncing = async () => {};
    asyncing();
  }, [worker]);

  const viewRef = useRef<EditorView>(
    new EditorView({
      doc: "hello",
      extensions: [
        basicSetup,
        EditorView.theme({
          "&": { height: "200px" },
          ".cm-scroller": { overflow: "auto" },
        }),
      ],
    })
  );

  const editorRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fetchPeer = async () => {
      if (editorRef.current) {
        editorRef.current.appendChild(viewRef.current.dom);
      }
    };
    fetchPeer();
  }, []);

  return (
    <div>
      <input id="latency" defaultValue={400}></input>
      <button
        onClick={() => {
          addPeer();
        }}
      >
        Add peer
      </button>
      <div id="editors"></div>
    </div>
  );
};
