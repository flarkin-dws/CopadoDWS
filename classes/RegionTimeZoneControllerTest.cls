@IsTest
private class RegionTimeZoneControllerTest {
    private static Boolean accountHasRegion() {
        return RegionTimeZoneController.hasRegionField(Account.SObjectType);
    }

    private static Id createAccount(String region) {
        Account acc = new Account(Name = 'Clock Test');
        acc.put(RegionTimeZoneController.REGION_FIELD, region);
        insert acc;
        return acc.Id;
    }

    @IsTest
    static void mapsEachRegionToItsTimeZone() {
        Map<String, String> expected = new Map<String, String>{
            'Appalachia' => 'America/New_York',
            'Texas' => 'America/Chicago',
            'Haynesville' => 'America/Chicago',
            'Bakken' => 'America/Chicago',
            'Rockies' => 'America/Denver',
            'UAE' => 'Asia/Dubai',
            'KSA' => 'Asia/Riyadh'
        };

        Test.startTest();
        for (String region : expected.keySet()) {
            Assert.areEqual(
                expected.get(region),
                RegionTimeZoneController.getTimeZoneForRegion(region),
                'Wrong time zone for ' + region
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void unmappedOrBlankRegionDefaultsToEastern() {
        Test.startTest();
        Assert.areEqual('America/New_York', RegionTimeZoneController.getTimeZoneForRegion('Corporate'));
        Assert.areEqual('America/New_York', RegionTimeZoneController.getTimeZoneForRegion(null));
        Assert.areEqual('America/New_York', RegionTimeZoneController.getTimeZoneForRegion(''));
        Test.stopTest();
    }

    @IsTest
    static void returnsTimeZoneForRecordRegion() {
        if (!accountHasRegion()) {
            return;
        }
        Id texasId = createAccount('Texas');
        Id uaeId = createAccount('UAE');

        Test.startTest();
        RegionTimeZoneController.RegionTimeZone texas = RegionTimeZoneController.getTimeZoneForRecord(texasId);
        RegionTimeZoneController.RegionTimeZone uae = RegionTimeZoneController.getTimeZoneForRecord(uaeId);
        Test.stopTest();

        Assert.areEqual('Texas', texas.region);
        Assert.areEqual('America/Chicago', texas.timeZone);
        Assert.areEqual('UAE', uae.region);
        Assert.areEqual('Asia/Dubai', uae.timeZone);
    }

    @IsTest
    static void recordWithoutRegionDefaultsToEastern() {
        if (!accountHasRegion()) {
            return;
        }
        Id accId = createAccount(null);

        Test.startTest();
        RegionTimeZoneController.RegionTimeZone result = RegionTimeZoneController.getTimeZoneForRecord(accId);
        Test.stopTest();

        Assert.isNull(result.region);
        Assert.areEqual('America/New_York', result.timeZone);
    }

    @IsTest
    static void objectWithoutRegionFieldOrNullIdDefaultsToEastern() {
        Test.startTest();
        RegionTimeZoneController.RegionTimeZone nullResult = RegionTimeZoneController.getTimeZoneForRecord(null);
        RegionTimeZoneController.RegionTimeZone orgResult = RegionTimeZoneController.getTimeZoneForRecord(
            UserInfo.getOrganizationId()
        );
        Test.stopTest();

        Assert.areEqual('America/New_York', nullResult.timeZone);
        Assert.areEqual('America/New_York', orgResult.timeZone);
        Assert.isNull(orgResult.region);
    }
}