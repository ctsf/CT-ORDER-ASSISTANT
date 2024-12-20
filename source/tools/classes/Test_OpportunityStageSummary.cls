@IsTest
public with sharing class Test_OpportunityStageSummary {

    @IsTest
    static void testGenerateSummary_Success() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Opportunity o1 = new Opportunity(Name='Opp1', StageName='Prospecting', CloseDate=Date.today().addDays(10), Amount=1000, AccountId=acc.Id);
        Opportunity o2 = new Opportunity(Name='Opp2', StageName='Prospecting', CloseDate=Date.today().addDays(10), Amount=2000, AccountId=acc.Id);
        Opportunity o3 = new Opportunity(Name='Opp3', StageName='Closed Won', CloseDate=Date.today().addDays(-1), Amount=3000, AccountId=acc.Id);
        insert new List<Opportunity>{o1, o2, o3};

        OpportunityStageSummary.StageSummaryRequest req = new OpportunityStageSummary.StageSummaryRequest();

        Test.startTest();
        List<List<OpportunityStageSummary.StageSummaryResponse>> result = OpportunityStageSummary.generateSummary(new List<OpportunityStageSummary.StageSummaryRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one list of responses');
        List<OpportunityStageSummary.StageSummaryResponse> responses = result[0];

        // Проверим результаты
        Map<String, OpportunityStageSummary.StageSummaryResponse> stageMap = new Map<String, OpportunityStageSummary.StageSummaryResponse>();
        for (OpportunityStageSummary.StageSummaryResponse r : responses) {
            stageMap.put(r.StageName, r);
        }

        System.assert(stageMap.containsKey('Prospecting'), 'Should have Prospecting stage');
        System.assert(stageMap.containsKey('Closed Won'), 'Should have Closed Won stage');

        // Prospecting: 2 опп, сумма 3000, средняя 1500
        OpportunityStageSummary.StageSummaryResponse prospecting = stageMap.get('Prospecting');
        System.assertEquals(2, prospecting.Count, '2 opportunities in Prospecting');
        System.assertEquals(3000, prospecting.TotalAmount, 'Total 3000 in Prospecting');
        System.assertEquals(1500, prospecting.AverageAmount, 'Average should be 1500');

        // Closed Won: 1 опп, сумма 3000, средняя 3000
        OpportunityStageSummary.StageSummaryResponse closedWon = stageMap.get('Closed Won');
        System.assertEquals(1, closedWon.Count, '1 opportunity in Closed Won');
        System.assertEquals(3000, closedWon.TotalAmount, 'Total 3000 in Closed Won');
        System.assertEquals(3000, closedWon.AverageAmount, 'Average should be 3000');
    }

    @IsTest
    static void testGenerateSummary_NoOpportunities() {
        OpportunityStageSummary.StageSummaryRequest req = new OpportunityStageSummary.StageSummaryRequest();

        Test.startTest();
        List<List<OpportunityStageSummary.StageSummaryResponse>> result = OpportunityStageSummary.generateSummary(new List<OpportunityStageSummary.StageSummaryRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One list returned');
        System.assertEquals(0, result[0].size(), 'No opportunities means no stages');
    }

    @IsTest
    static void testGenerateSummary_NoRequests() {
        Test.startTest();
        try {
            OpportunityStageSummary.generateSummary(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }
}