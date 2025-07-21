import { LightningElement, api, track } from "lwc";
import getAvailableFlexiPages from "@salesforce/apex/FlexiPageMetadataService.getAvailableFlexiPages";
import getObjectFields from "@salesforce/apex/FlexiPageToolingService.getObjectFields";
import getAllSObjects from "@salesforce/apex/FlexiPageToolingService.getAllSObjects";

export default class FlexipageRecordFormCPE extends LightningElement {
  // Flow Builder interfaces
  _builderContext = {};
  _inputVariables = [];
  _genericTypeMappings = [];
  _automaticOutputVariables = [];

  // UI State
  @track isLoadingFlexiPages = false;
  @track isLoadingFields = false;
  @track isLoadingObjects = false;
  @track objectOptions = [];
  @track flexiPageOptions = [];
  @track fieldOptions = [];
  @track showAdvancedSettings = false;
  @track showDefaultValuesModal = false;
  @track showExcludedFieldsModal = false;
  @track defaultValueFields = [];
  @track tempExcludedFields = [];
  @track showIndividualFields = false;
  @track selectedRecordVariable = "";
  @track recordVariableOptions = [];
  @track recordIdVariableOptions = [];
  @track selectedRecordIdVariable = "";

  // Configuration values
  objectApiName;
  selectedFlexiPage;
  cardTitle;
  showIcon = false;
  recordId;
  isReadOnly = false;
  excludedFields = [];
  defaultFieldValues = {};
  saveLabel = "Save";
  cancelLabel = "Cancel";

  // Temporary storage for default values modal
  tempDefaultValues = {};

  // Connected callback to load sObjects when component is initialized
  connectedCallback() {
    this.loadAllSObjects();
    // Load Flow variables if context is available
    if (this._builderContext) {
      this.loadFlowVariables();
    }
  }

  // Getters and setters for Flow Builder interfaces
  @api
  get builderContext() {
    return this._builderContext;
  }
  set builderContext(context) {
    this._builderContext = context || {};
    this.loadObjectMetadata();
  }

  @api
  get inputVariables() {
    return this._inputVariables;
  }
  set inputVariables(variables) {
    this._inputVariables = variables || [];
    this.initializeValues();
  }

  @api
  get genericTypeMappings() {
    return this._genericTypeMappings;
  }
  set genericTypeMappings(mappings) {
    this._genericTypeMappings = mappings || [];
    this.handleGenericTypeMapping();
  }

  @api
  get automaticOutputVariables() {
    return this._automaticOutputVariables;
  }
  set automaticOutputVariables(variables) {
    this._automaticOutputVariables = variables || [];
  }

  // Computed properties
  get advancedSettingsIcon() {
    return this.showAdvancedSettings
      ? "utility:chevrondown"
      : "utility:chevronright";
  }

  get isFlexiPageDisabled() {
    return !this.objectApiName;
  }

  get excludedFieldsCount() {
    return this.excludedFields.length;
  }

  get individualFieldsIcon() {
    return this.showIndividualFields
      ? "utility:chevrondown"
      : "utility:chevronright";
  }

  get hideIndividualFields() {
    return !this.showIndividualFields;
  }

