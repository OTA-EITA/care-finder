import { buildSearchQuery, emptyState, normalizeState, toggle } from "../../app/javascript/islands/search_filter_panel/query";

describe("buildSearchQuery", () => {
  it("既定値だけなら空文字", () => {
    expect(buildSearchQuery(emptyState)).toBe("");
  });

  it("Rails の Search::Criteria と同じ名前でパラメーターを組み立てる", () => {
    const query = buildSearchQuery({
      ...emptyState,
      keyword: " 運動 ",
      prefecture: "北海道",
      municipality: "帯広市",
      service_types: ["houkago_day", "jidou_hattatsu"],
      open_saturday: true,
      pickup: true,
      near: "帯広駅",
      sort: "distance",
    });

    const params = new URLSearchParams(query);
    expect(params.get("keyword")).toBe("運動");
    expect(params.get("municipality")).toBe("帯広市");
    expect(params.getAll("service_types[]")).toEqual(["houkago_day", "jidou_hattatsu"]);
    expect(params.get("open_saturday")).toBe("1");
    expect(params.get("open_sunday_or_holiday")).toBeNull();
    expect(params.get("sort")).toBe("distance");
  });

  it("都道府県がなければ市区町村は送らない", () => {
    expect(buildSearchQuery({ ...emptyState, municipality: "帯広市" })).toBe("");
  });
});

describe("toggle", () => {
  it("含まれていれば外し、なければ足す", () => {
    expect(toggle(["a", "b"], "a")).toEqual(["b"]);
    expect(toggle(["a"], "b")).toEqual(["a", "b"]);
  });
});

describe("normalizeState", () => {
  it("足りない項目を既定値で埋める", () => {
    expect(normalizeState({ keyword: "x" })).toEqual({ ...emptyState, keyword: "x" });
  });
});
