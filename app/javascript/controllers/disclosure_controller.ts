import { Controller } from "@hotwired/stimulus";

// スマートフォン幅で絞り込みパネルを開閉する。md 以上では CSS で常に表示する
export default class extends Controller<HTMLElement> {
  static targets = ["button", "panel"];

  declare readonly buttonTarget: HTMLButtonElement;
  declare readonly panelTarget: HTMLElement;

  toggle() {
    const open = this.panelTarget.classList.toggle("hidden") === false;
    this.buttonTarget.setAttribute("aria-expanded", String(open));
    this.buttonTarget.textContent = open ? "絞り込み条件を閉じる" : "絞り込み条件を開く";
  }
}
