@isTest
public class Test_TaskCreation {

    @isTest
    static void testCreateTaskForAccount() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        TaskCreation.TaskRequest request = new TaskCreation.TaskRequest();
        request.accountId = testAccount.Id;
        request.subject = 'Follow up';
        request.description = 'Follow up with the client';
        request.priority = 'High';
        request.status = 'Not Started';
        request.dueDate = Date.today().addDays(7);

        List<TaskCreation.TaskRequest> requests = new List<TaskCreation.TaskRequest>{ request };

        Test.startTest();
        TaskCreation.createTaskForAccount(requests);
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, Description, Priority, Status, ActivityDate, WhatId FROM Task WHERE WhatId = :testAccount.Id];
        System.assertEquals(1, tasks.size());
        System.assertEquals('Follow up', tasks[0].Subject);
        System.assertEquals('Follow up with the client', tasks[0].Description);
        System.assertEquals('High', tasks[0].Priority);
        System.assertEquals('Not Started', tasks[0].Status);
        System.assertEquals(Date.today().addDays(7), tasks[0].ActivityDate);
    }

    @isTest
    static void testMissingAccountId() {
        TaskCreation.TaskRequest request = new TaskCreation.TaskRequest();
        request.subject = 'Follow up';

        List<TaskCreation.TaskRequest> requests = new List<TaskCreation.TaskRequest>{ request };

        try {
            Test.startTest();
            TaskCreation.createTaskForAccount(requests);
            Test.stopTest();
            System.assert(false);
        } catch (IllegalArgumentException e) {
            System.assertEquals('accountId must be provided for each request.', e.getMessage());
        }
    }

    @IsTest
    static void test_nullRequest() {
        Test.startTest();
        try {
            TaskCreation.createTaskForAccount(null);
            System.Assert(false, 'Expected IllegalArgumentException for null request.');
        } catch (IllegalArgumentException e) {
            System.AssertEquals('At least one request must be provided.', e.getMessage());
        }
        Test.stopTest();
    }
}