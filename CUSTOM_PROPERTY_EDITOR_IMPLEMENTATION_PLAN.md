# Custom Property Editor Implementation Plan for FlowRecordDisplay Component

## Executive Summary

This document outlines a comprehensive plan to add a Custom Property Editor (CPE) to the FlowRecordDisplay (flexipageRecordForm) Lightning Web Component. The CPE will provide an intuitive configuration interface within Salesforce Flow Builder, enhancing the user experience when setting up the component.

## Current State Analysis

### Existing Component Structure

- **Main Component**: `flexipageRecordForm` - A dynamic form renderer that uses FlexiPage metadata
- **Apex Controller**: `FlexiPageToolingService` - Handles metadata retrieval and field operations
- **Current Configuration**: Uses standard Flow Builder property inputs without a custom editor
- **Key Properties**: objectApiName, recordId, flexiPageName, cardTitle, and many others

### Gap Analysis

- No custom property editor exists (missing `configurationEditor` attribute in meta.xml)
- Complex properties like excludedFields and defaultValues use comma-separated strings
- No dynamic validation or intelligent field selection
- Limited user guidance for FlexiPage selection

## Implementation Architecture

### Component Structure

```
force-app/main/default/lwc/
├── flexipageRecordForm/           # Existing main component
│   ├── flexipageRecordForm.js
│   ├── flexipageRecordForm.html
│   ├── flexipageRecordForm.js-meta.xml
│   └── utils.js
├── flexipageRecordFormCPE/        # New CPE component
│   ├── flexipageRecordFormCPE.js
│   ├── flexipageRecordFormCPE.html
│   └── flexipageRecordFormCPE.js-meta.xml
└── fsc_flow-combobox/             # External dependency (if needed)
```

### Key Design Decisions

1. **Progressive Disclosure**: Show configuration options in logical steps
2. **Dynamic Metadata Loading**: Fetch available FlexiPages and fields based on selections
3. **Flow Variable Integration**: Use fsc_flow-combobox for Flow variable selection
4. **Real-time Validation**: Validate configurations as users make changes

## Detailed Implementation Steps

### Phase 1: CPE Component Setup

#### 1.1 Create Base CPE Component

**File**: `flexipageRecordFormCPE.js`

```javascript
import { LightningElement, api, track } from "lwc";
import getAvailableFlexiPages from "@salesforce/apex/FlexiPageToolingService.getAvailableFlexiPages";
import getObjectFields from "@salesforce/apex/FlexiPageToolingService.getObjectFields";

export default class FlexipageRecordFormCPE extends LightningElement {
  // Flow Builder interfaces
  _builderContext = {};
  _inputVariables = [];
  _genericTypeMappings = [];
  _automaticOutputVariables = [];

  // UI State
  @track isLoadingFlexiPages = false;
  @track isLoadingFields = false;
  @track flexiPageOptions = [];
  @track fieldOptions = [];
  @track showAdvancedSettings = false;

  // Configuration values
  objectApiName;
  selectedFlexiPage;
  cardTitle;
  showIcon = false;
  recordId;
  isReadOnly = false;
  excludedFields = [];
  defaultFieldValues = {};

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
}
```

#### 1.2 Create CPE HTML Template

**File**: `flexipageRecordFormCPE.html`

