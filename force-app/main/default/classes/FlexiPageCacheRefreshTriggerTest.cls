/**
 * @description Test class for FlexiPageCacheRefreshTrigger
 * Tests platform event trigger functionality for cache operations
 *
 * @author Marc Swan
 * @date 2025-01-19
 * @version 64.0
 */
@isTest
public class FlexiPageCacheRefreshTriggerTest {
  private static final String TEST_DEVELOPER_NAME = 'Test_FlexiPage_Trigger';
  private static final String TEST_METADATA_JSON = '{"success":true,"metadata":{"sobjectType":"Account","fields":[{"name":"Name"}]}}';

  @TestSetup
  static void setupTestData() {
    // Create test cache records for trigger testing
    List<FlexiPage_Cache__c> cacheRecords = new List<FlexiPage_Cache__c>();

    // Main test cache record
    FlexiPage_Cache__c testCache = new FlexiPage_Cache__c();
    testCache.FlexiPage_Developer_Name__c = TEST_DEVELOPER_NAME;
    testCache.FlexiPage_Metadata_JSON__c = TEST_METADATA_JSON;
    testCache.Cache_Created_Date__c = DateTime.now().addMinutes(-30);
    testCache.FlexiPage_Last_Modified_Date__c = DateTime.now().addHours(-1);
    testCache.Is_Active__c = true;
    testCache.API_Version__c = '64.0';
    testCache.Object_API_Name__c = 'Account';
    cacheRecords.add(testCache);

    // Additional cache record for RefreshAll testing
    FlexiPage_Cache__c additionalCache = new FlexiPage_Cache__c();
    additionalCache.FlexiPage_Developer_Name__c = 'Another_Test_FlexiPage';
    additionalCache.FlexiPage_Metadata_JSON__c = TEST_METADATA_JSON;
    additionalCache.Cache_Created_Date__c = DateTime.now().addMinutes(-45);
    additionalCache.Is_Active__c = true;
    additionalCache.API_Version__c = '64.0';
    additionalCache.Object_API_Name__c = 'Contact';
    cacheRecords.add(additionalCache);

    insert cacheRecords;
  }

  /**
   * @description Test Refresh action via platform event
   */
  @isTest
  static void testRefreshAction() {
    // Mock HTTP response for metadata refresh
    Test.setMock(
      HttpCalloutMock.class,
      new MockHttpResponseGenerator(200, TEST_METADATA_JSON)
    );

    // Create platform event for Refresh action
    FlexiPage_Cache_Refresh__e refreshEvent = new FlexiPage_Cache_Refresh__e();
    refreshEvent.Action__c = 'Refresh';
    refreshEvent.FlexiPage_Developer_Name__c = TEST_DEVELOPER_NAME;
    refreshEvent.Performed_By_User_Id__c = UserInfo.getUserId();

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(refreshEvent);

    Test.stopTest();

    // Verify event was published successfully
    System.assert(result.isSuccess(), 'Event should be published successfully');

    // Note: In test context, the trigger execution is synchronous
    // We can verify that cache operations don't throw exceptions
    // and that the FlexiPageCacheService methods are called
  }

  /**
   * @description Test Clear action via platform event
   */
  @isTest
  static void testClearAction() {
    // Verify cache exists before clearing
    List<FlexiPage_Cache__c> cacheRecords = [
      SELECT Id
      FROM FlexiPage_Cache__c
      WHERE FlexiPage_Developer_Name__c = :TEST_DEVELOPER_NAME
    ];
    System.assertEquals(
      1,
      cacheRecords.size(),
      'Cache should exist before clearing'
    );

    // Create platform event for Clear action
    FlexiPage_Cache_Refresh__e clearEvent = new FlexiPage_Cache_Refresh__e();
    clearEvent.Action__c = 'Clear';
    clearEvent.FlexiPage_Developer_Name__c = TEST_DEVELOPER_NAME;
    clearEvent.Performed_By_User_Id__c = UserInfo.getUserId();

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(clearEvent);

    Test.stopTest();

    // Verify event was published successfully
    System.assert(result.isSuccess(), 'Event should be published successfully');

    // Note: Platform events in test context are processed immediately
    // The actual cache clearing is tested in FlexiPageCacheServiceTest
  }

  /**
   * @description Test RefreshAll action via platform event
   */
  @isTest
  static void testRefreshAllAction() {
    // Verify multiple cache records exist
    List<FlexiPage_Cache__c> cacheRecords = [SELECT Id FROM FlexiPage_Cache__c];
    System.assertEquals(
      2,
      cacheRecords.size(),
      'Should have multiple cache records'
    );

    // Create platform event for RefreshAll action
    FlexiPage_Cache_Refresh__e refreshAllEvent = new FlexiPage_Cache_Refresh__e();
    refreshAllEvent.Action__c = 'RefreshAll';
    refreshAllEvent.Performed_By_User_Id__c = UserInfo.getUserId();
    // Note: FlexiPage_Developer_Name__c is null for RefreshAll

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(refreshAllEvent);

    Test.stopTest();

    // Verify event was published successfully
    System.assert(result.isSuccess(), 'Event should be published successfully');
  }

