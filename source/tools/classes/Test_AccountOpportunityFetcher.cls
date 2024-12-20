@IsTest
public with sharing class Test_AccountOpportunityFetcher {

    @IsTest
    static void testGetOpportunities_Success() {
        Account acc = new Account(Name='Test Acc');
        insert acc;

        Opportunity opp1 = new Opportunity(Name='Opp1', StageName='Prospecting', CloseDate=Date.today().addDays(10), AccountId=acc.Id, Amount=1000);
        Opportunity opp2 = new Opportunity(Name='Opp2', StageName='Closed Won', CloseDate=Date.today().addDays(-1), AccountId=acc.Id, Amount=2000);
        insert new List<Opportunity>{opp1, opp2};

        AccountOpportunityFetcher.AccountRequest req = new AccountOpportunityFetcher.AccountRequest();
        req.AccountId = acc.Id;

        Test.startTest();
        List<List<AccountOpportunityFetcher.OpportunityResponse>> result = AccountOpportunityFetcher.getOpportunities(new List<AccountOpportunityFetcher.AccountRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One list returned');
        List<AccountOpportunityFetcher.OpportunityResponse> responses = result[0];
        System.assertEquals(2, responses.size(), 'Should return two opportunities');

        Set<String> oppNames = new Set<String>();
        for (AccountOpportunityFetcher.OpportunityResponse r : responses) {
            oppNames.add(r.Name);
        }
        System.assert(oppNames.contains('Opp1'), 'Opp1 should be returned');
        System.assert(oppNames.contains('Opp2'), 'Opp2 should be returned');
    }

    @IsTest
    static void testGetOpportunities_NoOpps() {
        Account acc = new Account(Name='No Opps Acc');
        insert acc;

        AccountOpportunityFetcher.AccountRequest req = new AccountOpportunityFetcher.AccountRequest();
        req.AccountId = acc.Id;

        Test.startTest();
        List<List<AccountOpportunityFetcher.OpportunityResponse>> result = AccountOpportunityFetcher.getOpportunities(new List<AccountOpportunityFetcher.AccountRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One list returned');
        System.assertEquals(0, result[0].size(), 'No opportunities means empty list');
    }

    @IsTest
    static void testGetOpportunities_NoRequests() {
        Test.startTest();
        try {
            AccountOpportunityFetcher.getOpportunities(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetOpportunities_MissingAccountId() {
        AccountOpportunityFetcher.AccountRequest req = new AccountOpportunityFetcher.AccountRequest();

        Test.startTest();
        try {
            AccountOpportunityFetcher.getOpportunities(new List<AccountOpportunityFetcher.AccountRequest>{req});
            System.assert(false, 'Expected exception for missing AccountId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('AccountId is required.'), 'Expected exception message');
        }
        Test.stopTest();
    }
}