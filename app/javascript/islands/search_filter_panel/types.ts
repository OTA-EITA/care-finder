export type Sort = "relevance" | "distance" | "name";

export interface SearchState {
  keyword: string;
  prefecture: string;
  municipality: string;
  service_types: string[];
  feature_codes: string[];
  open_saturday: boolean;
  open_sunday_or_holiday: boolean;
  pickup: boolean;
  near: string;
  sort: Sort;
}

export type FacetCounts = Record<string, number>;

export interface Facets {
  service_types: FacetCounts;
  prefectures: FacetCounts;
  municipalities: FacetCounts;
  features: FacetCounts;
  open_saturday: number;
  open_sunday_or_holiday: number;
  pickup: number;
}

export interface Option {
  value: string;
  label: string;
}

export interface SearchFilterPanelProps {
  action: string;
  initial: Partial<SearchState>;
  facets: Facets;
  serviceTypes: Option[];
  features: Option[];
  stations: string[];
  navigate?: (url: string) => void;
}
