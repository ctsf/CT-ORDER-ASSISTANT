@IsTest
public with sharing class Test_CasePrioritySetter {

    @IsTest
    static void testSetCasePriority_Success() {
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone');
        insert testCase;

        CasePrioritySetter.CasePriorityRequest req = new CasePrioritySetter.CasePriorityRequest();
        req.CaseId = testCase.Id;

        Test.startTest();
        CasePrioritySetter.setCasePriority(new List<CasePrioritySetter.CasePriorityRequest>{req});
        Test.stopTest();

        Case updatedCase = [SELECT Priority FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('High', updatedCase.Priority, 'Case Priority should be set to High');
    }

    @IsTest
    static void testSetCasePriority_NoRequests() {
        Test.startTest();
        try {
            CasePrioritySetter.setCasePriority(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSetCasePriority_MissingCaseId() {
        CasePrioritySetter.CasePriorityRequest req = new CasePrioritySetter.CasePriorityRequest();
        Test.startTest();
        try {
            CasePrioritySetter.setCasePriority(new List<CasePrioritySetter.CasePriorityRequest>{req});
            System.assert(false, 'Expected exception for missing CaseId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('CaseId is required.'), 'Expected exception for missing CaseId');
        }
        Test.stopTest();
    }
}
