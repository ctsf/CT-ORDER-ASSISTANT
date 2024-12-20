@IsTest
public with sharing class Test_UpcomingTasksFetcher {

    @IsTest
    static void testGetUpcomingTasks_Contact() {
        Contact con = new Contact(LastName='Test', FirstName='Contact');
        insert con;

        Task futureTask = new Task(
            Subject='Future Task',
            WhoId=con.Id,
            ActivityDate=Date.today().addDays(5)
        );
        Task pastTask = new Task(
            Subject='Past Task',
            WhoId=con.Id,
            ActivityDate=Date.today().addDays(-2)
        );
        insert new List<Task>{futureTask, pastTask};

        UpcomingTasksFetcher.TaskRequest req = new UpcomingTasksFetcher.TaskRequest();
        req.RecordId = con.Id;

        Test.startTest();
        List<List<UpcomingTasksFetcher.TaskResponse>> result = UpcomingTasksFetcher.getUpcomingTasks(new List<UpcomingTasksFetcher.TaskRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One list returned');
        List<UpcomingTasksFetcher.TaskResponse> responses = result[0];
        System.assertEquals(1, responses.size(), 'Only one future task should be returned');
        System.assertEquals('Future Task', responses[0].Subject, 'Subject should match future task');
    }

    @IsTest
    static void testGetUpcomingTasks_Opportunity() {
        Account acc = new Account(Name='Test Acc');
        insert acc;

        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today().addDays(10), AccountId=acc.Id);
        insert opp;

        Task futureTask = new Task(
            Subject='Future Task Opp',
            WhatId=opp.Id,
            ActivityDate=Date.today().addDays(3)
        );
        Task todayTask = new Task(
            Subject='Today Task Opp',
            WhatId=opp.Id,
            ActivityDate=Date.today()
        );
        insert new List<Task>{futureTask, todayTask};

        UpcomingTasksFetcher.TaskRequest req = new UpcomingTasksFetcher.TaskRequest();
        req.RecordId = opp.Id;

        Test.startTest();
        List<List<UpcomingTasksFetcher.TaskResponse>> result = UpcomingTasksFetcher.getUpcomingTasks(new List<UpcomingTasksFetcher.TaskRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One list returned');
        List<UpcomingTasksFetcher.TaskResponse> responses = result[0];
        System.assertEquals(1, responses.size(), 'Only future task should be returned');
        System.assertEquals('Future Task Opp', responses[0].Subject, 'Subject should match future task for opp');
    }

    @IsTest
    static void testGetUpcomingTasks_NoFutureTasks() {
        Contact con = new Contact(LastName='NoFuture', FirstName='Tasks');
        insert con;

        Task pastTask = new Task(
            Subject='Past Task',
            WhoId=con.Id,
            ActivityDate=Date.today().addDays(-1)
        );
        insert pastTask;

        UpcomingTasksFetcher.TaskRequest req = new UpcomingTasksFetcher.TaskRequest();
        req.RecordId = con.Id;

        Test.startTest();
        List<List<UpcomingTasksFetcher.TaskResponse>> result = UpcomingTasksFetcher.getUpcomingTasks(new List<UpcomingTasksFetcher.TaskRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One list returned');
        System.assertEquals(0, result[0].size(), 'No future tasks means empty list');
    }

    @IsTest
    static void testGetUpcomingTasks_NoRequests() {
        Test.startTest();
        try {
            UpcomingTasksFetcher.getUpcomingTasks(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetUpcomingTasks_InvalidObject() {
        Account acc = new Account(Name='Not Contact or Opp');
        insert acc;

        UpcomingTasksFetcher.TaskRequest req = new UpcomingTasksFetcher.TaskRequest();
        req.RecordId = acc.Id;

        Test.startTest();
        try {
            UpcomingTasksFetcher.getUpcomingTasks(new List<UpcomingTasksFetcher.TaskRequest>{req});
            System.assert(false, 'Expected exception for invalid object type');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('must be a Contact or Opportunity'), 'Expected invalid object exception');
        }
        Test.stopTest();
    }
}