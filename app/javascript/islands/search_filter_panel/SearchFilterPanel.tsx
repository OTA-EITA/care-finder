import { useId, useState, type FormEvent } from "react";
import { buildSearchQuery, normalizeState, toggle } from "./query";
import type { FacetCounts, SearchFilterPanelProps, SearchState } from "./types";

const defaultNavigate = (url: string) => {
  const turbo = (window as unknown as { Turbo?: { visit: (url: string) => void } }).Turbo;
  if (turbo) turbo.visit(url);
  else window.location.assign(url);
};

function Count({ value }: { value: number | undefined }) {
  return <span className="ml-1 text-xs text-stone-500">({value ?? 0})</span>;
}

function sortedEntries(counts: FacetCounts): [string, number][] {
  return Object.entries(counts).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], "ja"));
}

// 検索画面の絞り込みパネル。チェックや選択を変えたらすぐ検索し、文字の入力は「この条件で探す」で確定する。
export function SearchFilterPanel({
  action,
  initial,
  facets,
  serviceTypes,
  features,
  stations,
  navigate = defaultNavigate,
}: SearchFilterPanelProps) {
  const [state, setState] = useState<SearchState>(() => normalizeState(initial));
  const id = useId();

  const go = (next: SearchState) => {
    setState(next);
    const query = buildSearchQuery(next);
    navigate(query ? `${action}?${query}` : action);
  };

  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    go(state);
  };

  const municipalities = sortedEntries(facets.municipalities);
  const prefectures = sortedEntries(facets.prefectures);

  return (
    <form role="search" aria-label="事業所の絞り込み" onSubmit={onSubmit} className="space-y-5">
      <div>
        <label htmlFor={`${id}-keyword`} className="label">
          キーワード
        </label>
        <input
          id={`${id}-keyword`}
          type="search"
          className="input"
          placeholder="事業所名・住所・支援内容など"
          value={state.keyword}
          maxLength={100}
          onChange={(e) => setState({ ...state, keyword: e.target.value })}
        />
      </div>

      <div>
        <label htmlFor={`${id}-near`} className="label">
          駅・住所から近い順
        </label>
        <input
          id={`${id}-near`}
          type="text"
          className="input"
          placeholder="例: 帯広駅"
          list={`${id}-stations`}
          value={state.near}
          maxLength={50}
          onChange={(e) => setState({ ...state, near: e.target.value })}
        />
        <datalist id={`${id}-stations`}>
          {stations.map((name) => (
            <option key={name} value={name} />
          ))}
        </datalist>
      </div>

      <button type="submit" className="btn-primary w-full">
        この条件で探す
      </button>

      <fieldset>
        <legend className="label">サービス種別</legend>
        <div className="space-y-1">
          {serviceTypes.map((option) => (
            <label key={option.value} className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={state.service_types.includes(option.value)}
                onChange={() => go({ ...state, service_types: toggle(state.service_types, option.value) })}
              />
              {option.label}
              <Count value={facets.service_types[option.value]} />
            </label>
          ))}
        </div>
      </fieldset>

      <div>
        <label htmlFor={`${id}-prefecture`} className="label">
          都道府県
        </label>
        <select
          id={`${id}-prefecture`}
          className="input"
          value={state.prefecture}
          onChange={(e) => go({ ...state, prefecture: e.target.value, municipality: "" })}
        >
          <option value="">すべて</option>
          {prefectures.map(([name, count]) => (
            <option key={name} value={name}>
              {name} ({count})
            </option>
          ))}
        </select>
      </div>

      {state.prefecture && (
        <div>
          <label htmlFor={`${id}-municipality`} className="label">
            市区町村
          </label>
          <select
            id={`${id}-municipality`}
            className="input"
            value={state.municipality}
            onChange={(e) => go({ ...state, municipality: e.target.value })}
          >
            <option value="">すべて</option>
            {municipalities.map(([name, count]) => (
              <option key={name} value={name}>
                {name} ({count})
              </option>
            ))}
          </select>
        </div>
      )}

      <fieldset>
        <legend className="label">利用できる日・送迎</legend>
        <div className="space-y-1">
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={state.open_saturday} onChange={() => go({ ...state, open_saturday: !state.open_saturday })} />
            土曜に利用できる
            <Count value={facets.open_saturday} />
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={state.open_sunday_or_holiday}
              onChange={() => go({ ...state, open_sunday_or_holiday: !state.open_sunday_or_holiday })}
            />
            日曜・祝日に利用できる
            <Count value={facets.open_sunday_or_holiday} />
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={state.pickup} onChange={() => go({ ...state, pickup: !state.pickup })} />
            送迎あり（事業所が登録したもの）
            <Count value={facets.pickup} />
          </label>
        </div>
      </fieldset>

      {features.length > 0 && (
        <fieldset>
          <legend className="label">支援内容</legend>
          <div className="space-y-1">
            {features.map((option) => (
              <label key={option.value} className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={state.feature_codes.includes(option.value)}
                  onChange={() => go({ ...state, feature_codes: toggle(state.feature_codes, option.value) })}
                />
                {option.label}
                <Count value={facets.features[option.value]} />
              </label>
            ))}
          </div>
        </fieldset>
      )}

      <div>
        <label htmlFor={`${id}-sort`} className="label">
          並び順
        </label>
        <select
          id={`${id}-sort`}
          className="input"
          value={state.sort}
          onChange={(e) => go({ ...state, sort: e.target.value as SearchState["sort"] })}
        >
          <option value="relevance">おすすめ順</option>
          <option value="distance">近い順（駅・住所を入れたとき）</option>
          <option value="name">名前順</option>
        </select>
      </div>
    </form>
  );
}
