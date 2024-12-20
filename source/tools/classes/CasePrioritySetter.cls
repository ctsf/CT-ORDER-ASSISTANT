public with sharing class CasePrioritySetter {

    @InvocableMethod(label='Set Case Priority to High' description='Sets the priority of given Cases to High')
    public static void setCasePriority(List<CasePriorityRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        // Проверка прав доступа к Case и полю Priority
        if (!Schema.sObjectType.Case.isAccessible() || !Schema.sObjectType.Case.fields.Priority.isUpdateable()) {
            throw new Metadata.NoAccessException('You do not have permission to update Case Priority.');
        }

        Set<Id> caseIds = new Set<Id>();
        for (CasePriorityRequest req : requests) {
            if (req.CaseId == null) {
                throw new IllegalArgumentException('CaseId is required.');
            }
            caseIds.add(req.CaseId);
        }

        List<Case> casesToUpdate = [
            SELECT Id, Priority
            FROM Case
            WHERE Id IN :caseIds
        ];

        for (Case c : casesToUpdate) {
            c.Priority = 'High';
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    public class CasePriorityRequest {
        @InvocableVariable(required=true description='ID of the Case to update')
        public Id CaseId;
    }
}