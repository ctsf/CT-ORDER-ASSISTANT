public with sharing class CaseWithoutTasksReporter {

    @InvocableMethod(label='Get Cases Without Tasks in Date Range' description='Returns cases that have no tasks in the specified date range')
    public static List<List<CaseResponse>> getCases(List<CaseRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        CaseRequest req = requests[0];

        if (req.FromDate == null || req.ToDate == null) {
            throw new IllegalArgumentException('FromDate and ToDate are required.');
        }
        if (req.ToDate < req.FromDate) {
            throw new IllegalArgumentException('ToDate cannot be earlier than FromDate.');
        }

        if (!Schema.sObjectType.Case.isAccessible() ||
            !Schema.sObjectType.Case.fields.Subject.isAccessible() ||
            !Schema.sObjectType.Case.fields.Status.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Case fields.');
        }

        List<Task> tasksInRange = [
            SELECT Id, WhatId
            FROM Task
            WHERE ActivityDate >= :req.FromDate
            AND ActivityDate <= :req.ToDate
            AND WhatId != null
        ];

        Set<Id> caseIdsWithTasks = new Set<Id>();
        for (Task t : tasksInRange) {
            if (t.WhatId.getSObjectType() == Case.SObjectType) {
                caseIdsWithTasks.add(t.WhatId);
            }
        }

        List<Case> cases;
        if (caseIdsWithTasks.isEmpty()) {
            cases = [
                SELECT Id, Subject, Status 
                FROM Case
            ];
        } else {
            cases = [
                SELECT Id, Subject, Status
                FROM Case
                WHERE Id NOT IN :caseIdsWithTasks
            ];
        }

        List<CaseResponse> responses = new List<CaseResponse>();
        for (Case c : cases) {
            responses.add(new CaseResponse(c.Id, c.Subject, c.Status));
        }

        return new List<List<CaseResponse>>{responses};
    }

    public class CaseRequest {
        @InvocableVariable(required=true description='Start date for checking tasks')
        public Date FromDate;

        @InvocableVariable(required=true description='End date for checking tasks')
        public Date ToDate;
    }

    public class CaseResponse {
        @InvocableVariable(description='ID of the case')
        public Id CaseId;
        @InvocableVariable(description='Subject of the case')
        public String Subject;
        @InvocableVariable(description='Status of the case')
        public String Status;

        public CaseResponse(Id caseId, String subject, String status) {
            this.CaseId = caseId;
            this.Subject = subject;
            this.Status = status;
        }
    }
}