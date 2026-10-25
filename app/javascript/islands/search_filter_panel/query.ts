import type { SearchState } from "./types";

export const emptyState: SearchState = {
  keyword: "",
  prefecture: "",
  municipality: "",
  service_types: [],
  feature_codes: [],
  open_saturday: false,
  open_sunday_or_holiday: false,
  pickup: false,
  near: "",
  sort: "relevance",
};

export function normalizeState(initial: Partial<SearchState>): SearchState {
  return { ...emptyState, ...initial };
}

// Rails の Search::Criteria#to_query と同じ形にする（既定値は省き、ページは 1 に戻す）
export function buildSearchQuery(state: SearchState): string {
  const params = new URLSearchParams();
  const text = (key: keyof SearchState, value: string) => {
    const trimmed = value.trim();
    if (trimmed) params.append(key, trimmed);
  };

  text("keyword", state.keyword);
  text("prefecture", state.prefecture);
  if (state.prefecture.trim()) text("municipality", state.municipality);
  state.service_types.forEach((value) => params.append("service_types[]", value));
  state.feature_codes.forEach((value) => params.append("feature_codes[]", value));
  if (state.open_saturday) params.append("open_saturday", "1");
  if (state.open_sunday_or_holiday) params.append("open_sunday_or_holiday", "1");
  if (state.pickup) params.append("pickup", "1");
  text("near", state.near);
  if (state.sort !== "relevance") params.append("sort", state.sort);

  return params.toString();
}

export function toggle(values: string[], value: string): string[] {
  return values.includes(value) ? values.filter((v) => v !== value) : [...values, value];
}