  // Initialize values from existing configuration
  initializeValues() {
    if (!this._inputVariables || !Array.isArray(this._inputVariables)) {
      return;
    }

    let pendingFieldLoad = null;
    let pendingExcludedFields = null;
    let pendingDefaultValues = null;

    // Check for generic type mapping first
    let hasGenericMapping = false;
    if (this._genericTypeMappings && this._genericTypeMappings.length > 0) {
      const mapping = this._genericTypeMappings.find((m) => m.typeName === "T");
      if (mapping && mapping.typeValue) {
        hasGenericMapping = true;
        if (!this.objectApiName) {
          this.objectApiName = mapping.typeValue;
        }
      }
    }

    this._inputVariables.forEach((variable) => {
      switch (variable.name) {
        case "objectApiName":
          // Only set if we don't have a generic mapping or if the value is explicitly set
          if (!hasGenericMapping || variable.value) {
            this.objectApiName = variable.value;
          }
          break;
        case "flexiPageName":
          pendingFieldLoad = variable.value;
          break;
        case "cardTitle":
          this.cardTitle = variable.value;
          break;
        case "showIcon":
          this.showIcon = variable.value === true || variable.value === "true";
          break;
        case "recordId":
          this.recordId = variable.value;
          // Check if it's a Flow variable (no {!} syntax in CPEs)
          if (
            variable.value &&
            this._builderContext &&
            this._builderContext.variables
          ) {
            // Check if the value matches a variable name
            const matchingVariable = this._builderContext.variables.find(
              (v) => v.name === variable.value
            );
            if (matchingVariable) {
              this.selectedRecordIdVariable = variable.value;
            }
          }
          break;
        case "isReadOnly":
          this.isReadOnly =
            variable.value === true || variable.value === "true";
          break;
        case "excludedFields":
          pendingExcludedFields = variable.value;
          break;
        case "defaultValues":
          pendingDefaultValues = variable.value;
          break;
        case "saveLabel":
          this.saveLabel = variable.value || "Save";
          break;
        case "cancelLabel":
          this.cancelLabel = variable.value || "Cancel";
          break;
        default:
          // Ignore unknown variables
          break;
      }
    });

    // Load dependent data
    if (this.objectApiName) {
      this.loadFlexiPages().then(() => {
        if (pendingFieldLoad) {
          this.selectedFlexiPage = pendingFieldLoad;
          this.loadFields().then(() => {
            if (pendingExcludedFields) {
              this.excludedFields = pendingExcludedFields
                .split(",")
                .map((f) => f.trim());
            }
            if (pendingDefaultValues) {
              this.parseDefaultValues(pendingDefaultValues);
            }
          });
        }
      });
    }
  }

  // Dispatch configuration changes to Flow Builder
  dispatchConfigurationChange(name, value, dataType = "String") {
    const valueChangeEvent = new CustomEvent(
      "configuration_editor_input_value_changed",
      {
        bubbles: true,
        cancelable: false,
        composed: true,
        detail: {
          name: name,
          newValue: value,
          newValueDataType: dataType
        }
      }
    );
    this.dispatchEvent(valueChangeEvent);
  }

  // Event handlers
  handleObjectChange(event) {
    this.objectApiName = event.detail.value;
    this.dispatchConfigurationChange("objectApiName", this.objectApiName);

    // Reset dependent selections
    this.selectedFlexiPage = null;
    this.excludedFields = [];
    this.defaultFieldValues = {};
    this.dispatchConfigurationChange("flexiPageName", null);
    this.dispatchConfigurationChange("excludedFields", "");
    this.dispatchConfigurationChange("defaultValues", "");

    // Dispatch generic type mapping for Flow
    this.dispatchEvent(
      new CustomEvent("configuration_editor_generic_type_mapping_changed", {
        bubbles: true,
        composed: true,
        detail: {
          typeName: "T",
          typeValue: this.objectApiName
        }
      })
    );

    // Load FlexiPages for the selected object
    this.loadFlexiPages();

    // Reload Flow variables for the new object type
    this.loadFlowVariables();
  }

  handleFlexiPageChange(event) {
    this.selectedFlexiPage = event.detail.value;
    this.dispatchConfigurationChange("flexiPageName", this.selectedFlexiPage);

    // Load fields when FlexiPage is selected
    this.loadFields();
  }

  handleCardTitleChange(event) {
    this.cardTitle = event.detail.value;
    this.dispatchConfigurationChange("cardTitle", this.cardTitle);
  }

  handleShowIconChange(event) {
    this.showIcon = event.detail.checked;
    this.dispatchConfigurationChange("showIcon", this.showIcon, "Boolean");
  }

  handleRecordIdChange(event) {
    this.recordId = event.detail.value;
    this.dispatchConfigurationChange("recordId", this.recordId);
    // Clear the dropdown selection when user types manually
    this.selectedRecordIdVariable = "";
  }