```html
<template>
  <div class="slds-form">
    <!-- Object Selection Section -->
    <div class="slds-form-element">
      <label class="slds-form-element__label" for="object-select">
        <abbr class="slds-required" title="required">*</abbr>Object API Name
      </label>
      <div class="slds-form-element__control">
        <lightning-input
          id="object-select"
          type="text"
          value="{objectApiName}"
          placeholder="Enter object API name (e.g., Account)"
          onchange="{handleObjectChange}"
          required
        ></lightning-input>
      </div>
    </div>

    <!-- FlexiPage Selection -->
    <template if:true="{objectApiName}">
      <div class="slds-form-element slds-m-top_medium">
        <label class="slds-form-element__label" for="flexipage-select">
          <abbr class="slds-required" title="required">*</abbr>FlexiPage Layout
        </label>
        <div class="slds-form-element__control">
          <template if:true="{isLoadingFlexiPages}">
            <lightning-spinner size="small"></lightning-spinner>
          </template>
          <template if:false="{isLoadingFlexiPages}">
            <lightning-combobox
              id="flexipage-select"
              value="{selectedFlexiPage}"
              options="{flexiPageOptions}"
              placeholder="Select a FlexiPage"
              onchange="{handleFlexiPageChange}"
              required
            ></lightning-combobox>
          </template>
        </div>
      </div>
    </template>

    <!-- Basic Settings -->
    <template if:true="{selectedFlexiPage}">
      <div class="slds-section slds-is-open slds-m-top_large">
        <h3 class="slds-section__title">
          <span class="slds-truncate">Basic Settings</span>
        </h3>
        <div class="slds-section__content">
          <!-- Card Title -->
          <div class="slds-form-element">
            <label class="slds-form-element__label" for="card-title"
              >Card Title</label
            >
            <div class="slds-form-element__control">
              <lightning-input
                id="card-title"
                type="text"
                value="{cardTitle}"
                placeholder="Enter card title"
                onchange="{handleCardTitleChange}"
              ></lightning-input>
            </div>
          </div>

          <!-- Show Icon -->
          <div class="slds-form-element slds-m-top_small">
            <div class="slds-form-element__control">
              <lightning-input
                type="checkbox"
                label="Show Object Icon"
                checked="{showIcon}"
                onchange="{handleShowIconChange}"
              ></lightning-input>
            </div>
          </div>

          <!-- Record ID -->
          <div class="slds-form-element slds-m-top_small">
            <label class="slds-form-element__label" for="record-id"
              >Record ID</label
            >
            <div class="slds-form-element__control">
              <c-fsc_flow-combobox
                name="recordId"
                value="{recordId}"
                builder-context="{builderContext}"
                automatic-output-variables="{automaticOutputVariables}"
                onvaluechanged="{handleRecordIdChange}"
              ></c-fsc_flow-combobox>
            </div>
          </div>

          <!-- Read Only Mode -->
          <div class="slds-form-element slds-m-top_small">
            <div class="slds-form-element__control">
              <lightning-input
                type="checkbox"
                label="Read Only Mode"
                checked="{isReadOnly}"
                onchange="{handleReadOnlyChange}"
              ></lightning-input>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Advanced Settings -->
    <template if:true="{selectedFlexiPage}">
      <div class="slds-section slds-m-top_medium">
        <h3 class="slds-section__title">
          <button
            class="slds-button slds-section__title-action"
            onclick="{toggleAdvancedSettings}"
          >
            <lightning-icon
              icon-name="{advancedSettingsIcon}"
              size="x-small"
              class="slds-m-right_x-small"
            ></lightning-icon>
            <span class="slds-truncate">Advanced Settings</span>
          </button>
        </h3>
        <template if:true="{showAdvancedSettings}">
          <div class="slds-section__content">
            <!-- Excluded Fields -->
            <div class="slds-form-element">
              <label class="slds-form-element__label">Exclude Fields</label>
              <div class="slds-form-element__control">
                <template if:true="{isLoadingFields}">
                  <lightning-spinner size="small"></lightning-spinner>
                </template>
                <template if:false="{isLoadingFields}">
                  <lightning-dual-listbox
                    name="excludedFields"
                    label="Select fields to exclude"
                    source-label="Available Fields"
                    selected-label="Excluded Fields"
                    options="{fieldOptions}"
                    value="{excludedFields}"
                    onchange="{handleExcludedFieldsChange}"
                  ></lightning-dual-listbox>
                </template>
              </div>
            </div>

            <!-- Default Values -->
            <div class="slds-form-element slds-m-top_medium">
              <label class="slds-form-element__label"
                >Default Field Values</label
              >
              <div class="slds-form-element__control">
                <lightning-button
                  label="Configure Default Values"
                  onclick="{openDefaultValuesModal}"
                  variant="neutral"
                ></lightning-button>
              </div>
              <div class="slds-form-element__help">
                Set default values for fields when creating new records
              </div>
            </div>

            <!-- Button Labels -->
            <div class="slds-grid slds-gutters slds-m-top_medium">
              <div class="slds-col slds-size_1-of-2">
                <lightning-input
                  type="text"
                  label="Save Button Label"
                  value="{saveLabel}"
                  onchange="{handleSaveLabelChange}"
                ></lightning-input>
              </div>
              <div class="slds-col slds-size_1-of-2">
                <lightning-input
                  type="text"
                  label="Cancel Button Label"
                  value="{cancelLabel}"
                  onchange="{handleCancelLabelChange}"
                ></lightning-input>
              </div>
            </div>
          </div>
        </template>
      </div>
    </template>
  </div>

  <!-- Default Values Modal -->
  <template if:true="{showDefaultValuesModal}">
    <section role="dialog" tabindex="-1" class="slds-modal slds-fade-in-open">
      <div class="slds-modal__container">
        <header class="slds-modal__header">
          <button
            class="slds-button slds-button_icon slds-modal__close slds-button_icon-inverse"
            title="Close"
            onclick="{closeDefaultValuesModal}"
          >
            <lightning-icon
              icon-name="utility:close"
              size="small"
            ></lightning-icon>
          </button>
          <h2 class="slds-modal__title">Configure Default Field Values</h2>
        </header>
        <div class="slds-modal__content">
          <!-- Dynamic field inputs for default values -->
          <template for:each="{defaultValueFields}" for:item="field">
            <div key="{field.value}" class="slds-form-element">
              <label class="slds-form-element__label">{field.label}</label>
              <div class="slds-form-element__control">
                <lightning-input
                  type="text"
                  data-field="{field.value}"
                  value="{field.defaultValue}"
                  onchange="{handleDefaultValueChange}"
                ></lightning-input>
              </div>
            </div>
          </template>
        </div>
        <footer class="slds-modal__footer">
          <button
            class="slds-button slds-button_neutral"
            onclick="{closeDefaultValuesModal}"
          >
            Cancel
          </button>
          <button
            class="slds-button slds-button_brand"
            onclick="{saveDefaultValues}"
          >
            Save
          </button>
        </footer>
      </div>
    </section>
    <div class="slds-backdrop slds-backdrop_open"></div>
  </template>
</template>
```

