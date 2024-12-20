public with sharing class CaseCommentRetriever {

    @InvocableMethod(label='Get Case Comments' description='Returns comments for the specified Case')
    public static List<List<CaseCommentResponse>> getCaseComments(List<CaseCommentRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        CaseCommentRequest req = requests[0];

        if (req.CaseId == null) {
            throw new IllegalArgumentException('CaseId is required.');
        }

        if (!Schema.sObjectType.CaseComment.isAccessible() || 
            !Schema.sObjectType.CaseComment.fields.CommentBody.isAccessible() || 
            !Schema.sObjectType.CaseComment.fields.CreatedDate.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required fields on CaseComment.');
        }

        List<CaseComment> comments = [
            SELECT Id, CommentBody, CreatedDate, IsPublished
            FROM CaseComment
            WHERE ParentId = :req.CaseId
            ORDER BY CreatedDate ASC
        ];

        List<CaseCommentResponse> responses = new List<CaseCommentResponse>();
        for (CaseComment cc : comments) {
            responses.add(new CaseCommentResponse(cc.Id, cc.CommentBody, cc.CreatedDate, cc.IsPublished));
        }

        return new List<List<CaseCommentResponse>>{responses};
    }

    public class CaseCommentRequest {
        @InvocableVariable(required=true description='ID of the Case to retrieve comments for')
        public Id CaseId;
    }

    public class CaseCommentResponse {
        @InvocableVariable(description='ID of the case comment')
        public Id CommentId;
        @InvocableVariable(description='Body of the case comment')
        public String CommentBody;
        @InvocableVariable(description='Created date of the case comment')
        public DateTime CreatedDate;
        @InvocableVariable(description='Indicates if the comment is published')
        public Boolean IsPublished;

        public CaseCommentResponse(Id commentId, String commentBody, DateTime createdDate, Boolean isPublished) {
            this.CommentId = commentId;
            this.CommentBody = commentBody;
            this.CreatedDate = createdDate;
            this.IsPublished = isPublished;
        }
    }
}