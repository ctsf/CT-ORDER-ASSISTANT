public with sharing class CaseCommentAdder {

    @InvocableMethod(label='Add Comment to Cases' description='Adds a comment to the specified cases')
    public static void addCaseComment(List<CaseCommentRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        CaseCommentRequest req = requests[0];
        
        if (req.CaseIds == null || req.CaseIds.isEmpty()) {
            throw new IllegalArgumentException('CaseIds cannot be null or empty.');
        }
        if (String.isBlank(req.CommentBody)) {
            throw new IllegalArgumentException('CommentBody is required.');
        }

        if (!Schema.sObjectType.CaseComment.isCreateable() ||
            !Schema.sObjectType.CaseComment.fields.ParentId.isCreateable() ||
            !Schema.sObjectType.CaseComment.fields.CommentBody.isCreateable()) {
            throw new Metadata.NoAccessException('You do not have permission to create Case Comments.');
        }

        Schema.DescribeSObjectResult caseDescribe = Case.SObjectType.getDescribe();
        if (!caseDescribe.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access Case.');
        }

        List<CaseComment> commentsToInsert = new List<CaseComment>();
        for (Id caseId : req.CaseIds) {
            commentsToInsert.add(new CaseComment(
                ParentId = caseId,
                CommentBody = req.CommentBody,
                IsPublished = true
            ));
        }

        insert commentsToInsert;
    }

    public class CaseCommentRequest {
        @InvocableVariable(required=true description='List of Case IDs to add comments to')
        public List<Id> CaseIds;

        @InvocableVariable(required=true description='The body of the comment to add')
        public String CommentBody;
    }
}