  handleRecordIdVariableChange(event) {
    this.selectedRecordIdVariable = event.detail.value;
    if (this.selectedRecordIdVariable) {
      // Set the record ID to just the variable name (Flow will resolve it)
      this.recordId = this.selectedRecordIdVariable;
      this.dispatchConfigurationChange("recordId", this.recordId);
    }
  }

  handleReadOnlyChange(event) {
    this.isReadOnly = event.detail.checked;
    this.dispatchConfigurationChange("isReadOnly", this.isReadOnly, "Boolean");
  }

  handleSaveLabelChange(event) {
    this.saveLabel = event.detail.value || "Save";
    this.dispatchConfigurationChange("saveLabel", this.saveLabel);
  }

  handleCancelLabelChange(event) {
    this.cancelLabel = event.detail.value || "Cancel";
    this.dispatchConfigurationChange("cancelLabel", this.cancelLabel);
  }

  toggleAdvancedSettings() {
    this.showAdvancedSettings = !this.showAdvancedSettings;

    // Load fields if not already loaded
    if (this.showAdvancedSettings && this.fieldOptions.length === 0) {
      this.loadFields();
    }
  }

  // Data loading methods
  async loadFlexiPages() {
    if (!this.objectApiName) {
      this.flexiPageOptions = [];
      return;
    }

    this.isLoadingFlexiPages = true;
    console.log("Loading FlexiPages for object:", this.objectApiName);

    try {
      const flexiPages = await getAvailableFlexiPages({
        objectApiName: this.objectApiName
      });

      console.log("Retrieved FlexiPages:", flexiPages);
      console.log("FlexiPage count:", flexiPages ? flexiPages.length : 0);

      this.flexiPageOptions = flexiPages.map((page) => ({
        label: page.label || page.developerName,
        value: page.developerName,
        description: page.developerName
      }));

      console.log("FlexiPage options:", this.flexiPageOptions);
    } catch (error) {
      console.error("Error loading FlexiPages:", error);
      console.error("Error details:", {
        message: error.message,
        stack: error.stack,
        body: error.body
      });
      this.showError("Unable to load FlexiPage layouts");
    } finally {
      this.isLoadingFlexiPages = false;
    }
  }

  async loadFields() {
    if (!this.objectApiName) {
      this.fieldOptions = [];
      return;
    }

    this.isLoadingFields = true;
    try {
      const fields = await getObjectFields({
        objectApiName: this.objectApiName
      });

      // Filter out system fields that shouldn't be excluded
      const userEditableFields = fields.filter(
        (field) =>
          ![
            "Id",
            "CreatedDate",
            "CreatedById",
            "LastModifiedDate",
            "LastModifiedById",
            "SystemModstamp"
          ].includes(field.apiName)
      );

      this.fieldOptions = userEditableFields.map((field) => ({
        label: field.label,
        value: field.apiName
      }));

      // Also prepare fields for default values
      this.defaultValueFields = userEditableFields.map((field) => ({
        label: field.label,
        value: field.apiName,
        type: field.type,
        defaultValue: this.defaultFieldValues[field.apiName] || "",
        selectedVariable: "",
        variableOptions: []
      }));
    } catch (error) {
      console.error("Error loading fields:", error);
      this.showError("Unable to load object fields");
    } finally {
      this.isLoadingFields = false;
    }
  }

  // Default values modal handlers
  openDefaultValuesModal() {
    this.showDefaultValuesModal = true;
    // Copy current values to temp storage
    this.tempDefaultValues = { ...this.defaultFieldValues };
    // Load Flow variables
    this.loadFlowVariables();
    // Load field-specific variables
    this.loadFieldVariables();
    // Start with accordion collapsed
    this.showIndividualFields = false;
  }

