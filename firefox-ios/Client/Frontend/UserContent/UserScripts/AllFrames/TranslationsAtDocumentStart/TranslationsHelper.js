import "resource://gre/modules/shared/Helpers.ios.mjs";
import "resource://gre/modules/shared/TranslationsHelpers.ios.mjs";

import {
  LRUCache,
  TranslationsDocument,
} from "Assets/CC_Script/translations-document.sys.mjs";
import "Assets/CC_Script/translations-engine.sys.mjs";

// Hardcoding for now just to demo things
const fromLanguage = "en";
const toLanguage = "fr";
const innerWindowId = crypto.randomUUID();
const translationsCache = new LRUCache(fromLanguage, toLanguage);

// Don't care about this for now
const translationsStart = performance.now();

// QUESTION(ISSAM): we need to do something with port1 ????
const { port1, port2 } = new MessageChannel();

port1.onmessage = (message) => {
  const payload = {
    ...message.data,
    fromLanguage,
    toLanguage,
    innerWindowId,
  };

  window.webkit.messageHandlers.translations.postMessage({
    type: "port",
    payload,
  });
};

window.forwardMessageToContent = (message) => {
  console.log("%%%%%% ---- ", message);
  port1.postMessage(message);
};

// ISSAM: DOMContentLoaded might be enough though ?
document.addEventListener("startEverything", () => {
  if (document.readyState === "complete") {
    const translatedDoc = new TranslationsDocument(
      document,
      fromLanguage,
      toLanguage,
      innerWindowId,
      port2,
      () => console.log("foooo 1"),
      () => console.log("foooo 2"),
      translationsStart,
      () => performance.now(),
      translationsCache
    );

    const message = {
      type: "StartTranslation",
      fromLanguage,
      toLanguage,
      innerWindowId,
      // port: port1,
      // TODO(Issam): We can't serialize this for now and webkit postMessage has no transferables
    };

    console.log(";;;;;; ---- this 1", message);
    window.webkit.messageHandlers.translations.postMessage({
      type: "background",
      payload: message,
    });
  }
});