#### 1.3 Update Component Metadata

**File**: `flexipageRecordForm.js-meta.xml` (Update existing)

```xml
<targetConfig
  targets="lightning__FlowScreen"
  configurationEditor="c-flexipage-record-form-c-p-e"
>
    <!-- Existing properties remain the same -->
</targetConfig>
```

### Phase 2: Implement Core Functionality

#### 2.1 Initialize Values from Existing Configuration

```javascript
initializeValues() {
    if (!this._inputVariables || !Array.isArray(this._inputVariables)) {
        return;
    }

    let pendingFieldLoad = null;
    let pendingExcludedFields = null;
    let pendingDefaultValues = null;

    this._inputVariables.forEach(variable => {
        switch (variable.name) {
            case 'objectApiName':
                this.objectApiName = variable.value;
                break;
            case 'flexiPageName':
                pendingFieldLoad = variable.value;
                break;
            case 'cardTitle':
                this.cardTitle = variable.value;
                break;
            case 'showIcon':
                this.showIcon = variable.value === true || variable.value === 'true';
                break;
            case 'recordId':
                this.recordId = variable.value;
                break;
            case 'isReadOnly':
                this.isReadOnly = variable.value === true || variable.value === 'true';
                break;
            case 'excludedFields':
                pendingExcludedFields = variable.value;
                break;
            case 'defaultValues':
                pendingDefaultValues = variable.value;
                break;
            case 'saveLabel':
                this.saveLabel = variable.value || 'Save';
                break;
            case 'cancelLabel':
                this.cancelLabel = variable.value || 'Cancel';
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
                        this.excludedFields = pendingExcludedFields.split(',').map(f => f.trim());
                    }
                    if (pendingDefaultValues) {
                        this.parseDefaultValues(pendingDefaultValues);
                    }
                });
            }
        });
    }
}
```

