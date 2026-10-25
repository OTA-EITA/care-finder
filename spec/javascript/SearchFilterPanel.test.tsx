import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SearchFilterPanel } from "../../app/javascript/islands/search_filter_panel/SearchFilterPanel";
import { panelProps } from "./fixtures";

describe("SearchFilterPanel", () => {
  it("ファセットの件数を表示する", () => {
    render(<SearchFilterPanel {...panelProps()} />);

    expect(screen.getByRole("checkbox", { name: /放課後等デイサービス\s*\(39\)/ })).toBeInTheDocument();
    expect(screen.getByRole("checkbox", { name: /土曜に利用できる\s*\(28\)/ })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "大阪府 (4630)" })).toBeInTheDocument();
  });

  it("チェックを変えるとすぐ検索する", async () => {
    const navigate = jest.fn();
    render(<SearchFilterPanel {...panelProps({ navigate })} />);

    await userEvent.click(screen.getByRole("checkbox", { name: /児童発達支援/ }));

    expect(navigate).toHaveBeenCalledWith("/facilities?service_types%5B%5D=jidou_hattatsu");
  });

  it("文字の入力は「この条件で探す」で確定する", async () => {
    const navigate = jest.fn();
    render(<SearchFilterPanel {...panelProps({ navigate })} />);

    await userEvent.type(screen.getByLabelText("キーワード"), "運動");
    expect(navigate).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole("button", { name: "この条件で探す" }));
    expect(navigate).toHaveBeenCalledWith(`/facilities?keyword=${encodeURIComponent("運動")}`);
  });

  it("都道府県を選ぶと市区町村を出し、変えると市区町村を選び直す", async () => {
    const navigate = jest.fn();
    render(<SearchFilterPanel {...panelProps({ navigate, initial: { prefecture: "北海道", municipality: "帯広市" } })} />);

    expect(screen.getByLabelText("市区町村")).toHaveValue("帯広市");

    await userEvent.selectOptions(screen.getByLabelText("都道府県"), "大阪府");
    expect(navigate).toHaveBeenLastCalledWith(`/facilities?prefecture=${encodeURIComponent("大阪府")}`);
  });

  it("条件がすべて外れたら検索画面そのものへ移る", async () => {
    const navigate = jest.fn();
    render(<SearchFilterPanel {...panelProps({ navigate, initial: { pickup: true } })} />);

    await userEvent.click(screen.getByRole("checkbox", { name: /送迎あり/ }));
    expect(navigate).toHaveBeenCalledWith("/facilities");
  });

  it("駅名の候補を datalist で出す", () => {
    const { container } = render(<SearchFilterPanel {...panelProps()} />);
    expect(container.querySelectorAll("datalist option")).toHaveLength(2);
  });

  it("navigate を渡さなければ Turbo.visit を使う", async () => {
    const visit = jest.fn();
    (window as unknown as { Turbo: { visit: jest.Mock } }).Turbo = { visit };
    render(<SearchFilterPanel {...panelProps()} />);

    await userEvent.selectOptions(screen.getByLabelText("並び順"), "name");
    expect(visit).toHaveBeenCalledWith("/facilities?sort=name");
  });
});
