public with sharing class TaskCreation {

    @InvocableMethod(label='Create Task for Account' description='Creates a Task associated with a specified Account')
    public static void createTaskForAccount(List<TaskRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('At least one request must be provided.');
        }

        List<Task> tasksToInsert = new List<Task>();

        for (TaskRequest request : requests) {
            if (request == null) {
                continue;
            }

            if (String.isBlank(request.accountId)) {
                throw new IllegalArgumentException('accountId must be provided for each request.');
            }

            if (!Schema.sObjectType.Task.isCreateable()) {
                throw new Metadata.NoAccessException('You do not have permission to create Tasks.');
            }

            Task task = new Task();
            task.WhatId = request.accountId;

            if (Schema.sObjectType.Task.fields.Subject.isCreateable()) {
                task.Subject = request.subject;
            } else {
                throw new Metadata.NoAccessException('You do not have permission to set the Subject field.');
            }

            if (Schema.sObjectType.Task.fields.Description.isCreateable()) {
                task.Description = request.description;
            }

            if (Schema.sObjectType.Task.fields.Priority.isCreateable()) {
                task.Priority = request.priority;
            }

            if (Schema.sObjectType.Task.fields.Status.isCreateable()) {
                task.Status = request.status;
            }

            if (Schema.sObjectType.Task.fields.ActivityDate.isCreateable()) {
                task.ActivityDate = request.dueDate;
            }

            tasksToInsert.add(task);
        }

        if (!tasksToInsert.isEmpty()) {
            try {
                insert tasksToInsert;
            } catch (Exception e) {
                System.debug('Error while inserting tasks: ' + e.getMessage());
                throw e;
            }
        }
    }

    public class TaskRequest {
        @InvocableVariable(required=true description='Account ID to associate the Task with')
        public String accountId;

        @InvocableVariable(required=true description='Subject of the Task')
        public String subject;

        @InvocableVariable(description='Description of the Task')
        public String description;

        @InvocableVariable(description='Priority of the Task (e.g., High, Normal, Low)')
        public String priority;

        @InvocableVariable(description='Status of the Task (e.g., Not Started, Completed)')
        public String status;

        @InvocableVariable(description='Due date of the Task')
        public Date dueDate;
    }
}
