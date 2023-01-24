import { useCallback, useEffect, useState } from "react";
import {
  SessionConnectHandler,
  SessionDisconnectHandler,
  SessionHook,
  SessionMessageHandler,
  Data,
  Message,
} from "./types";

export function useSession(
  onOpen: SessionConnectHandler,
  onMessage: SessionMessageHandler,
  onClose: SessionDisconnectHandler
): SessionHook {
  const [session, setSession] = useState(null as unknown as WebSocket);

  const updateOpenHandler = () => {
    if (!session) return;
    session.addEventListener("open", onOpen);
    return () => {
      session.removeEventListener("open", onOpen);
    };
  };

  const updateMessageHandler = () => {
    if (!session) return;
    session.addEventListener("message", onMessage);
    return () => {
      session.removeEventListener("message", onMessage);
    };
  };

  const updateCloseHandler = () => {
    if (!session) return;
    session.addEventListener("close", onClose);
    return () => {
      session.removeEventListener("close", onClose);
    };
  };

  useEffect(updateOpenHandler, [session, onOpen]);
  useEffect(updateMessageHandler, [session, onMessage]);
  useEffect(updateCloseHandler, [session, onClose]);

  const connect = useCallback(() => {
    const uri = "wss://37lrljvw89.execute-api.us-west-1.amazonaws.com/prod";
    const ws = new WebSocket(uri);
    setSession(ws);
  }, []);

  const sendMessage = (args: Data) => {
    const message: Message = {
      action: "sendmessage",
      data: JSON.stringify(args),
    };
    session.send(JSON.stringify(message));
  };

  const sendError = () => {
    session.send("test");
  };

  const close = useCallback(() => {
    if (session.readyState === session.OPEN) session.close();
  }, [session]);

  return [connect, sendMessage, sendError, close];
}
