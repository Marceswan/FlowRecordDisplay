import { createElement } from "lwc";
import FlexipageRecordFormCPE from "c/flexipageRecordFormCPE";
import getFlexiPageFields from "@salesforce/apex/FlexiPageMetadataService.getFlexiPageFields";
import getObjectFields from "@salesforce/apex/FlexiPageToolingService.getObjectFields";
import { ShowToastEventName } from "lightning/platformShowToastEvent";

// Mock Apex methods
jest.mock(
  "@salesforce/apex/FlexiPageMetadataService.getFlexiPageFields",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/FlexiPageToolingService.getObjectFields",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

// Helper function to wait for promises
const flushPromises = () => Promise.resolve().then(() => Promise.resolve());

describe("c-flexipage-record-form-cpe", () => {
  afterEach(() => {
    // Clear all mocks
    jest.clearAllMocks();

    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("should extract fields from complex FlexiPage metadata structure", async () => {
    // Create element
    const element = createElement("c-flexipage-record-form-cpe", {
      is: FlexipageRecordFormCPE
    });

    // Mock the actual metadata structure from the user
    const mockFlexiPageFields = [
      {
        fieldName: "OwnerId",
        section: "Facet-0ab55fc9-0cbd-4425-84d0-a90d8b25edf8",
        position: 1
      },
      {
        fieldName: "IsPrivate",
        section: "Facet-0ab55fc9-0cbd-4425-84d0-a90d8b25edf8",
        position: 2
      },
      {
        fieldName: "Name",
        section: "Facet-0ab55fc9-0cbd-4425-84d0-a90d8b25edf8",
        position: 3
      },
      {
        fieldName: "AccountId",
        section: "Facet-0ab55fc9-0cbd-4425-84d0-a90d8b25edf8",
        position: 4
      },
      {
        fieldName: "Type",
        section: "Facet-0ab55fc9-0cbd-4425-84d0-a90d8b25edf8",
        position: 5
      },
      {
        fieldName: "LeadSource",
        section: "Facet-0ab55fc9-0cbd-4425-84d0-a90d8b25edf8",
        position: 6
      },
      {
        fieldName: "Sub_Stage__c",
        section: "Facet-0ab55fc9-0cbd-4425-84d0-a90d8b25edf8",
        position: 7
      },
      {
        fieldName: "Amount",
        section: "Facet-b10a35b7-1c9d-46eb-af65-abda91eeb95d",
        position: 1
      },
      {
        fieldName: "ExpectedRevenue",
        section: "Facet-b10a35b7-1c9d-46eb-af65-abda91eeb95d",
        position: 2
      },
      {
        fieldName: "CloseDate",
        section: "Facet-b10a35b7-1c9d-46eb-af65-abda91eeb95d",
        position: 3
      },
      {
        fieldName: "StageName",
        section: "Facet-b10a35b7-1c9d-46eb-af65-abda91eeb95d",
        position: 4
      },
      {
        fieldName: "Probability",
        section: "Facet-b10a35b7-1c9d-46eb-af65-abda91eeb95d",
        position: 6
      },
      {
        fieldName: "OrderNumber__c",
        section: "Facet-874f9d33-d4d8-4d99-be94-76215c9eb06b",
        position: 1
      },
      {
        fieldName: "CurrentGenerators__c",
        section: "Facet-874f9d33-d4d8-4d99-be94-76215c9eb06b",
        position: 2
      },
      {
        fieldName: "TrackingNumber__c",
        section: "Facet-874f9d33-d4d8-4d99-be94-76215c9eb06b",
        position: 3
      },
      {
        fieldName: "CampaignId",
        section: "Facet-c99671ad-bcd7-44fe-9418-2620a67f536a",
        position: 1
      },
      {
        fieldName: "MainCompetitors__c",
        section: "Facet-c99671ad-bcd7-44fe-9418-2620a67f536a",
        position: 2
      },
      {
        fieldName: "DeliveryInstallationStatus__c",
        section: "Facet-c99671ad-bcd7-44fe-9418-2620a67f536a",
        position: 3
      },
      {
        fieldName: "CreatedById",
        section: "Facet-00cc11ba-dac6-4dda-bf8e-66fb400e612b",
        position: 1
      },
      {
        fieldName: "LastModifiedById",
        section: "Facet-1e6f00fc-7552-4f8d-b75d-e0d7920dd0ac",
        position: 1
      },
      {
        fieldName: "Description",
        section: "Facet-84103a87-a146-486e-a3fc-98b28acfa515",
        position: 1
      },
      {
        fieldName: "Source__c",
        section: "Facet-84103a87-a146-486e-a3fc-98b28acfa515",
        position: 2
      },
      {
        fieldName: "NextStep",
        section: "Facet-84103a87-a146-486e-a3fc-98b28acfa515",
        position: 3
      }
    ];

    const mockObjectFields = mockFlexiPageFields.map((field) => ({
      apiName: field.fieldName,
      label: field.fieldName.replace(/__c$/g, "").replace(/_/g, " "),
      type: "STRING"
    }));

    getFlexiPageFields.mockResolvedValue(mockFlexiPageFields);
    getObjectFields.mockResolvedValue(mockObjectFields);

    // Set up component
    element.objectApiName = "Opportunity";
    element.selectedFlexiPage = "Opportunity_Record_Page";

    document.body.appendChild(element);

    // Trigger field loading
    await element.loadFields();
    await flushPromises();

    // Verify fields were extracted
    expect(element.fieldOptions).toHaveLength(20); // 23 fields minus 3 system fields
    expect(element.flexiPageFields).toHaveLength(23);

    // Verify field options contain the expected fields
    const fieldApiNames = element.fieldOptions.map((f) => f.value);
    expect(fieldApiNames).toContain("Name");
    expect(fieldApiNames).toContain("Amount");
    expect(fieldApiNames).toContain("CloseDate");
    expect(fieldApiNames).toContain("StageName");
    expect(fieldApiNames).not.toContain("CreatedById");
    expect(fieldApiNames).not.toContain("LastModifiedById");
  });

  it("should show error when trying to open modal without FlexiPage selected", async () => {
    const element = createElement("c-flexipage-record-form-cpe", {
      is: FlexipageRecordFormCPE
    });

    element.objectApiName = "Opportunity";
    // No FlexiPage selected
    element.selectedFlexiPage = null;

    document.body.appendChild(element);

    // Listen for toast events
    const handler = jest.fn();
    element.addEventListener(ShowToastEventName, handler);

    // Try to open excluded fields modal
    element.openExcludedFieldsModal();

    // Should show error toast
    expect(handler).toHaveBeenCalled();
    expect(handler.mock.calls[0][0].detail.message).toBe(
      "Please select a FlexiPage layout first"
    );
    expect(element.showExcludedFieldsModal).toBe(false);
  });

  it("should load fields when opening modal if not already loaded", async () => {
    const element = createElement("c-flexipage-record-form-cpe", {
      is: FlexipageRecordFormCPE
    });

    const mockFields = [
      { fieldName: "Name", section: "main", position: 1 },
      { fieldName: "Amount", section: "main", position: 2 }
    ];

    const mockObjectFields = [
      { apiName: "Name", label: "Name", type: "STRING" },
      { apiName: "Amount", label: "Amount", type: "CURRENCY" }
    ];

    getFlexiPageFields.mockResolvedValue(mockFields);
    getObjectFields.mockResolvedValue(mockObjectFields);

    element.objectApiName = "Opportunity";
    element.selectedFlexiPage = "Opportunity_Record_Page";

    // Ensure fields are not loaded yet
    element.fieldOptions = [];
    element.flexiPageFields = [];

    document.body.appendChild(element);

    // Open modal
    element.openDefaultValuesModal();
    await flushPromises();

    // Verify fields were loaded
    expect(getFlexiPageFields).toHaveBeenCalledWith({
      developerName: "Opportunity_Record_Page"
    });
    expect(getObjectFields).toHaveBeenCalledWith({
      objectApiName: "Opportunity"
    });

    expect(element.showDefaultValuesModal).toBe(true);
    expect(element.fieldOptions).toHaveLength(2);
  });

  it("should handle empty FlexiPage fields gracefully", async () => {
    const element = createElement("c-flexipage-record-form-cpe", {
      is: FlexipageRecordFormCPE
    });

    // Mock empty FlexiPage fields but with object fields available
    const mockObjectFields = [
      { apiName: "Name", label: "Name", type: "STRING" },
      { apiName: "Amount", label: "Amount", type: "CURRENCY" },
      { apiName: "CloseDate", label: "Close Date", type: "DATE" }
    ];

    getFlexiPageFields.mockResolvedValue([]); // No fields in FlexiPage
    getObjectFields.mockResolvedValue(mockObjectFields);

    element.objectApiName = "Opportunity";
    element.selectedFlexiPage = "Opportunity_Record_Page";

    document.body.appendChild(element);

    await element.loadFields();
    await flushPromises();

    // Should fall back to all object fields
    expect(element.fieldOptions).toHaveLength(3);
    expect(element.fieldOptions[0].value).toBe("Name");
    expect(element.fieldOptions[1].value).toBe("Amount");
    expect(element.fieldOptions[2].value).toBe("CloseDate");
  });
});
