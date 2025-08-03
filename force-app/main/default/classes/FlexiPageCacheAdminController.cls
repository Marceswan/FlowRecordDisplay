/**
 * @description Admin controller for FlexiPage cache management
 * Provides administrative functions for cache monitoring, refresh, and clearing
 *
 * @author Marc Swan
 * @date 2025-01-19
 * @version 64.0
 */
public with sharing class FlexiPageCacheAdminController {
  /**
   * @description Wrapper class for cache record information
   */
  public class CacheRecordInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String developerName;
    @AuraEnabled
    public String objectApiName;
    @AuraEnabled
    public DateTime cacheCreatedDate;
    @AuraEnabled
    public DateTime flexiPageLastModifiedDate;
    @AuraEnabled
    public Boolean isActive;
    @AuraEnabled
    public String apiVersion;
    @AuraEnabled
    public Integer ageInMinutes;
    @AuraEnabled
    public String status; // Valid, Stale, Unknown

    public CacheRecordInfo(FlexiPage_Cache__c record) {
      this.id = record.Id;
      this.developerName = record.FlexiPage_Developer_Name__c;
      this.objectApiName = record.Object_API_Name__c;
      this.cacheCreatedDate = record.Cache_Created_Date__c;
      this.flexiPageLastModifiedDate = record.FlexiPage_Last_Modified_Date__c;
      this.isActive = record.Is_Active__c;
      this.apiVersion = record.API_Version__c;

      // Calculate age in minutes
      if (this.cacheCreatedDate != null) {
        this.ageInMinutes = (Integer) ((DateTime.now().getTime() -
        this.cacheCreatedDate.getTime()) / (1000 * 60));
      }

      // Determine status
      this.status = determineStatus();
    }

    private String determineStatus() {
      if (this.cacheCreatedDate == null) {
        return 'Unknown';
      }

      // Check if cache is older than 60 minutes (default timeout)
      if (this.ageInMinutes != null && this.ageInMinutes > 60) {
        return 'Stale';
      }

      return 'Valid';
    }
  }

  /**
   * @description Gets all cache records with status information
   * @return List of CacheRecordInfo with status details
   */
  @AuraEnabled(cacheable=true)
  public static List<CacheRecordInfo> getAllCacheRecords() {
    try {
      List<FlexiPage_Cache__c> cacheRecords = [
        SELECT
          Id,
          FlexiPage_Developer_Name__c,
          Object_API_Name__c,
          Cache_Created_Date__c,
          FlexiPage_Last_Modified_Date__c,
          Is_Active__c,
          API_Version__c
        FROM FlexiPage_Cache__c
        ORDER BY Cache_Created_Date__c DESC
      ];

      List<CacheRecordInfo> cacheInfoList = new List<CacheRecordInfo>();
      for (FlexiPage_Cache__c record : cacheRecords) {
        cacheInfoList.add(new CacheRecordInfo(record));
      }

      return cacheInfoList;
    } catch (Exception e) {
      System.debug('Error getting cache records: ' + e.getMessage());
      throw new AuraHandledException(
        'Error retrieving cache records: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Gets cache statistics for dashboard display
   * @return Map containing various cache statistics
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getCacheStatistics() {
    try {
      return FlexiPageCacheService.getCacheStatistics();
    } catch (Exception e) {
      System.debug('Error getting cache statistics: ' + e.getMessage());
      throw new AuraHandledException(
        'Error retrieving cache statistics: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Refreshes cache for a specific FlexiPage
   * @param developerName The FlexiPage developer name to refresh
   * @return Success message
   */
  @AuraEnabled
  public static String refreshSpecificCache(String developerName) {
    try {
      if (String.isBlank(developerName)) {
        throw new AuraHandledException(
          'Developer name is required for cache refresh'
        );
      }

      // Publish platform event for cache refresh
      FlexiPageCacheService.publishCacheRefreshEvent('Refresh', developerName);

      return 'Cache refresh initiated for: ' + developerName;
    } catch (Exception e) {
      System.debug('Error refreshing specific cache: ' + e.getMessage());
      throw new AuraHandledException(
        'Error refreshing cache: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Clears cache for a specific FlexiPage
   * @param developerName The FlexiPage developer name to clear
   * @return Success message
   */
  @AuraEnabled
  public static String clearSpecificCache(String developerName) {
    try {
      if (String.isBlank(developerName)) {
        throw new AuraHandledException(
          'Developer name is required for cache clearing'
        );
      }

      // Publish platform event for cache clearing
      FlexiPageCacheService.publishCacheRefreshEvent('Clear', developerName);

      return 'Cache clearing initiated for: ' + developerName;
    } catch (Exception e) {
      System.debug('Error clearing specific cache: ' + e.getMessage());
      throw new AuraHandledException('Error clearing cache: ' + e.getMessage());
    }
  }

  /**
   * @description Clears all cache records
   * @return Success message
   */
  @AuraEnabled
  public static String clearAllCache() {
    try {
      // Publish platform event for clearing all cache
      FlexiPageCacheService.publishCacheRefreshEvent('RefreshAll', null);

      return 'All cache clearing initiated';
    } catch (Exception e) {
      System.debug('Error clearing all cache: ' + e.getMessage());
      throw new AuraHandledException(
        'Error clearing all cache: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Gets list of stale cache records
   * @return List of CacheRecordInfo for stale records
   */
  @AuraEnabled(cacheable=true)
  public static List<CacheRecordInfo> getStaleCacheRecords() {
    try {
      List<CacheRecordInfo> allRecords = getAllCacheRecords();
      List<CacheRecordInfo> staleRecords = new List<CacheRecordInfo>();

      for (CacheRecordInfo record : allRecords) {
        if (record.status == 'Stale') {
          staleRecords.add(record);
        }
      }

      return staleRecords;
    } catch (Exception e) {
      System.debug('Error getting stale cache records: ' + e.getMessage());
      throw new AuraHandledException(
        'Error retrieving stale cache records: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Refreshes all stale cache records
   * @return Success message with count of records processed
   */
  @AuraEnabled
  public static String refreshStaleCacheRecords() {
    try {
      List<CacheRecordInfo> staleRecords = getStaleCacheRecords();

      for (CacheRecordInfo record : staleRecords) {
        FlexiPageCacheService.publishCacheRefreshEvent(
          'Refresh',
          record.developerName
        );
      }

      return 'Cache refresh initiated for ' +
        staleRecords.size() +
        ' stale records';
    } catch (Exception e) {
      System.debug('Error refreshing stale cache records: ' + e.getMessage());
      throw new AuraHandledException(
        'Error refreshing stale cache records: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Gets cache records by object API name
   * @param objectApiName The object API name to filter by
   * @return List of CacheRecordInfo for the specified object
   */
  @AuraEnabled(cacheable=true)
  public static List<CacheRecordInfo> getCacheRecordsByObject(
    String objectApiName
  ) {
    try {
      if (String.isBlank(objectApiName)) {
        return new List<CacheRecordInfo>();
      }

      List<FlexiPage_Cache__c> cacheRecords = [
        SELECT
          Id,
          FlexiPage_Developer_Name__c,
          Object_API_Name__c,
          Cache_Created_Date__c,
          FlexiPage_Last_Modified_Date__c,
          Is_Active__c,
          API_Version__c
        FROM FlexiPage_Cache__c
        WHERE Object_API_Name__c = :objectApiName
        ORDER BY Cache_Created_Date__c DESC
      ];

      List<CacheRecordInfo> cacheInfoList = new List<CacheRecordInfo>();
      for (FlexiPage_Cache__c record : cacheRecords) {
        cacheInfoList.add(new CacheRecordInfo(record));
      }

      return cacheInfoList;
    } catch (Exception e) {
      System.debug('Error getting cache records by object: ' + e.getMessage());
      throw new AuraHandledException(
        'Error retrieving cache records by object: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Gets distinct object API names from cache records
   * @return List of object API names
   */
  @AuraEnabled(cacheable=true)
  public static List<String> getDistinctObjectApiNames() {
    try {
      List<AggregateResult> results = [
        SELECT Object_API_Name__c
        FROM FlexiPage_Cache__c
        WHERE Object_API_Name__c != NULL
        GROUP BY Object_API_Name__c
        ORDER BY Object_API_Name__c
      ];

      List<String> objectNames = new List<String>();
      for (AggregateResult result : results) {
        String objectName = (String) result.get('Object_API_Name__c');
        if (String.isNotBlank(objectName)) {
          objectNames.add(objectName);
        }
      }

      return objectNames;
    } catch (Exception e) {
      System.debug(
        'Error getting distinct object API names: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error retrieving object API names: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Validates cache health and returns summary
   * @return Map containing cache health information
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getCacheHealthSummary() {
    try {
      List<CacheRecordInfo> allRecords = getAllCacheRecords();
      Map<String, Object> healthSummary = new Map<String, Object>();

      Integer totalRecords = allRecords.size();
      Integer validRecords = 0;
      Integer staleRecords = 0;
      Integer unknownRecords = 0;

      for (CacheRecordInfo record : allRecords) {
        if (record.status == 'Valid') {
          validRecords++;
        } else if (record.status == 'Stale') {
          staleRecords++;
        } else {
          unknownRecords++;
        }
      }

      healthSummary.put('totalRecords', totalRecords);
      healthSummary.put('validRecords', validRecords);
      healthSummary.put('staleRecords', staleRecords);
      healthSummary.put('unknownRecords', unknownRecords);

      // Calculate percentages
      if (totalRecords > 0) {
        healthSummary.put(
          'validPercentage',
          (validRecords * 100) / totalRecords
        );
        healthSummary.put(
          'stalePercentage',
          (staleRecords * 100) / totalRecords
        );
      } else {
        healthSummary.put('validPercentage', 0);
        healthSummary.put('stalePercentage', 0);
      }

      // Determine overall health status
      String overallHealth = 'Good';
      if (totalRecords == 0) {
        overallHealth = 'No Data';
      } else if (staleRecords > (totalRecords * 0.5)) {
        overallHealth = 'Poor';
      } else if (staleRecords > (totalRecords * 0.2)) {
        overallHealth = 'Fair';
      }

      healthSummary.put('overallHealth', overallHealth);

      return healthSummary;
    } catch (Exception e) {
      System.debug('Error getting cache health summary: ' + e.getMessage());
      throw new AuraHandledException(
        'Error retrieving cache health summary: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Performs cache maintenance - clears old/invalid records
   * @param maxAgeInDays Maximum age in days for cache records
   * @return Success message with count of records cleaned
   */
  @AuraEnabled
  public static String performCacheMaintenance(Integer maxAgeInDays) {
    try {
      if (maxAgeInDays == null || maxAgeInDays <= 0) {
        maxAgeInDays = 7; // Default to 7 days
      }

      DateTime cutoffDate = DateTime.now().addDays(-maxAgeInDays);

      List<FlexiPage_Cache__c> oldRecords = [
        SELECT Id
        FROM FlexiPage_Cache__c
        WHERE Cache_Created_Date__c < :cutoffDate OR Is_Active__c = FALSE
      ];

      if (!oldRecords.isEmpty()) {
        delete oldRecords;
      }

      return 'Cache maintenance completed. Cleaned ' +
        oldRecords.size() +
        ' old records';
    } catch (Exception e) {
      System.debug('Error performing cache maintenance: ' + e.getMessage());
      throw new AuraHandledException(
        'Error performing cache maintenance: ' + e.getMessage()
      );
    }
  }
}
