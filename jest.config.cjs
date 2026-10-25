/** @type {import("jest").Config} */
module.exports = {
  testEnvironment: "jsdom",
  roots: ["<rootDir>/spec/javascript"],
  testMatch: ["**/*.test.ts", "**/*.test.tsx"],
  setupFilesAfterEnv: ["<rootDir>/spec/javascript/setup.ts"],
  transform: {
    "^.+\\.tsx?$": [
      "ts-jest",
      { tsconfig: { jsx: "react-jsx", module: "commonjs", esModuleInterop: true, isolatedModules: true } },
    ],
  },
  collectCoverageFrom: ["app/javascript/islands/**/*.{ts,tsx}"],
};
