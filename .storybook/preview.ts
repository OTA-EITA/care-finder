import type { Preview } from "@storybook/react-vite";
// Tailwind のビルド結果（npm run build:css）をそのまま読む
import "../app/assets/builds/application.css";

const preview: Preview = {
  parameters: {
    layout: "padded",
  },
};

export default preview;
