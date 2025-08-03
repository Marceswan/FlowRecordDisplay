import { LightningElement, api } from "lwc";

export default class FscFlowCombobox extends LightningElement {
  @api label;
  @api options;
  @api value;
  @api placeholder;
  @api required;
  @api disabled;
  @api masterLabel;

  // Mock the value change event
  handleChange(event) {
    const detail = {
      value: event.detail.value,
      newValue: event.detail.value
    };
    this.dispatchEvent(new CustomEvent("change", { detail }));
  }
}
