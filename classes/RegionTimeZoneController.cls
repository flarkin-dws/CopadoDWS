public with sharing class RegionTimeZoneController {
    public static final String DEFAULT_TIME_ZONE = 'America/New_York';
    public static final String REGION_FIELD = 'Region__c';

    @TestVisible
    private static final Map<String, String> REGION_TO_TIME_ZONE = new Map<String, String>{
        'Appalachia' => 'America/New_York',
        'Texas' => 'America/Chicago',
        'Haynesville' => 'America/Chicago',
        'Bakken' => 'America/Chicago',
        'Rockies' => 'America/Denver',
        'UAE' => 'Asia/Dubai',
        'KSA' => 'Asia/Riyadh'
    };

    public class RegionTimeZone {
        @AuraEnabled
        public String region;
        @AuraEnabled
        public String timeZone;

        public RegionTimeZone(String region) {
            this.region = region;
            this.timeZone = getTimeZoneForRegion(region);
        }
    }

    // Region__c is read dynamically so this class compiles in orgs where the field
    // (or the object it lives on, e.g. WorkOrder) does not exist.
    @AuraEnabled(cacheable=true)
    public static RegionTimeZone getTimeZoneForRecord(Id recordId) {
        return new RegionTimeZone(getRegion(recordId));
    }

    public static String getTimeZoneForRegion(String region) {
        if (String.isBlank(region) || !REGION_TO_TIME_ZONE.containsKey(region)) {
            return DEFAULT_TIME_ZONE;
        }
        return REGION_TO_TIME_ZONE.get(region);
    }

    @TestVisible
    private static Boolean hasRegionField(Schema.SObjectType objectType) {
        return objectType != null && objectType.getDescribe().fields.getMap().containsKey(REGION_FIELD);
    }

    private static String getRegion(Id recordId) {
        if (recordId == null) {
            return null;
        }
        Schema.SObjectType objectType = recordId.getSobjectType();
        if (!hasRegionField(objectType)) {
            return null;
        }

        String query = 'SELECT ' + REGION_FIELD + ' FROM ' + objectType + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> records = Database.queryWithBinds(
            query,
            new Map<String, Object>{ 'recordId' => recordId },
            AccessLevel.USER_MODE
        );
        return records.isEmpty() ? null : (String) records[0].get(REGION_FIELD);
    }
}