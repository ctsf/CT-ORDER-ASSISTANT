@IsTest
public with sharing class Test_CaseWithoutTasksReporter {

    @IsTest
    static void testGetCases_NoTasksInRange() {
        Case c1 = new Case(Subject='Case No Tasks', Status='New', Origin='Phone');
        insert c1;

        Task pastTask = new Task(
            Subject='Past Task',
            WhatId=c1.Id,
            ActivityDate=Date.today().addDays(-10)
        );
        insert pastTask;

        CaseWithoutTasksReporter.CaseRequest req = new CaseWithoutTasksReporter.CaseRequest();
        req.FromDate = Date.today();
        req.ToDate = Date.today().addDays(5);

        Test.startTest();
        List<List<CaseWithoutTasksReporter.CaseResponse>> result = CaseWithoutTasksReporter.getCases(new List<CaseWithoutTasksReporter.CaseRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One list returned');
        List<CaseWithoutTasksReporter.CaseResponse> responses = result[0];
        System.assertEquals(1, responses.size(), 'Case should be returned because no tasks in given range');
        System.assertEquals(c1.Id, responses[0].CaseId, 'Should include c1');
    }

    @IsTest
    static void testGetCases_WithTasksInRange() {
        Case c = new Case(Subject='Case With Task', Status='New', Origin='Phone');
        insert c;

        Task futureTask = new Task(
            Subject='Future Task in Range',
            WhatId=c.Id,
            ActivityDate=Date.today().addDays(2)
        );
        insert futureTask;

        CaseWithoutTasksReporter.CaseRequest req = new CaseWithoutTasksReporter.CaseRequest();
        req.FromDate = Date.today();
        req.ToDate = Date.today().addDays(5);

        Test.startTest();
        List<List<CaseWithoutTasksReporter.CaseResponse>> result = CaseWithoutTasksReporter.getCases(new List<CaseWithoutTasksReporter.CaseRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(0, result[0].size(), 'No cases should be returned as there is a task in range');
    }

    @IsTest
    static void testGetCases_NoRequests() {
        Test.startTest();
        try {
            CaseWithoutTasksReporter.getCases(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetCases_MissingDates() {
        CaseWithoutTasksReporter.CaseRequest req = new CaseWithoutTasksReporter.CaseRequest();
        req.FromDate = null;
        req.ToDate = Date.today();

        Test.startTest();
        try {
            CaseWithoutTasksReporter.getCases(new List<CaseWithoutTasksReporter.CaseRequest>{req});
            System.assert(false, 'Expected exception for missing FromDate');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('FromDate and ToDate are required.'), 'Expected date exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetCases_InvertedDates() {
        CaseWithoutTasksReporter.CaseRequest req = new CaseWithoutTasksReporter.CaseRequest();
        req.FromDate = Date.today().addDays(5);
        req.ToDate = Date.today();

        Test.startTest();
        try {
            CaseWithoutTasksReporter.getCases(new List<CaseWithoutTasksReporter.CaseRequest>{req});
            System.assert(false, 'Expected exception for inverted dates');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('ToDate cannot be earlier than FromDate.'), 'Expected inverted date exception');
        }
        Test.stopTest();
    }
}