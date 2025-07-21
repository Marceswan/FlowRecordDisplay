@isTest
private class FlexiPageToolingServiceTest {
  private static final String TEST_FLEXIPAGE_NAME = 'Account_Record_Page';
  private static final String TEST_OBJECT_API_NAME = 'Account';
  private static final String TEST_RECORD_ID = '001xx000003DGb0AAG';

  @isTest
  static void testGetFlexiPageMetadata_Success() {
    Test.setMock(HttpCalloutMock.class, new FlexiPageToolingServiceMock(false));

    Test.startTest();
    String result = FlexiPageToolingService.getFlexiPageMetadata(
      TEST_FLEXIPAGE_NAME
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      result
    );
    // Check if the result is the new format from FlexiPageMetadataService
    if (resultMap.containsKey('success')) {
      System.assertEquals(
        true,
        resultMap.get('success'),
        'Result should indicate success'
      );
      System.assert(
        resultMap.containsKey('metadata'),
        'Result should contain metadata'
      );
      Map<String, Object> metadata = (Map<String, Object>) resultMap.get(
        'metadata'
      );
      System.assert(
        metadata != null &&
        (metadata.containsKey('type') || metadata.containsKey('fullName')),
        'Result should contain FlexiPage metadata: ' +
        (metadata != null
          ? 'Expected: FlexiPage, Actual: ' + metadata.get('type')
          : 'Expected: FlexiPage, Actual: null')
      );
    } else {
      // Old format - direct metadata
      System.assert(
        resultMap.containsKey('type') || resultMap.containsKey('fullName'),
        'Result should contain FlexiPage metadata'
      );
    }
  }

  @isTest
  static void testGetFlexiPageMetadata_NoRecordsFound() {
    Test.setMock(HttpCalloutMock.class, new FlexiPageToolingServiceMock(true));

    Test.startTest();
    // Use NonExistent_Page to trigger the not found scenario
    String result = FlexiPageToolingService.getFlexiPageMetadata(
      'NonExistent_Page'
    );
    Test.stopTest();

    // The new implementation returns error in JSON format
    System.assertNotEquals(null, result, 'Result should not be null');
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      result
    );

