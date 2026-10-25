import { mountIslands, unmountIslands } from "../../app/javascript/islands";
import { act } from "react";
import { panelProps } from "./fixtures";

describe("islands", () => {
  beforeAll(() => {
    (globalThis as unknown as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
  });

  it("data-react-island の中身を React に置き換え、外すと元の HTML に戻す", async () => {
    document.body.innerHTML = `<div data-react-island="SearchFilterPanel" data-props='${JSON.stringify(panelProps({ navigate: undefined }))}'><form id="fallback"></form></div>`;

    await act(async () => {
      await mountIslands();
    });
    expect(document.querySelector("form[role=search]")).not.toBeNull();
    expect(document.getElementById("fallback")).toBeNull();

    act(() => unmountIslands());
    expect(document.getElementById("fallback")).not.toBeNull();
  });

  it("登録されていない名前は触らない", async () => {
    document.body.innerHTML = `<div data-react-island="Unknown"><p id="keep"></p></div>`;
    await mountIslands();
    expect(document.getElementById("keep")).not.toBeNull();
  });
});
