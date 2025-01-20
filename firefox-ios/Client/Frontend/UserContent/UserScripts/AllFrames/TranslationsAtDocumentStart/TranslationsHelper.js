import "resource://gre/modules/shared/Helpers.ios.mjs";
import "resource://gre/modules/shared/TranslationsHelpers.ios.mjs";

import {LRUCache,TranslationsDocument} from "Assets/CC_Script/translations-document.sys.mjs";
import "Assets/CC_Script/translations-engine.sys.mjs";

// Hardcoding for now just to demo things
const fromLanguage = "en";
const toLanguage = "fr";
// Only used as a marker for profiling ( we can add some id logic later if we want profiling  )
const  innerWindowId = 989489489484;
const translationsCache = new LRUCache(fromLanguage, toLanguage);

// Don't care about this for now
const translationsStart = performance.now();

// QUESTION(ISSAM): we need to do something with port1 ????
const { port1, port2 } = new MessageChannel();


// ISSAM: DOMContentLoaded might be enough though ?
document.addEventListener("startEverything", () => {
  console.log("oooooooo ---- -startEverything");
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

    const transferables = [port1];
    const message = {
      type: "StartTranslation",
      fromLanguage,
      toLanguage,
      innerWindowId,
      port: port1,
    };
    window.postMessage(message, "*", transferables);
  }
});