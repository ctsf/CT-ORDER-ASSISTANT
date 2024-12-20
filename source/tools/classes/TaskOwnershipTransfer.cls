public with sharing class TaskOwnershipTransfer {

    @InvocableMethod(label='Transfer Open Tasks' description='Transfers all open tasks from one user to another')
    public static void transferTasks(List<TaskTransferRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        List<Task> tasksToUpdate = new List<Task>();

        for (TaskTransferRequest request : requests) {
            if (request.OldOwnerId == null || request.NewOwnerId == null) {
                throw new IllegalArgumentException('Both OldOwnerId and NewOwnerId are required.');
            }

            if (!Schema.sObjectType.Task.isAccessible()) {
                throw new Metadata.NoAccessException('You do not have permission to access Tasks.');
            }

            if (!Schema.sObjectType.Task.fields.OwnerId.isUpdateable()) {
                throw new Metadata.NoAccessException('You do not have permission to update the OwnerId field on Tasks.');
            }

            List<Task> tasks = [
                SELECT Id, OwnerId, Status
                FROM Task
                WHERE OwnerId = :request.OldOwnerId AND Status IN ('Not Started', 'In Progress')
            ];

            for (Task task : tasks) {
                task.OwnerId = request.NewOwnerId;
                tasksToUpdate.add(task);
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }

    public class TaskTransferRequest {
        @InvocableVariable(required=true description='ID of the current task owner')
        public Id OldOwnerId;

        @InvocableVariable(required=true description='ID of the new task owner')
        public Id NewOwnerId;
    }
}