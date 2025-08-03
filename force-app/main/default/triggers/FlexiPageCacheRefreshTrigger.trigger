/**
 * @description Trigger for FlexiPage_Cache_Refresh__e Platform Event
 * Handles cache refresh, clear, and refresh-all operations based on platform events
 *
 * @author Marc Swan
 * @date 2025-01-19
 * @version 64.0
 */
trigger FlexiPageCacheRefreshTrigger on FlexiPage_Cache_Refresh__e(
  after insert
) {
  System.debug(
    'FlexiPageCacheRefreshTrigger fired with ' + Trigger.new.size() + ' events'
  );

  for (FlexiPage_Cache_Refresh__e event : Trigger.new) {
    try {
      String action = event.Action__c;
      String developerName = event.FlexiPage_Developer_Name__c;
      String performedByUserId = event.Performed_By_User_Id__c;

      System.debug(
        'Processing cache refresh event - Action: ' +
          action +
          ', FlexiPage: ' +
          developerName +
          ', User: ' +
          performedByUserId
      );

      // Process different actions
      if (action == 'Refresh') {
        if (String.isNotBlank(developerName)) {
          FlexiPageCacheService.refreshCache(developerName);
          System.debug('Cache refreshed for FlexiPage: ' + developerName);
        } else {
          System.debug(
            'ERROR: Refresh action requires FlexiPage developer name'
          );
        }
      } else if (action == 'Clear') {
        if (String.isNotBlank(developerName)) {
          FlexiPageCacheService.clearCache(developerName);
          System.debug('Cache cleared for FlexiPage: ' + developerName);
        } else {
          System.debug('ERROR: Clear action requires FlexiPage developer name');
        }
      } else if (action == 'RefreshAll') {
        FlexiPageCacheService.clearAllCache();
        System.debug('All cache cleared');
      } else {
        System.debug('ERROR: Unknown action: ' + action);
      }
    } catch (Exception e) {
      System.debug('ERROR processing cache refresh event: ' + e.getMessage());
      System.debug('Stack trace: ' + e.getStackTraceString());

      // Platform Event triggers can't throw exceptions that would rollback
      // the event processing, so we just log errors
    }
  }
}
