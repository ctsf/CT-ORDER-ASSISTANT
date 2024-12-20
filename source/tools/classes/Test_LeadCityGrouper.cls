@IsTest
public with sharing class Test_LeadCityGrouper {

    @IsTest
    static void testGroupByCity_Success() {
        Lead l1 = new Lead(LastName='L1', Company='TestCo', City='New York');
        Lead l2 = new Lead(LastName='L2', Company='TestCo', City='new york');
        Lead l3 = new Lead(LastName='L3', Company='TestCo', City='London');
        insert new List<Lead>{l1, l2, l3};

        LeadCityGrouper.LeadCityRequest req = new LeadCityGrouper.LeadCityRequest();

        Test.startTest();
        List<List<LeadCityGrouper.LeadCityResponse>> result = LeadCityGrouper.groupByCity(new List<LeadCityGrouper.LeadCityRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one list of responses.');
        List<LeadCityGrouper.LeadCityResponse> responses = result[0];

        Map<String, Integer> cityMap = new Map<String, Integer>();
        for (LeadCityGrouper.LeadCityResponse r : responses) {
            cityMap.put(r.City, r.Count);
        }

        // Город new york должен быть объединен (обработан в lowercase)
        System.assertEquals(2, cityMap.get('new york'), 'There should be 2 leads in New York.');
        System.assertEquals(1, cityMap.get('london'), 'There should be 1 lead in London.');
    }

    @IsTest
    static void testGroupByCity_NoLeads() {
        LeadCityGrouper.LeadCityRequest req = new LeadCityGrouper.LeadCityRequest();

        Test.startTest();
        List<List<LeadCityGrouper.LeadCityResponse>> result = LeadCityGrouper.groupByCity(new List<LeadCityGrouper.LeadCityRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one list even if no leads.');
        System.assertEquals(0, result[0].size(), 'No leads means no cities.');
    }

    @IsTest
    static void testGroupByCity_NoRequests() {
        Test.startTest();
        try {
            LeadCityGrouper.groupByCity(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }
}