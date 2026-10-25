import type { Meta, StoryObj } from "@storybook/react-vite";
import { fn } from "storybook/test";
import { SearchFilterPanel } from "./SearchFilterPanel";

const meta = {
  title: "Search/SearchFilterPanel",
  component: SearchFilterPanel,
  decorators: [
    (Story) => (
      <div className="card max-w-xs">
        <Story />
      </div>
    ),
  ],
  args: {
    action: "/facilities",
    navigate: fn(),
    initial: {},
    facets: {
      service_types: { houkago_day: 3879, jidou_hattatsu: 3431 },
      prefectures: { 北海道: 2687, 大阪府: 4630 },
      municipalities: {},
      features: { exercise: 2, study: 1 },
      open_saturday: 3810,
      open_sunday_or_holiday: 2930,
      pickup: 4,
    },
    serviceTypes: [
      { value: "houkago_day", label: "放課後等デイサービス" },
      { value: "jidou_hattatsu", label: "児童発達支援" },
    ],
    features: [
      { value: "exercise", label: "運動療育" },
      { value: "study", label: "学習支援" },
    ],
    stations: ["帯広駅", "札幌駅", "天王寺駅"],
  },
} satisfies Meta<typeof SearchFilterPanel>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const PrefectureSelected: Story = {
  args: {
    initial: { prefecture: "北海道", municipality: "帯広市", open_saturday: true, near: "帯広駅", sort: "distance" },
    facets: {
      ...meta.args.facets,
      municipalities: { 帯広市: 70, 札幌市中央区: 193, 旭川市: 168 },
    },
  },
};
