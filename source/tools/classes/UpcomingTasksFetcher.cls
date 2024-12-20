public with sharing class UpcomingTasksFetcher {

    @InvocableMethod(label='Get Upcoming Tasks' description='Returns tasks in the future related to an Opportunity or Contact')
    public static List<List<TaskResponse>> getUpcomingTasks(List<TaskRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        TaskRequest req = requests[0];
        if (req.RecordId == null) {
            throw new IllegalArgumentException('RecordId is required.');
        }

        if (!Schema.sObjectType.Task.isAccessible() ||
            !Schema.sObjectType.Task.fields.Subject.isAccessible() ||
            !Schema.sObjectType.Task.fields.ActivityDate.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Task fields.');
        }

        Id recordId = req.RecordId;
        Schema.SObjectType sObjType = recordId.getSObjectType();
        String objName = sObjType.getDescribe().getName();
        
        List<Task> tasks;
        if (objName == 'Contact') {
            tasks = [
                SELECT Id, Subject, ActivityDate 
                FROM Task 
                WHERE WhoId = :recordId
                AND ActivityDate > :Date.today()
                ORDER BY ActivityDate ASC
            ];
        } else if (objName == 'Opportunity') {
            tasks = [
                SELECT Id, Subject, ActivityDate 
                FROM Task 
                WHERE WhatId = :recordId
                AND ActivityDate > :Date.today()
                ORDER BY ActivityDate ASC
            ];
        } else {
            throw new IllegalArgumentException('RecordId must be a Contact or Opportunity.');
        }

        List<TaskResponse> responses = new List<TaskResponse>();
        for (Task t : tasks) {
            responses.add(new TaskResponse(t.Id, t.Subject, t.ActivityDate));
        }

        return new List<List<TaskResponse>>{responses};
    }

    public class TaskRequest {
        @InvocableVariable(required=true description='ID of the Contact or Opportunity')
        public Id RecordId;
    }

    public class TaskResponse {
        @InvocableVariable(description='ID of the task')
        public Id TaskId;
        @InvocableVariable(description='Subject of the task')
        public String Subject;
        @InvocableVariable(description='ActivityDate of the task')
        public Date ActivityDate;

        public TaskResponse(Id taskId, String subject, Date activityDate) {
            this.TaskId = taskId;
            this.Subject = subject;
            this.ActivityDate = activityDate;
        }
    }
}