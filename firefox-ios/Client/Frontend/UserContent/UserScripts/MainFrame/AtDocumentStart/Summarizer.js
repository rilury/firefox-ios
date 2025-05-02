/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";
import { isProbablyReaderable, Readability } from "@mozilla/readability";

function readerize() {
  if (isProbablyReaderable()) {
    var uri = {
      spec: document.location.href,
      host: document.location.host,
      prePath: document.location.protocol + "//" + document.location.host, // TODO This is incomplete, needs username/password and port
      scheme: document.location.protocol.substr(0, document.location.protocol.indexOf(":")),
      pathBase:
        document.location.protocol +
        "//" +
        document.location.host +
        location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1),
    };

    // document.cloneNode() can cause the webview to break (bug 1128774).
    // Serialize and then parse the document instead.
    var docStr = new XMLSerializer().serializeToString(document);

    const DOMPurify = require("dompurify");
    const clean = DOMPurify.sanitize(docStr, { WHOLE_DOCUMENT: true });
    var doc = new DOMParser().parseFromString(clean, "text/html");
    var readability = new Readability(uri, doc, { debug: DEBUG });
    readabilityResult = readability.parse();

    // Sanitize the title to prevent a malicious page from inserting HTML in the `<title>`.
    readabilityResult.title = escapeHTML(readabilityResult.title);
    // Sanitize the byline to prevent a malicious page from inserting HTML in the `<byline>`.
    readabilityResult.byline = escapeHTML(readabilityResult.byline);
    console.log("readabilityResult", readabilityResult);
    return readabilityResult.textContent ?? readabilityResult.content;
  }
}

Object.defineProperty(window.__firefox__, "summarizer", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze({
    readerize: readerize,
  }),
});