#### 2.2 Implement Event Dispatching

```javascript
dispatchConfigurationChange(name, value, dataType = 'String') {
    const valueChangeEvent = new CustomEvent('configuration_editor_input_value_changed', {
        bubbles: true,
        cancelable: false,
        composed: true,
        detail: {
            name: name,
            newValue: value,
            newValueDataType: dataType
        }
    });
    this.dispatchEvent(valueChangeEvent);
}

handleObjectChange(event) {
    this.objectApiName = event.detail.value;
    this.dispatchConfigurationChange('objectApiName', this.objectApiName);

    // Reset dependent selections
    this.selectedFlexiPage = null;
    this.excludedFields = [];
    this.defaultFieldValues = {};

    // Dispatch generic type mapping for Flow
    this.dispatchEvent(new CustomEvent('configuration_editor_generic_type_mapping_changed', {
        bubbles: true,
        composed: true,
        detail: {
            typeName: 'T',
            typeValue: this.objectApiName
        }
    }));

    // Load FlexiPages for the selected object
    this.loadFlexiPages();
}
```

#### 2.3 Implement Data Loading

```javascript
async loadFlexiPages() {
    if (!this.objectApiName) {
        this.flexiPageOptions = [];
        return;
    }

    this.isLoadingFlexiPages = true;
    try {
        const flexiPages = await getAvailableFlexiPages({
            objectApiName: this.objectApiName
        });

        this.flexiPageOptions = flexiPages.map(page => ({
            label: page.label || page.developerName,
            value: page.developerName,
            description: page.description
        }));
    } catch (error) {
        console.error('Error loading FlexiPages:', error);
        this.showError('Unable to load FlexiPage layouts');
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
        const userEditableFields = fields.filter(field =>
            !['Id', 'CreatedDate', 'CreatedById', 'LastModifiedDate',
              'LastModifiedById', 'SystemModstamp'].includes(field.apiName)
        );

        this.fieldOptions = userEditableFields.map(field => ({
            label: field.label,
            value: field.apiName
        }));

        // Also prepare fields for default values
        this.defaultValueFields = userEditableFields.map(field => ({
            label: field.label,
            value: field.apiName,
            type: field.type,
            defaultValue: this.defaultFieldValues[field.apiName] || ''
        }));
    } catch (error) {
        console.error('Error loading fields:', error);
        this.showError('Unable to load object fields');
    } finally {
        this.isLoadingFields = false;
    }
}
```

### Phase 3: Add Validation

#### 3.1 Implement Validation Method

```javascript
@api
validate() {
    const errors = [];

    // Validate required fields
    if (!this.objectApiName) {
        errors.push({
            key: 'OBJECT_REQUIRED',
            errorString: 'Please select an object'
        });
    }

    if (!this.selectedFlexiPage) {
        errors.push({
            key: 'FLEXIPAGE_REQUIRED',
            errorString: 'Please select a FlexiPage layout'
        });
    }

    // Validate default values format
    if (this.defaultFieldValues && Object.keys(this.defaultFieldValues).length > 0) {
        try {
            this.formatDefaultValuesString();
        } catch (e) {
            errors.push({
                key: 'INVALID_DEFAULT_VALUES',
                errorString: 'Invalid default values format'
            });
        }
    }

    return errors;
}
```

### Phase 4: Create Supporting Apex Methods

