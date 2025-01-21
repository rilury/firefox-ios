Node.prototype.ownerGlobal = window;

Object.defineProperty(Node.prototype, "flattenedTreeParentNode", {
  get() {
    return this.parentElement ?? null;
  },
  configurable: true,
});

export const Cu = {
  // NOTE(Issam): Is this enough ? Or maybe we can use WeakRefs.
  isDeadWrapper: (node) => !node?.isConnected,
  isInAutomation: false,
};
globalThis.Cu = Cu;

export const setTimeout = globalThis.setTimeout.bind(window);
export const clearTimeout = globalThis.clearTimeout.bind(window);

// TODO(Issam): Implement this for debugging
globalThis.console.createInstance = () => ({
  log: (...whatever) => console.log("createInstance --- ", ...whatever),
  warn: (...whatever) => console.warn("createInstance --- ", ...whatever),
  error: (...whatever) => console.error("createInstance --- ", ...whatever),
});

globalThis.ChromeUtils = globalThis.ChromeUtils || {};
globalThis.ChromeUtils.addProfilerMarker = () => {};

// QUESTION(Issam): It would be better if the code in the engine ingests these as is.
const base64ToArrayBuffer = (base64) => {
  const strippedSignature = base64.replace(
    /^data:application\/wasm;base64,/,
    ""
  );
  const binaryString = atob(strippedSignature);
  const length = binaryString.length;
  const bytes = new Uint8Array(length);
  for (let i = 0; i < length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
};

// NOTE(Issam): Wasm is bundled using webpack. Language models are fetched from swift.
// Is this a good approach ?
export const getAllModels = async (sourceLanguage, targetLanguage) => {
  // NOTE(Issam): Most processing is done in swift. If we manage to accept base64 encoded models
  // Then we can omit the processing here all together.
  // TODO(Issam): models in base64 to array buffer
  // languageModelFiles: {
  //     lex: {buffer: ""}
  //     vocab: {buffer: ""}
  //     model: {buffer: ""}
  // }
  const modelsForLanguagePair =
    await webkit.messageHandlers.translationsBackground.postMessage({
      type: "getModels",
      payload: {
        sourceLanguage,
        targetLanguage,
      },
    });

  const languageModelFiles = modelsForLanguagePair.languageModelFiles;
  for (const model of Object.values(languageModelFiles)) {
    model.buffer = base64ToArrayBuffer(model.buffer);
  }
  return modelsForLanguagePair;
};

globalThis.TE_getLogLevel = () => {};
globalThis.TE_log = (message) => console.log("TE_log ---- ", message);
globalThis.log = (message) => console.log("log ---- ", message);

globalThis.TE_logError = (...error) =>
  console.error("TE_error ---- ", ...error);
globalThis.TE_getLogLevel = () => {};
globalThis.TE_destroyEngineProcess = () => {};
globalThis.TE_requestEnginePayload = async (fromLanguage, toLanguage) => {
  const bergamotTranslator = require("Translations/Wasm/bergamot-translator.wasm");
  const allModels = await getAllModels(fromLanguage, toLanguage);
  return {
    bergamotWasmArrayBuffer: base64ToArrayBuffer(bergamotTranslator),
    translationModelPayloads: [allModels],
    // NOTE(Issam): Only used for testing on Desktop. This should never be true on iOS.
    // Although probably not needed here as undefined is falsy too
    isMocked: false,
  };
};
globalThis.TE_reportEngineStatus = () => {};
globalThis.TE_resolveForceShutdown = () => {};
globalThis.TE_addProfilerMarker = () => {};

// NOTE(Issam): Calling new Worker(url) will cause a security error since we are loading from an unsafe context.
// To bypass this we inline the worker and override the Worker constructor. This way we don't have to touch the shared code.
// We are only calling this to load translations-engine.worker.js for now, so it's hardcoded
const OriginalWorker = globalThis.Worker;
globalThis.Worker = class extends OriginalWorker {
  constructor(url, options) {
    if (url.endsWith("translations-engine.worker.js")) {
      const translationsWorker = require("Assets/CC_Script/translations-engine.worker.js");
      return new translationsWorker();
    }
    return new OriginalWorker(url, options);
  }
};

// NOTE(Issam): importScripts is resolved at runtime which is problematic. The best solution I found for this is to:
// - Override it to use require so webpack can build the deps graph.
// - Use script-loader to expose loadBergamot to the worker since it's not an es module.
globalThis.importScripts = (moduleURI) => {
  const moduleName = moduleURI.split("/").pop();
  require(`script-loader!./${moduleName}`);
};
