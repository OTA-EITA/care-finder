// React 本体をまとめて遅延読み込みするための入口。
// react / react-dom は CommonJS なので、動的 import の名前空間から直接取り出さず、ここで静的に import して渡す。
export { createElement } from "react";
export { createRoot } from "react-dom/client";