#### 4.1 Add Methods to FlexiPageToolingService

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getAvailableFlexiPages(String objectApiName) {
    List<Map<String, Object>> flexiPages = new List<Map<String, Object>>();

    try {
        // Query FlexiPage metadata for the object
        List<FlexiPage> pages = [
            SELECT Id, DeveloperName, MasterLabel, Description, Type, SobjectType
            FROM FlexiPage
            WHERE SobjectType = :objectApiName
            AND Type = 'RecordPage'
            ORDER BY MasterLabel
        ];

        for (FlexiPage page : pages) {
            flexiPages.add(new Map<String, Object>{
                'developerName' => page.DeveloperName,
                'label' => page.MasterLabel,
                'description' => page.Description
            });
        }
    } catch (Exception e) {
        throw new AuraHandledException('Error retrieving FlexiPages: ' + e.getMessage());
    }

    return flexiPages;
}

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getObjectFields(String objectApiName) {
    List<Map<String, Object>> fieldList = new List<Map<String, Object>>();

    try {
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjectType == null) {
            throw new IllegalArgumentException('Invalid object API name: ' + objectApiName);
        }

        Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();

            // Include only updateable fields
            if (fieldDescribe.isUpdateable() || fieldDescribe.isCreateable()) {
                fieldList.add(new Map<String, Object>{
                    'apiName' => fieldDescribe.getName(),
                    'label' => fieldDescribe.getLabel(),
                    'type' => String.valueOf(fieldDescribe.getType()),
                    'required' => fieldDescribe.isNillable() == false
                });
            }
        }

        // Sort by label
        fieldList.sort();

    } catch (Exception e) {
        throw new AuraHandledException('Error retrieving object fields: ' + e.getMessage());
    }

    return fieldList;
}
```

### Phase 5: Testing and Refinement

#### 5.1 Test Scenarios

1. **New Configuration**: Create new Flow with component
2. **Edit Existing**: Open existing Flow and modify settings
3. **Object Change**: Change object and verify dependent fields reset
4. **Validation**: Test validation with missing required fields
5. **Flow Variables**: Test record ID selection with Flow variables
6. **Advanced Settings**: Test excluded fields and default values

#### 5.2 Performance Optimization

- Cache frequently used metadata
- Implement debouncing for rapid changes
- Lazy load advanced settings

### Phase 6: Documentation and Deployment

#### 6.1 Create User Documentation

- How to use the CPE
- Configuration options explained
- Best practices for FlexiPage selection
- Default values format guide

#### 6.2 Deployment Steps

1. Deploy CPE component to sandbox
2. Update main component metadata
3. Deploy Apex changes
4. Test in Flow Builder
5. Create change set for production

## Additional Enhancements (Future Phases)

### Enhanced Features

1. **Field Mapping Preview**: Show preview of selected FlexiPage layout
2. **Conditional Settings**: Show/hide settings based on selections
3. **Bulk Default Values**: Import/export default values
4. **Field Set Support**: Allow selection of field sets
5. **Layout Preview**: Visual preview of form layout

### Integration Improvements

1. **External Component Integration**: Integrate with more UnOfficialSF components
2. **Custom Validation Rules**: Define validation rules in CPE
3. **Dynamic Picklist Defaults**: Set picklist defaults based on context
4. **Multi-Object Support**: Configure multiple objects in one component

## Risk Mitigation

### Technical Risks

- **Metadata API Limits**: Implement caching and bulk operations
- **Large Data Volumes**: Paginate field lists for objects with many fields
- **Browser Performance**: Limit DOM manipulation in large forms

### User Experience Risks

- **Complexity**: Use progressive disclosure to manage complexity
- **Error Handling**: Provide clear error messages and recovery options
- **Help Text**: Include contextual help for all settings

## Success Metrics

1. **Configuration Time**: Reduce from 10+ minutes to < 3 minutes
2. **Error Rate**: < 5% validation errors in Flow Builder
3. **User Satisfaction**: Positive feedback on ease of use
4. **Adoption Rate**: 80%+ of implementations use CPE

## Timeline

- **Week 1-2**: Phase 1 & 2 - Basic CPE implementation
- **Week 3**: Phase 3 & 4 - Validation and Apex methods
- **Week 4**: Phase 5 - Testing and refinement
- **Week 5**: Phase 6 - Documentation and deployment
- **Week 6+**: Additional enhancements based on feedback

## Conclusion

This Custom Property Editor will significantly improve the user experience when configuring the FlowRecordDisplay component in Flow Builder. By providing intelligent defaults, dynamic field selection, and clear validation, we'll reduce configuration errors and speed up implementation time.
