@IsTest
public with sharing class Test_OpportunityCloner {

    @IsTest
    static void testCloneOpportunities_Success() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = account.Id,
            CloseDate = Date.today().addDays(10),
            StageName = 'Prospecting',
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = 10000
        );
        insert opp;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert oli;

        OpportunityCloner.CloneOpportunityRequest request = new OpportunityCloner.CloneOpportunityRequest();
        request.OpportunityId = opp.Id;

        Test.startTest();
        List<Id> clonedOppIds = OpportunityCloner.cloneOpportunities(new List<OpportunityCloner.CloneOpportunityRequest>{request});
        Test.stopTest();

        System.assertEquals(1, clonedOppIds.size(), 'One opportunity should be cloned.');

        Opportunity clonedOpp = [SELECT Name, CloseDate, StageName, Amount, AccountId FROM Opportunity WHERE Id = :clonedOppIds[0]];
        System.assert(clonedOpp.Name.contains('(Clone)'), 'Cloned opportunity name should be updated.');
        System.assertEquals('Prospecting', clonedOpp.StageName, 'Cloned opportunity should have the Prospecting stage.');
        System.assertEquals(account.Id, clonedOpp.AccountId, 'Cloned opportunity should belong to the same account.');

        List<OpportunityLineItem> clonedLineItems = [
            SELECT Quantity, UnitPrice, PricebookEntryId
            FROM OpportunityLineItem
            WHERE OpportunityId = :clonedOppIds[0]
        ];

        System.assertEquals(1, clonedLineItems.size(), 'Cloned opportunity should have one line item.');
        System.assertEquals(oli.Quantity, clonedLineItems[0].Quantity, 'Cloned line item quantity should match the original.');
        System.assertEquals(oli.UnitPrice, clonedLineItems[0].UnitPrice, 'Cloned line item price should match the original.');
    }

    @IsTest
    static void testCloneOpportunities_NoLineItems() {
        Account account = new Account(Name = 'Test Account No Line Items');
        insert account;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity No Line Items',
            AccountId = account.Id,
            CloseDate = Date.today().addDays(10),
            StageName = 'Prospecting',
            Amount = 5000
        );
        insert opp;

        OpportunityCloner.CloneOpportunityRequest request = new OpportunityCloner.CloneOpportunityRequest();
        request.OpportunityId = opp.Id;

        Test.startTest();
        List<Id> clonedOppIds = OpportunityCloner.cloneOpportunities(new List<OpportunityCloner.CloneOpportunityRequest>{request});
        Test.stopTest();

        System.assertEquals(1, clonedOppIds.size(), 'One opportunity should be cloned even without line items.');

        List<OpportunityLineItem> clonedLineItems = [
            SELECT Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :clonedOppIds[0]
        ];

        System.assertEquals(0, clonedLineItems.size(), 'Cloned opportunity should not have any line items.');
    }
}