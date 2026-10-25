import { Controller } from "@hotwired/stimulus";

// 入力欄の残り文字数を表示する（管理画面の紹介文など）
export default class extends Controller<HTMLElement> {
  static targets = ["input", "output"];
  static values = { max: Number };

  declare readonly inputTarget: HTMLTextAreaElement | HTMLInputElement;
  declare readonly outputTarget: HTMLElement;
  declare readonly maxValue: number;

  connect() {
    this.update();
  }

  update() {
    const remaining = this.maxValue - this.inputTarget.value.length;
    this.outputTarget.textContent = `あと ${remaining} 文字`;
    this.outputTarget.classList.toggle("text-red-700", remaining < 0);
  }
}