  loadFieldVariables() {
    if (!this._builderContext || !this._builderContext.variables) {
      return;
    }

    // Update each field with appropriate variable options
    this.defaultValueFields = this.defaultValueFields.map((field) => {
      const variableOptions = this.getVariableOptionsForFieldType(field.type);

      // Check if current value is a Flow variable (no {!} syntax in CPEs)
      let selectedVariable = "";
      if (field.defaultValue) {
        // Check if the value matches a variable name or variable path
        const matchingVariable = this._builderContext.variables.find(
          (v) =>
            v.name === field.defaultValue ||
            field.defaultValue.startsWith(v.name + ".")
        );
        if (matchingVariable) {
          selectedVariable = field.defaultValue;
        }
      }

      return {
        ...field,
        selectedVariable: selectedVariable,
        variableOptions: variableOptions
      };
    });
  }

  getVariableOptionsForFieldType(fieldType) {
    if (!this._builderContext || !this._builderContext.variables) {
      return [];
    }

    const options = [];

    // Add empty option first
    options.push({
      label: "-- Select a variable --",
      value: "",
      description: "Choose from available Flow variables"
    });

    // Filter variables based on field type
    this._builderContext.variables.forEach((variable) => {
      let includeVariable = false;
      let description = "";

      // Map Salesforce field types to Flow variable types
      switch (fieldType) {
        case "STRING":
        case "TEXTAREA":
        case "PHONE":
        case "EMAIL":
        case "URL":
        case "PICKLIST":
        case "MULTIPICKLIST":
          if (variable.dataType === "String") {
            includeVariable = true;
            description = "Text variable";
          }
          break;
        case "BOOLEAN":
          if (variable.dataType === "Boolean") {
            includeVariable = true;
            description = "Boolean variable";
          }
          break;
        case "INTEGER":
        case "DOUBLE":
        case "PERCENT":
        case "CURRENCY":
          if (variable.dataType === "Number") {
            includeVariable = true;
            description = "Number variable";
          }
          break;
        case "DATE":
          if (variable.dataType === "Date") {
            includeVariable = true;
            description = "Date variable";
          }
          break;
        case "DATETIME":
          if (variable.dataType === "DateTime") {
            includeVariable = true;
            description = "DateTime variable";
          }
          break;
        case "REFERENCE":
          if (variable.dataType === "String") {
            includeVariable = true;
            description = "Text variable (for ID)";
          }
          // Also include record variables of the same type
          if (
            (variable.dataType === "SObject" ||
              variable.dataType === "Sobject") &&
            this.objectApiName &&
            variable.objectType === this.objectApiName
          ) {
            includeVariable = true;
            description = `${variable.objectType} record`;
          }
          break;
        default:
          // No matching type - exclude variable
          includeVariable = false;
          break;
      }

      if (includeVariable) {
        options.push({
          label: variable.name,
          value: variable.name,
          description: description
        });
      }
    });

    return options;
  }

  toggleIndividualFields() {
    this.showIndividualFields = !this.showIndividualFields;
  }

  handleRecordVariableChange(event) {
    this.selectedRecordVariable = event.detail.value;

    if (this.selectedRecordVariable) {
      // When a record variable is selected, populate all fields with the variable reference
      this.defaultValueFields = this.defaultValueFields.map((field) => {
        // In CPE, we store the variable path directly without {!} syntax
        const variablePath = `${this.selectedRecordVariable}.${field.value}`;
        this.tempDefaultValues[field.value] = variablePath;
        return {
          ...field,
          defaultValue: variablePath,
          selectedVariable: variablePath
        };
      });

      // Expand the accordion to show the populated fields
      this.showIndividualFields = true;
    } else {
      // Clear all fields when "None" is selected
      this.defaultValueFields = this.defaultValueFields.map((field) => {
        delete this.tempDefaultValues[field.value];
        return {
          ...field,
          defaultValue: "",
          selectedVariable: ""
        };
      });
    }
  }

  closeDefaultValuesModal() {
    this.showDefaultValuesModal = false;
    // Reset temp values
    this.tempDefaultValues = {};
  }

