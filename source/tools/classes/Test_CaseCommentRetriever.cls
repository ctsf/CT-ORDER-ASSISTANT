@IsTest
public with sharing class Test_CaseCommentRetriever {

    @IsTest
    static void testGetCaseComments_Success() {
        Case c = new Case(Subject='Test Case', Status='New', Origin='Phone');
        insert c;

        CaseComment cc1 = new CaseComment(
            ParentId = c.Id,
            CommentBody = 'First comment',
            IsPublished = true
        );
        CaseComment cc2 = new CaseComment(
            ParentId = c.Id,
            CommentBody = 'Second comment',
            IsPublished = false
        );
        insert new List<CaseComment>{cc1, cc2};

        CaseCommentRetriever.CaseCommentRequest req = new CaseCommentRetriever.CaseCommentRequest();
        req.CaseId = c.Id;

        Test.startTest();
        List<List<CaseCommentRetriever.CaseCommentResponse>> result = CaseCommentRetriever.getCaseComments(new List<CaseCommentRetriever.CaseCommentRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Result should have one list of responses');
        List<CaseCommentRetriever.CaseCommentResponse> responses = result[0];
        System.assertEquals(2, responses.size(), 'There should be two comments');

        Set<String> bodies = new Set<String>();
        for (CaseCommentRetriever.CaseCommentResponse r : responses) {
            bodies.add(r.CommentBody);
        }
        System.assert(bodies.contains('First comment'), 'Should contain first comment');
        System.assert(bodies.contains('Second comment'), 'Should contain second comment');
    }

    @IsTest
    static void testGetCaseComments_NoComments() {
        Case c = new Case(Subject='No Comments Case', Status='New', Origin='Phone');
        insert c;

        CaseCommentRetriever.CaseCommentRequest req = new CaseCommentRetriever.CaseCommentRequest();
        req.CaseId = c.Id;

        Test.startTest();
        List<List<CaseCommentRetriever.CaseCommentResponse>> result = CaseCommentRetriever.getCaseComments(new List<CaseCommentRetriever.CaseCommentRequest>{req});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return a list with one element');
        System.assertEquals(0, result[0].size(), 'No comments should return an empty list');
    }

    @IsTest
    static void testGetCaseComments_MissingCaseId() {
        CaseCommentRetriever.CaseCommentRequest req = new CaseCommentRetriever.CaseCommentRequest();

        Test.startTest();
        try {
            CaseCommentRetriever.getCaseComments(new List<CaseCommentRetriever.CaseCommentRequest>{req});
            System.assert(false, 'Expected exception for missing CaseId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('CaseId is required.'), 'Expected case id exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetCaseComments_NoRequests() {
        Test.startTest();
        try {
            CaseCommentRetriever.getCaseComments(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }
}