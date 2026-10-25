import type { SearchFilterPanelProps } from "../../app/javascript/islands/search_filter_panel/types";

export const panelProps = (overrides: Partial<SearchFilterPanelProps> = {}): SearchFilterPanelProps => ({
  action: "/facilities",
  initial: { service_types: [], feature_codes: [], sort: "relevance" },
  facets: {
    service_types: { houkago_day: 39, jidou_hattatsu: 31 },
    prefectures: { 北海道: 2687, 大阪府: 4630 },
    municipalities: { 帯広市: 70, 札幌市中央区: 193 },
    features: { exercise: 2 },
    open_saturday: 28,
    open_sunday_or_holiday: 21,
    pickup: 2,
  },
  serviceTypes: [
    { value: "houkago_day", label: "放課後等デイサービス" },
    { value: "jidou_hattatsu", label: "児童発達支援" },
  ],
  features: [{ value: "exercise", label: "運動療育" }],
  stations: ["帯広駅", "天王寺駅"],
  ...overrides,
});