  handleDefaultValueChange(event) {
    const fieldName = event.target.dataset.field;
    const value = event.detail.value;

    if (value) {
      this.tempDefaultValues[fieldName] = value;
      // Update the field's defaultValue in the array
      this.defaultValueFields = this.defaultValueFields.map((field) => {
        if (field.value === fieldName) {
          return { ...field, defaultValue: value, selectedVariable: "" };
        }
        return field;
      });
    } else {
      delete this.tempDefaultValues[fieldName];
      // Clear the field's defaultValue
      this.defaultValueFields = this.defaultValueFields.map((field) => {
        if (field.value === fieldName) {
          return { ...field, defaultValue: "", selectedVariable: "" };
        }
        return field;
      });
    }
  }

  handleFieldVariableChange(event) {
    const fieldName = event.target.dataset.field;
    const selectedVariable = event.detail.value;

    if (selectedVariable) {
      // Set the field value to just the variable name (no {!} syntax)
      this.tempDefaultValues[fieldName] = selectedVariable;

      // Update the field in the array
      this.defaultValueFields = this.defaultValueFields.map((field) => {
        if (field.value === fieldName) {
          return {
            ...field,
            defaultValue: selectedVariable,
            selectedVariable: selectedVariable
          };
        }
        return field;
      });
    } else {
      // Clear the selection
      this.defaultValueFields = this.defaultValueFields.map((field) => {
        if (field.value === fieldName) {
          return { ...field, selectedVariable: "" };
        }
        return field;
      });
    }
  }

  saveDefaultValues() {
    this.defaultFieldValues = { ...this.tempDefaultValues };
    const defaultValuesString = this.formatDefaultValuesString();
    this.dispatchConfigurationChange("defaultValues", defaultValuesString);
    this.closeDefaultValuesModal();
  }

  // Excluded fields modal handlers
  openExcludedFieldsModal() {
    this.showExcludedFieldsModal = true;
    // Copy current excluded fields to temp array
    this.tempExcludedFields = [...this.excludedFields];

    // Load fields if not already loaded
    if (this.fieldOptions.length === 0) {
      this.loadFields();
    }
  }

  closeExcludedFieldsModal() {
    this.showExcludedFieldsModal = false;
    // Reset temp values
    this.tempExcludedFields = [];
  }

  handleTempExcludedFieldsChange(event) {
    this.tempExcludedFields = event.detail.value;
  }

  saveExcludedFields() {
    this.excludedFields = [...this.tempExcludedFields];
    const excludedFieldsString = this.excludedFields.join(",");
    this.dispatchConfigurationChange("excludedFields", excludedFieldsString);
    this.closeExcludedFieldsModal();
  }

  // Helper methods
  parseDefaultValues(defaultValuesString) {
    if (!defaultValuesString) {
      this.defaultFieldValues = {};
      return;
    }

    const values = {};
    // Support both comma and semicolon separators
    const pairs = defaultValuesString.split(/[,;]/);

    pairs.forEach((pair) => {
      const [field, value] = pair.split(":").map((s) => s.trim());
      if (field && value) {
        // Store the value directly - no {!} syntax in CPEs
        // Flow will resolve variable references automatically
        values[field] = value;
      }
    });

    this.defaultFieldValues = values;
  }

  formatDefaultValuesString() {
    const pairs = Object.entries(this.defaultFieldValues)
      .filter(([, value]) => value)
      .map(([field, value]) => {
        // Format as field:value - Flow handles variable resolution
        // No {!} syntax needed in CPEs
        return `${field}:${value}`;
      });

    return pairs.join(",");
  }

  handleGenericTypeMapping() {
    // Handle generic type mapping if needed
    if (this._genericTypeMappings && this._genericTypeMappings.length > 0) {
      const mapping = this._genericTypeMappings.find((m) => m.typeName === "T");
      if (mapping && mapping.typeValue) {
        this.objectApiName = mapping.typeValue;
        // Dispatch configuration change to ensure it's saved
        this.dispatchConfigurationChange("objectApiName", this.objectApiName);
        this.loadFlexiPages();
      }
    }
  }

  loadObjectMetadata() {
    // Load record variables from Flow builder context
    this.loadFlowVariables();
  }

