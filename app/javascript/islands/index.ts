import type { ComponentType } from "react";
import type { Root } from "react-dom/client";

// サーバーが描いた HTML の一部だけを React にする「島」。
// <div data-react-island="名前" data-props="JSON"> の中身（JS なしでも動くフォーム）を置き換える。
// React 本体は島があるページでだけ読み込む（esbuild の code splitting）。
type Loader = () => Promise<ComponentType<Record<string, unknown>>>;

const registry: Record<string, Loader> = {
  SearchFilterPanel: () =>
    import("./search_filter_panel/SearchFilterPanel").then(
      (m) => m.SearchFilterPanel as unknown as ComponentType<Record<string, unknown>>,
    ),
};

interface Mounted {
  root: Root;
  element: HTMLElement;
  fallback: string;
}

let mounted: Mounted[] = [];

export async function mountIslands(scope: ParentNode = document): Promise<void> {
  const elements = Array.from(scope.querySelectorAll<HTMLElement>("[data-react-island]"));
  const targets = elements.filter((el) => !el.dataset.reactMounted && registry[el.dataset.reactIsland ?? ""]);
  if (targets.length === 0) return;

  const { createRoot, createElement } = await import("./react_runtime");

  for (const element of targets) {
    const load = registry[element.dataset.reactIsland ?? ""];
    if (!load || element.dataset.reactMounted) continue;
    element.dataset.reactMounted = "true";

    const Component = await load();
    const props = JSON.parse(element.dataset.props ?? "{}") as Record<string, unknown>;
    const fallback = element.innerHTML;
    const root = createRoot(element);
    root.render(createElement(Component, props));
    mounted.push({ root, element, fallback });
  }
}

// Turbo がページをキャッシュする前に React を外し、JS なしの HTML に戻しておく
export function unmountIslands(): void {
  mounted.forEach(({ root, element, fallback }) => {
    root.unmount();
    element.innerHTML = fallback;
    delete element.dataset.reactMounted;
  });
  mounted = [];
}
