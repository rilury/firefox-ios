!function(e){var n={};function t(r){if(n[r])return n[r].exports;var o=n[r]={i:r,l:!1,exports:{}};return e[r].call(o.exports,o,o.exports,t),o.l=!0,o.exports}t.m=e,t.c=n,t.d=function(e,n,r){t.o(e,n)||Object.defineProperty(e,n,{enumerable:!0,get:r})},t.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},t.t=function(e,n){if(1&n&&(e=t(e)),8&n)return e;if(4&n&&"object"==typeof e&&e&&e.__esModule)return e;var r=Object.create(null);if(t.r(r),Object.defineProperty(r,"default",{enumerable:!0,value:e}),2&n&&"string"!=typeof e)for(var o in e)t.d(r,o,function(n){return e[n]}.bind(null,o));return r},t.n=function(e){var n=e&&e.__esModule?function(){return e.default}:function(){return e};return t.d(n,"a",n),n},t.o=function(e,n){return Object.prototype.hasOwnProperty.call(e,n)},t.p="",t(t.s=4)}([,,,,function(e,n,t){t(5),t(6),t(7),t(8),t(9),e.exports=t(10)},function(e,n,t){"use strict";window.__firefox__||Object.defineProperty(window,"__firefox__",{enumerable:!1,configurable:!1,writable:!1,value:{userScripts:{},includeOnce:function(e,n){return!!__firefox__.userScripts[e]||(__firefox__.userScripts[e]=!0,"function"==typeof n&&n(),!1)}}})},function(e,n,t){"use strict";window.__firefox__.includeOnce("ContextMenu",function(){window.addEventListener("touchstart",function(e){var n=e.target,t=n.closest("a"),r=n.closest("img");if(t||r){var o={};t&&(o.link=t.href,o.title=t.title),r&&(o.image=r.src,o.title=r.title||o.title,o.alt=r.alt),(o.link||o.image)&&webkit.messageHandlers.contextMenuMessageHandler.postMessage(o)}},!0)})},function(e,n,t){"use strict";Object.defineProperty(window.__firefox__,"download",{enumerable:!1,configurable:!1,writable:!1,value:function(e,n){if(n===SECURITY_TOKEN){if(e.startsWith("blob:")){var t=new XMLHttpRequest;return t.open("GET",e,!0),t.responseType="blob",t.onload=function(){if(200===this.status){var n=function(e){return e.split("/").pop()}(e),t=this.response;!function(e,n){var t=new FileReader;t.onloadend=function(){n(this.result.split(",")[1])},t.readAsDataURL(e)}(t,function(e){webkit.messageHandlers.downloadManager.postMessage({filename:n,mimeType:t.type,size:t.size,base64String:e})})}},void t.send()}var r=document.createElement("a");r.href=e,r.dispatchEvent(new MouseEvent("click"))}}})},function(e,n,t){"use strict";window.__firefox__.includeOnce("FocusHelper",function(){var e=function(e){var n=e.type,t=e.target.nodeName;("INPUT"===t||"TEXTAREA"===t||e.target.isContentEditable)&&(function(e){if("INPUT"!==e.nodeName)return!1;var n=e.type.toUpperCase();return"BUTTON"==n||"SUBMIT"==n||"FILE"==n}(e.target)||webkit.messageHandlers.focusHelper.postMessage({eventType:n,elementType:t}))},n={capture:!0,passive:!0},t=window.document.body;["focus","blur"].forEach(function(r){t.addEventListener(r,e,n)})})},function(e,n,t){"use strict";var r=function(e,n){if(Array.isArray(e))return e;if(Symbol.iterator in Object(e))return function(e,n){var t=[],r=!0,o=!1,i=void 0;try{for(var s,a=e[Symbol.iterator]();!(r=(s=a.next()).done)&&(t.push(s.value),!n||t.length!==n);r=!0);}catch(e){o=!0,i=e}finally{try{!r&&a.return&&a.return()}finally{if(o)throw i}}return t}(e,n);throw new TypeError("Invalid attempt to destructure non-iterable instance")};window.__firefox__.includeOnce("LoginsHelper",function(){var e=!1;function n(n){e&&alert(n)}var t={_getRandomId:function(){return Math.round(Math.random()*(Number.MAX_VALUE-Number.MIN_VALUE)+Number.MIN_VALUE).toString()},_messages:["RemoteLogins:loginsFound"],_requests:{},_takeRequest:function(e){var n=e,t=this._requests[n.requestId];return this._requests[n.requestId]=void 0,t},_sendRequest:function(e,n){var t=this._getRandomId();n.requestId=t,webkit.messageHandlers.loginsManagerMessageHandler.postMessage(n);var r=this;return new Promise(function(n,o){e.promise={resolve:n,reject:o},r._requests[t]=e})},receiveMessage:function(e){var n=this._takeRequest(e);switch(e.name){case"RemoteLogins:loginsFound":n.promise.resolve({form:n.form,loginsFound:e.logins});break;case"RemoteLogins:loginsAutoCompleted":n.promise.resolve(e.logins)}},_asyncFindLogins:function(e,n){var t=this._getFormFields(e,!1);if(!t[0]||!t[1])return Promise.reject("No logins found");t[0].addEventListener("blur",i);var r=o._getPasswordOrigin(e.ownerDocument.documentURI),s=o._getActionOrigin(e);if(null==s)return Promise.reject("Action origin is null");var a={form:e},l={type:"request",formOrigin:r,actionOrigin:s};return this._sendRequest(a,l)},loginsFound:function(e,n){this._fillForm(e,!0,!1,!1,!1,n)},onUsernameInput:function(e){var t=e.target;if(t.ownerDocument instanceof HTMLDocument&&this._isUsernameFieldType(t)){var o=t.form;if(o&&t.value){n("onUsernameInput from",e.type);var i=this._getFormFields(o,!1),s=r(i,3),a=s[0],l=s[1];if(s[2],a==t&&l){var u=this;this._asyncFindLogins(o,{showMasterPassword:!1}).then(function(e){u._fillForm(e.form,!0,!0,!0,!0,e.loginsFound)}).then(null,n)}}}},_getPasswordFields:function(e,t){for(var r=[],o=0;o<e.elements.length;o++){var i=e.elements[o];i instanceof HTMLInputElement&&"password"==i.type&&(t&&!i.value||(r[r.length]={index:o,element:i}))}return 0==r.length?(n("(form ignored -- no password fields.)"),null):r.length>3?(n("(form ignored -- too many password fields. [ got ",r.length),null):r},_isUsernameFieldType:function(e){if(!(e instanceof HTMLInputElement))return!1;var n=e.hasAttribute("type")?e.getAttribute("type").toLowerCase():e.type;return"text"==n||"email"==n||"url"==n||"tel"==n||"number"==n},_getFormFields:function(e,t){var r,o,i=null,s=this._getPasswordFields(e,t);if(!s)return[null,null,null];for(var a=s[0].index-1;a>=0;a--){var l=e.elements[a];if(this._isUsernameFieldType(l)){i=l;break}}if(i||n("(form -- no username field found)"),!t||1==s.length)return[i,s[0].element,null];var u=s[0].element.value,f=s[1].element.value,d=s[2]?s[2].element.value:null;if(3==s.length)if(u==f&&f==d)o=s[0].element,r=null;else if(u==f)o=s[0].element,r=s[2].element;else if(f==d)r=s[0].element,o=s[2].element;else{if(u!=d)return n("(form ignored -- all 3 pw fields differ)"),[null,null,null];o=s[0].element,r=s[1].element}else u==f?(o=s[0].element,r=null):(r=s[0].element,o=s[1].element);return[i,o,r]},_isAutocompleteDisabled:function(e){return!(!e||!e.hasAttribute("autocomplete")||"off"!=e.getAttribute("autocomplete").toLowerCase())},_onFormSubmit:function(e){var t=e.ownerDocument,r=t.defaultView,i=o._getPasswordOrigin(t.documentURI);if(i){var s=o._getActionOrigin(e),a=this._getFormFields(e,!0),l=a[0],u=a[1],f=a[2];if(null!=u){this._isAutocompleteDisabled(e)||this._isAutocompleteDisabled(l)||this._isAutocompleteDisabled(u)||this._isAutocompleteDisabled(f);var d=l?{name:l.name,value:l.value}:null,c={name:u.name,value:u.value};f&&(f.name,f.value),r.opener&&r.opener.top,webkit.messageHandlers.loginsManagerMessageHandler.postMessage({type:"submit",hostname:i,username:d.value,usernameField:d.name,password:c.value,passwordField:c.name,formSubmitURL:s})}}else n("(form submission ignored -- invalid hostname)")},_fillForm:function(e,t,r,o,i,s){var a=this._getFormFields(e,!1),l=a[0],f=a[1];if(null==f)return[!1,s];if(f.disabled||f.readOnly)return n("not filling form, password field disabled or read-only"),[!1,s];var d=Number.MAX_VALUE,c=Number.MAX_VALUE;l&&l.maxLength>=0&&(d=l.maxLength),f.maxLength>=0&&(c=f.maxLength);var m=(s=function(e,n){var t,r,o;if(null==e)throw new TypeError("Array is null or not defined");var i=Object(e),s=i.length>>>0;if("function"!=typeof n)throw new TypeError(n+" is not a function");for(arguments.length>1&&(t=e),r=new Array(s),o=0;o<s;){var a,l;o in i&&(a=i[o],l=n.call(t,a,o,i),r[o]=l),o++}return r}(s,function(e){return{hostname:e.hostname,formSubmitURL:e.formSubmitURL,httpRealm:e.httpRealm,username:e.username,password:e.password,usernameField:e.usernameField,passwordField:e.passwordField}})).filter(function(e){var t=e.username.length<=d&&e.password.length<=c;return t||n("Ignored",e.username),t},this);if(0==m.length)return[!1,s];if(f.value&&!o)return[!1,s];var g=!1;!r&&(this._isAutocompleteDisabled(e)||this._isAutocompleteDisabled(l)||this._isAutocompleteDisabled(f))&&(g=!0,n("form not filled, has autocomplete=off"));var v=null;if(l&&(l.value||l.disabled||l.readOnly)){var p=l.value.toLowerCase();if((b=m.filter(function(e){return e.username.toLowerCase()==p})).length){for(var _=0;_<b.length;_++){var h=b[_];h.username==l.value&&(v=h)}v||(v=b[0])}else n("Password not filled. None of the stored logins match the username already present.")}else if(1==m.length)v=m[0];else{var b;v=(b=l?m.filter(function(e){return e.username}):m.filter(function(e){return!e.username}))[0]}var w=!1;if(v&&t&&!g){if(l){var y=l.disabled||l.readOnly,F=v.username!=l.value,L=i&&F&&l.value.toLowerCase()==v.username.toLowerCase();y||L||!F||(l.value=v.username,u(l,"keydown",40),u(l,"keyup",40))}f.value!=v.password&&(f.value=v.password,u(f,"keydown",40),u(f,"keyup",40)),w=!0}else v&&!t?n("autofillForms=false but form can be filled; notified observers"):v&&g&&n("autocomplete=off but form can be filled; notified observers");return[w,s]}},o={_getPasswordOrigin:function(e,n){return e},_getActionOrigin:function(e){var n=e.action;return""==n&&(n=e.baseURI),this._getPasswordOrigin(n,!0)}};function i(e){t.onUsernameInput(e)}var s=document.body;function a(e){for(var n=0;n<e.length;n++){var t=e[n];"FORM"===t.nodeName?l(t):t.hasChildNodes()&&a(t.childNodes)}return!1}function l(e){try{t._asyncFindLogins(e,{}).then(function(e){t.loginsFound(e.form,e.loginsFound)}).then(null,n)}catch(e){n(e)}}function u(e,n,t){var r=document.createEvent("KeyboardEvent");r.initKeyboardEvent(n,!0,!0,window,0,0,0,0,0,t),e.dispatchEvent(r)}new MutationObserver(function(e){for(var n=0;n<e.length;++n)a(e[n].addedNodes)}).observe(s,{attributes:!1,childList:!0,characterData:!1,subtree:!0}),window.addEventListener("load",function(e){for(var n=0;n<document.forms.length;n++)l(document.forms[n])}),window.addEventListener("submit",function(e){try{t._onFormSubmit(e.target)}catch(e){n(e)}}),Object.defineProperty(window.__firefox__,"logins",{enumerable:!1,configurable:!1,writable:!1,value:Object.freeze(new function(){this.inject=function(e){try{t.receiveMessage(e)}catch(e){}}})})})},function(e,n,t){"use strict";window.__firefox__.includeOnce("PrintHandler",function(){window.print=function(){webkit.messageHandlers.printHandler.postMessage({})}})}]);