  loadFlowVariables() {
    if (!this._builderContext || !this._builderContext.variables) {
      return;
    }

    // Filter for record variables of the selected object type
    const recordVariables = this._builderContext.variables.filter(
      (variable) => {
        // Check if it's a record variable
        if (
          variable.dataType === "SObject" ||
          variable.dataType === "Sobject"
        ) {
          // If we have an object selected, filter by object type
          if (this.objectApiName) {
            return variable.objectType === this.objectApiName;
          }
          return true;
        }
        return false;
      }
    );

    // Map to combobox options
    this.recordVariableOptions = recordVariables.map((variable) => ({
      label: variable.name,
      value: variable.name,
      description: `${variable.objectType} record variable`
    }));

    // Add empty option at the beginning
    this.recordVariableOptions.unshift({
      label: "-- None --",
      value: "",
      description: "Manual field entry"
    });

    // Also load variables suitable for Record ID (Text variables and specific record ID references)
    this.loadRecordIdVariables();
  }

  loadRecordIdVariables() {
    if (!this._builderContext || !this._builderContext.variables) {
      this.recordIdVariableOptions = [];
      return;
    }

    // Filter for variables that can hold a record ID
    const idVariables = this._builderContext.variables.filter((variable) => {
      // Include Text variables
      if (variable.dataType === "String") {
        return true;
      }
      // Include record variables that we can extract ID from
      if (
        (variable.dataType === "SObject" || variable.dataType === "Sobject") &&
        this.objectApiName &&
        variable.objectType === this.objectApiName
      ) {
        return true;
      }
      return false;
    });

    // Map to combobox options
    this.recordIdVariableOptions = idVariables.map((variable) => {
      if (variable.dataType === "String") {
        return {
          label: variable.name,
          value: variable.name,
          description: "Text variable"
        };
      }
      // For record variables, we'll reference the Id field
      return {
        label: variable.name,
        value: `${variable.name}.Id`,
        description: `${variable.objectType} record ID`
      };
    });

    // Add empty option at the beginning
    this.recordIdVariableOptions.unshift({
      label: "-- Select a variable --",
      value: "",
      description: "Choose from available Flow variables"
    });
  }

  // Load all available sObjects
  async loadAllSObjects() {
    this.isLoadingObjects = true;
    try {
      const sObjects = await getAllSObjects();
      this.objectOptions = sObjects;

      // If we have a generic type mapping, ensure it's selected
      if (this._genericTypeMappings && this._genericTypeMappings.length > 0) {
        const mapping = this._genericTypeMappings.find(
          (m) => m.typeName === "T"
        );
        if (mapping && mapping.typeValue && !this.objectApiName) {
          this.objectApiName = mapping.typeValue;
        }
      }
    } catch (error) {
      console.error("Error loading sObjects:", error);
      this.showError("Unable to load objects");
    } finally {
      this.isLoadingObjects = false;
    }
  }

  showError(message) {
    // Simple error display - can be enhanced with toast notifications
    console.error(message);

    // Dispatch error event for Flow Builder
    this.dispatchEvent(
      new CustomEvent("configuration_editor_error", {
        bubbles: true,
        composed: true,
        detail: { message }
      })
    );
  }

  // Validation method for Flow Builder
  @api
  validate() {
    const errors = [];

    // Validate required fields
    if (!this.objectApiName) {
      errors.push({
        key: "OBJECT_REQUIRED",
        errorString: "Please select an object"
      });
    }

    if (!this.selectedFlexiPage) {
      errors.push({
        key: "FLEXIPAGE_REQUIRED",
        errorString: "Please select a FlexiPage layout"
      });
    }

    // Validate default values format
    if (
      this.defaultFieldValues &&
      Object.keys(this.defaultFieldValues).length > 0
    ) {
      try {
        this.formatDefaultValuesString();
      } catch {
        errors.push({
          key: "INVALID_DEFAULT_VALUES",
          errorString: "Invalid default values format"
        });
      }
    }

    return errors;
  }
}
