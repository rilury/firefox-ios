import "Assets/CC_Script/TranslationsHelpers.ios.mjs";
import "Assets/CC_Script/translations-engine.sys.mjs";

const { port1, port2 } = new MessageChannel();

port2.onmessage = (message) => {
  webkit.messageHandlers.translationsBackground.postMessage({
    type: "forward",
    payload: message.data,
  });
};

const portPostMessage = (message) => port2.postMessage(message);
window.portPostMessage = portPostMessage;

const backgroundPostMessage = (message) => {
  const transferables = [port1];
  window.postMessage({ ...message, port: port1 }, "*", transferables);
};
window.backgroundPostMessage = backgroundPostMessage;
