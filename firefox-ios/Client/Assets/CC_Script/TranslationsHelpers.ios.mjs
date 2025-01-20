import bergamotTranslator from "Translations/Wasm/bergamot-translator.wasm";
// NOTE(Issam): It's better if we pass this via swift :) Ignoring for now.
// import translationModels from "Assets/RemoteSettingsData/TranslationModels.json";

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
});
globalThis.Cu = Cu;

export const setTimeout = globalThis.setTimeout.bind(window);
export const clearTimeout = globalThis.clearTimeout.bind(window);

const base64ToArrayBuffer = (base64) => {
  const strippedSignature = base64.replace(
    /^data:application\/octet-stream;base64,/,
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
  //   const modelsContext = require.context(
  //     "Translations/Models",
  //     false,
  //     /\.(bin|spm)$/
  //   );

  // NOTE(Issam): We can do all processing in swift
  const modelsForLanguagePair =
    await webkit.messageHandlers.translations.postMessage({
      action: "getModels",
      payload: {
        sourceLanguage,
        targetLanguage,
      },
    });

  return modelsForLanguagePair;
  //   const results = {};

  //   modelsForLanguagePair.forEach((model) => {
  //     const modelRawString = modelsContext(`./${model.attachment.filename}`);
  //     results[model.fileType] = {
  //       buffer: base64ToArrayBuffer(modelRawString),
  //       record: model,
  //     };
  //   });

  //   return {
  //     languageModelFiles: results,
  //     sourceLanguage: sourceLanguage,
  //     targetLanguage: targetLanguage,
  //   };
};

window.TE_getLogLevel = () => {};
window.TE_log = (message) => console.log("TE_log ---- ", message);
window.log = (message) => console.log("log ---- ", message);

window.TE_logError = (message) => console.error("TE_error ---- ", message);
window.TE_getLogLevel = () => {};
window.TE_destroyEngineProcess = () => {};
window.TE_requestEnginePayload = async (fromLanguage, toLanguage) => {
  const allModels = await getAllModels(fromLanguage, toLanguage);
  return {
    bergamotWasmArrayBuffer: base64ToArrayBuffer(bergamotTranslator),
    translationModelPayloads: [allModels],
    // NOTE(Issam): Only used for testing on Desktop. This should never be true on iOS.
    // Although probably not needed here as undefined is falsy too
    isMocked: false,
  };
};
window.TE_reportEngineStatus = () => {};
window.TE_resolveForceShutdown = () => {};
window.TE_addProfilerMarker = () => {};
