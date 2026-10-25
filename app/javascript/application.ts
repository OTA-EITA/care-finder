import "@hotwired/turbo-rails";
import "./controllers";
import { mountIslands, unmountIslands } from "./islands";

document.addEventListener("turbo:load", () => {
  void mountIslands();
});
document.addEventListener("turbo:before-cache", () => unmountIslands());
