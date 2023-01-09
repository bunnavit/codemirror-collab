export type SessionConnectHandler = (ev: Event) => any;
export type SessionMessageHandler = (ev: MessageEvent<any>) => any;
export type SessionDisconnectHandler = (ev: Event) => any;
export type SessionSendHandler = (args: Data) => any;

export type Operation = "add" | "delete" | "update";

export interface BaseMessage {
  action: "sendmessage";
}

export const BASE_MESSAGE: BaseMessage = {
  action: "sendmessage",
};

// temporary
export type Message = {
  action: "sendmessage";
  data: Object;
};

export type Data = Object;

export type ConnectFN = () => void;

export type SessionHook = [
  ConnectFN,
  (args: Data) => void,
  () => void,
  () => void
];
export type PauseHandlerHook = [(fn: ConnectFN) => void, () => void];
