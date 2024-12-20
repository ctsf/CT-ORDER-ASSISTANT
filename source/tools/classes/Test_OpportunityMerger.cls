@IsTest
public with sharing class Test_OpportunityMerger {

    @IsTest
    static void testMergeOpps_Success() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Opportunity primaryOpp = new Opportunity(
            Name='Primary Opp', 
            StageName='Prospecting', 
            CloseDate=Date.today().addDays(10),
            AccountId=acc.Id
        );
        insert primaryOpp;

        Opportunity secondaryOpp = new Opportunity(
            Name='Secondary Opp', 
            StageName='Prospecting', 
            CloseDate=Date.today().addDays(5), 
            Amount=5000, 
            Description='Secondary description',
            AccountId=acc.Id
        );
        insert secondaryOpp;

        OpportunityMerger.MergeOppRequest req = new OpportunityMerger.MergeOppRequest();
        req.PrimaryOppId = primaryOpp.Id;
        req.SecondaryOppId = secondaryOpp.Id;

        Test.startTest();
        OpportunityMerger.mergeOpps(new List<OpportunityMerger.MergeOppRequest>{req});
        Test.stopTest();

        Opportunity updatedPrimary = [SELECT Amount, CloseDate, Description FROM Opportunity WHERE Id = :primaryOpp.Id];
        Integer countSecondary = [SELECT COUNT() FROM Opportunity WHERE Id = :secondaryOpp.Id];


        System.assertEquals(5000, updatedPrimary.Amount, 'Amount should be copied from secondary');
        
        System.assertEquals(Date.today().addDays(10), updatedPrimary.CloseDate, 'CloseDate should remain the same');
        System.assertEquals('Secondary description', updatedPrimary.Description, 'Description should be copied from secondary');

        System.assertEquals(0, countSecondary, 'Secondary opportunity should be deleted');
    }

    @IsTest
    static void testMergeOpps_MissingIds() {
        OpportunityMerger.MergeOppRequest req = new OpportunityMerger.MergeOppRequest();

        Test.startTest();
        try {
            OpportunityMerger.mergeOpps(new List<OpportunityMerger.MergeOppRequest>{req});
            System.assert(false, 'Expected exception for missing Ids');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('required'), 'Expected required Ids exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testMergeOpps_SameId() {
        Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=Date.today().addDays(10), Amount=1000);
        insert opp;

        OpportunityMerger.MergeOppRequest req = new OpportunityMerger.MergeOppRequest();
        req.PrimaryOppId = opp.Id;
        req.SecondaryOppId = opp.Id;

        Test.startTest();
        try {
            OpportunityMerger.mergeOpps(new List<OpportunityMerger.MergeOppRequest>{req});
            System.assert(false, 'Expected exception for same Ids');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('cannot be the same'), 'Expected same Id exception');
        }
        Test.stopTest();
    }
}