    // Check if it's an error response
    if (resultMap.containsKey('success')) {
      System.assertEquals(
        false,
        resultMap.get('success'),
        'Result should indicate failure'
      );
      System.assert(
        resultMap.containsKey('message') || resultMap.containsKey('error'),
        'Result should contain error message'
      );
    } else {
      // Old format would throw exception, but this shouldn't happen with new implementation
      System.assert(false, 'Unexpected response format');
    }
  }

  @isTest
  static void testGetFieldValues_Success() {
    Account testAccount = new Account(
      Name = 'Test Account',
      Type = 'Customer',
      Industry = 'Technology',
      AnnualRevenue = 1000000
    );
    insert testAccount;

    // Query the record back to verify the Name field
    Account insertedAccount = [
      SELECT Id, Name
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    System.debug('Inserted Account Name: ' + insertedAccount.Name);

    Test.startTest();
    List<String> fieldApiNames = new List<String>{ 'Name', 'AnnualRevenue' };
    Map<String, Object> result = FlexiPageToolingService.getFieldValues(
      testAccount.Id,
      TEST_OBJECT_API_NAME,
      fieldApiNames
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.debug('Result: ' + result);

    // Check structure of new response format
    System.assert(
      result.containsKey('values'),
      'Result should contain values map'
    );
    System.assert(
      result.containsKey('metadata'),
      'Result should contain metadata map'
    );

    Map<String, Object> values = (Map<String, Object>) result.get('values');
    if (values.containsKey('name')) {
      System.assertEquals(
        'Test Account',
        (String) values.get('name'),
        'Name field should match'
      );
    } else {
      System.assert(false, 'Name field is missing from the values');
    }
  }

  @isTest
  static void testGetFieldValues_InvalidObject() {
    Test.startTest();
    try {
      FlexiPageToolingService.getFieldValues(
        TEST_RECORD_ID,
        'InvalidObject',
        new List<String>()
      );
      System.assert(false, 'Exception should have been thrown');
    } catch (AuraHandledException e) {
      System.assertEquals(
        'Script-thrown exception',
        e.getMessage(),
        'Incorrect exception message'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testGetAllSObjects() {
    Test.startTest();
    List<Map<String, Object>> result = FlexiPageToolingService.getAllSObjects();
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assert(result.size() > 0, 'Should return at least one sObject');

    // Verify structure of returned data
    Map<String, Object> firstObject = result[0];
    System.assert(
      firstObject.containsKey('value'),
      'Each sObject should have a value'
    );
    System.assert(
      firstObject.containsKey('label'),
      'Each sObject should have a label'
    );
    System.assert(
      firstObject.containsKey('isCustom'),
      'Each sObject should have isCustom flag'
    );

    // Verify Account object is included (should always exist)
    Boolean foundAccount = false;
    for (Map<String, Object> sObj : result) {
      if (sObj.get('value') == 'Account') {
        foundAccount = true;
        System.assertEquals(
          false,
          sObj.get('isCustom'),
          'Account should not be custom'
        );
        break;
      }
    }
    System.assert(foundAccount, 'Account object should be in the list');
  }

  @isTest
  static void testGetObjectFields() {
    Test.startTest();
    List<Map<String, Object>> result = FlexiPageToolingService.getObjectFields(
      'Account'
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assert(result.size() > 0, 'Should return at least one field');

    // Verify structure of returned data
    Map<String, Object> firstField = result[0];
    System.assert(
      firstField.containsKey('apiName'),
      'Each field should have apiName'
    );
    System.assert(
      firstField.containsKey('label'),
      'Each field should have label'
    );
    System.assert(
      firstField.containsKey('type'),
      'Each field should have type'
    );
    System.assert(
      firstField.containsKey('required'),
      'Each field should have required flag'
    );

    // Verify Name field is included (should always exist for Account)
    Boolean foundName = false;
    for (Map<String, Object> field : result) {
      if (field.get('apiName') == 'Name') {
        foundName = true;
        System.assertEquals(
          'STRING',
          field.get('type'),
          'Name should be STRING type'
        );
        break;
      }
    }
    System.assert(foundName, 'Name field should be in the list');
  }

  @isTest
  static void testGetObjectFields_InvalidObject() {
    Test.startTest();
    try {
      FlexiPageToolingService.getObjectFields('InvalidObject');
      System.assert(false, 'Exception should have been thrown');
    } catch (AuraHandledException e) {
      // AuraHandledException returns "Script-thrown exception" as the message
      System.assertEquals(
        'Script-thrown exception',
        e.getMessage(),
        'Incorrect exception message'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testGetAvailableFlexiPages() {
    // Mock the HTTP callout
    Test.setMock(HttpCalloutMock.class, new FlexiPageAvailableMock());

    Test.startTest();
    List<Map<String, Object>> result = FlexiPageToolingService.getAvailableFlexiPages(
      'Account'
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    // In mock, we should get the expected results
  }

  @isTest
  static void testSObjectComparator() {
    // Create test data for sorting
    List<Map<String, Object>> testList = new List<Map<String, Object>>();

    Map<String, Object> customObj = new Map<String, Object>();
    customObj.put('value', 'Custom__c');
    customObj.put('label', 'Custom Object (Custom__c)');
    customObj.put('isCustom', true);
    testList.add(customObj);

    Map<String, Object> standardObj1 = new Map<String, Object>();
    standardObj1.put('value', 'Contact');
    standardObj1.put('label', 'Contact (Contact)');
    standardObj1.put('isCustom', false);
    testList.add(standardObj1);

    Map<String, Object> standardObj2 = new Map<String, Object>();
    standardObj2.put('value', 'Account');
    standardObj2.put('label', 'Account (Account)');
    standardObj2.put('isCustom', false);
    testList.add(standardObj2);

    Test.startTest();
    testList.sort(new FlexiPageToolingService.SObjectComparator());
    Test.stopTest();

    // Verify sorting: standard objects should come first, then custom
    System.assertEquals(
      'Account',
      testList[0].get('value'),
      'Account should be first (standard, alphabetical)'
    );
    System.assertEquals(
      'Contact',
      testList[1].get('value'),
      'Contact should be second (standard, alphabetical)'
    );
    System.assertEquals(
      'Custom__c',
      testList[2].get('value'),
      'Custom__c should be last (custom)'
    );
  }

  private class FlexiPageToolingServiceMock implements HttpCalloutMock {
    private Boolean returnEmptyResults;

    public FlexiPageToolingServiceMock(Boolean returnEmptyResults) {
      this.returnEmptyResults = returnEmptyResults;
    }

    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);

      if (returnEmptyResults) {
        res.setBody('{"records":[]}');
      } else {
        res.setBody(
          '{"records":[{"Metadata":{"type":"FlexiPage","fullName":"' +
            TEST_FLEXIPAGE_NAME +
            '"}}]}'
        );
      }

      return res;
    }
  }

  private class FlexiPageAvailableMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);

      // Mock response for available FlexiPages
      String responseBody =
        '{"records":[' +
        '{"Id":"0M0xx0000000001","DeveloperName":"Account_Record_Page","MasterLabel":"Account Record Page","Description":"Standard Account page","Metadata":{"sobjectType":"Account"}},' +
        '{"Id":"0M0xx0000000002","DeveloperName":"Account_Custom_Page","MasterLabel":"Account Custom Page","Description":"Custom Account page","Metadata":{"sobjectType":"Account"}}' +
        ']}';
      res.setBody(responseBody);

      return res;
    }
  }
}
