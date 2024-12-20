@IsTest
public with sharing class Test_TaskOwnershipTransfer {

    @IsTest
    static void testTransferTasks_Success() {
        User oldOwner = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE IsActive = true AND Id != :oldOwner.Id LIMIT 1];

        Task task1 = new Task(
            OwnerId = oldOwner.Id,
            Subject = 'Task 1',
            Status = 'Not Started',
            Priority = 'Normal'
        );
        Task task2 = new Task(
            OwnerId = oldOwner.Id,
            Subject = 'Task 2',
            Status = 'In Progress',
            Priority = 'Normal'
        );
        insert new List<Task>{task1, task2};

        TaskOwnershipTransfer.TaskTransferRequest request = new TaskOwnershipTransfer.TaskTransferRequest();
        request.OldOwnerId = oldOwner.Id;
        request.NewOwnerId = newOwner.Id;

        Test.startTest();
        TaskOwnershipTransfer.transferTasks(new List<TaskOwnershipTransfer.TaskTransferRequest>{request});
        Test.stopTest();

        List<Task> updatedTasks = [
            SELECT OwnerId
            FROM Task
            WHERE Id IN (:task1.Id, :task2.Id)
        ];

        for (Task task : updatedTasks) {
            System.assertEquals(newOwner.Id, task.OwnerId, 'Task should be transferred to the new owner.');
        }
    }

    @IsTest
    static void testTransferTasks_NoTasksToTransfer() {
        User oldOwner = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE IsActive = true AND Id != :oldOwner.Id LIMIT 1];

        TaskOwnershipTransfer.TaskTransferRequest request = new TaskOwnershipTransfer.TaskTransferRequest();
        request.OldOwnerId = oldOwner.Id;
        request.NewOwnerId = newOwner.Id;

        Test.startTest();
        TaskOwnershipTransfer.transferTasks(new List<TaskOwnershipTransfer.TaskTransferRequest>{request});
        Test.stopTest();

        System.assert(true, 'No exception should be thrown if there are no tasks to transfer.');
    }

    @IsTest
    static void testTransferTasks_InvalidAccess() {
        Test.startTest();
        try {
            TaskOwnershipTransfer.transferTasks(null);
            System.assert(false, 'An exception should have been thrown for null input.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception for null input.');
        }

        try {
            TaskOwnershipTransfer.TaskTransferRequest request = new TaskOwnershipTransfer.TaskTransferRequest();
            request.OldOwnerId = null;
            request.NewOwnerId = null;

            TaskOwnershipTransfer.transferTasks(new List<TaskOwnershipTransfer.TaskTransferRequest>{request});
            System.assert(false, 'An exception should have been thrown for invalid input.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Both OldOwnerId and NewOwnerId are required.'), 'Expected exception for missing owner IDs.');
        }
        Test.stopTest();
    }
}