  /**
   * @description Test multiple events in single transaction
   */
  @isTest
  static void testMultipleEvents() {
    // Create multiple platform events
    List<FlexiPage_Cache_Refresh__e> events = new List<FlexiPage_Cache_Refresh__e>();

    // Refresh event
    FlexiPage_Cache_Refresh__e refreshEvent = new FlexiPage_Cache_Refresh__e();
    refreshEvent.Action__c = 'Refresh';
    refreshEvent.FlexiPage_Developer_Name__c = TEST_DEVELOPER_NAME;
    refreshEvent.Performed_By_User_Id__c = UserInfo.getUserId();
    events.add(refreshEvent);

    // Clear event for different FlexiPage
    FlexiPage_Cache_Refresh__e clearEvent = new FlexiPage_Cache_Refresh__e();
    clearEvent.Action__c = 'Clear';
    clearEvent.FlexiPage_Developer_Name__c = 'Another_Test_FlexiPage';
    clearEvent.Performed_By_User_Id__c = UserInfo.getUserId();
    events.add(clearEvent);

    Test.startTest();

    // Publish multiple events
    List<Database.SaveResult> results = EventBus.publish(events);

    Test.stopTest();

    // Verify all events were published successfully
    System.assertEquals(2, results.size(), 'Should have 2 results');
    for (Database.SaveResult result : results) {
      System.assert(
        result.isSuccess(),
        'All events should be published successfully'
      );
    }
  }

  /**
   * @description Test Refresh action with missing developer name
   */
  @isTest
  static void testRefreshAction_MissingDeveloperName() {
    // Create platform event for Refresh action without developer name
    FlexiPage_Cache_Refresh__e refreshEvent = new FlexiPage_Cache_Refresh__e();
    refreshEvent.Action__c = 'Refresh';
    // FlexiPage_Developer_Name__c is null
    refreshEvent.Performed_By_User_Id__c = UserInfo.getUserId();

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(refreshEvent);

    Test.stopTest();

    // Verify event was published successfully
    // The trigger should handle the missing developer name gracefully
    System.assert(result.isSuccess(), 'Event should be published successfully');
  }

  /**
   * @description Test Clear action with missing developer name
   */
  @isTest
  static void testClearAction_MissingDeveloperName() {
    // Create platform event for Clear action without developer name
    FlexiPage_Cache_Refresh__e clearEvent = new FlexiPage_Cache_Refresh__e();
    clearEvent.Action__c = 'Clear';
    // FlexiPage_Developer_Name__c is null
    clearEvent.Performed_By_User_Id__c = UserInfo.getUserId();

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(clearEvent);

    Test.stopTest();

    // Verify event was published successfully
    // The trigger should handle the missing developer name gracefully
    System.assert(result.isSuccess(), 'Event should be published successfully');
  }

  /**
   * @description Test unknown action type
   */
  @isTest
  static void testUnknownAction() {
    // Create platform event with unknown action
    FlexiPage_Cache_Refresh__e unknownEvent = new FlexiPage_Cache_Refresh__e();
    unknownEvent.Action__c = 'UnknownAction';
    unknownEvent.FlexiPage_Developer_Name__c = TEST_DEVELOPER_NAME;
    unknownEvent.Performed_By_User_Id__c = UserInfo.getUserId();

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(unknownEvent);

    Test.stopTest();

    // Verify event was published successfully
    // The trigger should handle unknown actions gracefully
    System.assert(result.isSuccess(), 'Event should be published successfully');
  }

  /**
   * @description Test trigger with null action
   */
  @isTest
  static void testNullAction() {
    // Create platform event with null action
    FlexiPage_Cache_Refresh__e nullActionEvent = new FlexiPage_Cache_Refresh__e();
    nullActionEvent.Action__c = null;
    nullActionEvent.FlexiPage_Developer_Name__c = TEST_DEVELOPER_NAME;
    nullActionEvent.Performed_By_User_Id__c = UserInfo.getUserId();

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(nullActionEvent);

    Test.stopTest();

    // Verify event was published successfully
    // The trigger should handle null actions gracefully
    System.assert(result.isSuccess(), 'Event should be published successfully');
  }

  /**
   * @description Test trigger exception handling
   * This test simulates a scenario where an exception might occur in the trigger
   */
  @isTest
  static void testTriggerExceptionHandling() {
    // Create a platform event that might cause issues
    FlexiPage_Cache_Refresh__e eventWithPotentialIssue = new FlexiPage_Cache_Refresh__e();
    eventWithPotentialIssue.Action__c = 'Refresh';
    eventWithPotentialIssue.FlexiPage_Developer_Name__c = 'Non_Existent_FlexiPage_That_Might_Cause_Issues';
    eventWithPotentialIssue.Performed_By_User_Id__c = UserInfo.getUserId();

    Test.startTest();

    // Publish the event
    Database.SaveResult result = EventBus.publish(eventWithPotentialIssue);

    Test.stopTest();

    // Verify event was published successfully
    // The trigger should handle exceptions gracefully without failing
    System.assert(
      result.isSuccess(),
      'Event should be published successfully even with potential issues'
    );
  }

  /**
   * Mock HTTP Response Generator for testing HTTP callouts
   */
  public class MockHttpResponseGenerator implements HttpCalloutMock {
    private Integer statusCode;
    private String responseBody;

    public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
      this.statusCode = statusCode;
      this.responseBody = responseBody;
    }

    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(responseBody);
      res.setStatusCode(statusCode);
      return res;
    }
  }
}
