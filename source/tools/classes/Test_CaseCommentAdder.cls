@IsTest
public with sharing class Test_CaseCommentAdder {

    @IsTest
    static void testAddCaseComment_Success() {
        Case c1 = new Case(Subject='Test Case 1', Status='New', Origin='Phone');
        Case c2 = new Case(Subject='Test Case 2', Status='New', Origin='Phone');
        insert new List<Case>{c1, c2};

        CaseCommentAdder.CaseCommentRequest req = new CaseCommentAdder.CaseCommentRequest();
        req.CaseIds = new List<Id>{c1.Id, c2.Id};
        req.CommentBody = 'This is a test comment';

        Test.startTest();
        CaseCommentAdder.addCaseComment(new List<CaseCommentAdder.CaseCommentRequest>{req});
        Test.stopTest();

        List<CaseComment> comments = [
            SELECT ParentId, CommentBody, IsPublished
            FROM CaseComment
            WHERE ParentId IN :req.CaseIds
        ];
        
        System.assertEquals(2, comments.size(), 'Two comments should be inserted.');
        for (CaseComment cc : comments) {
            System.assertEquals('This is a test comment', cc.CommentBody, 'CommentBody should match.');
            System.assertEquals(true, cc.IsPublished, 'Comment should be published.');
        }
    }

    @IsTest
    static void testAddCaseComment_NoRequests() {
        Test.startTest();
        try {
            CaseCommentAdder.addCaseComment(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAddCaseComment_EmptyCaseIds() {
        CaseCommentAdder.CaseCommentRequest req = new CaseCommentAdder.CaseCommentRequest();
        req.CaseIds = new List<Id>();
        req.CommentBody = 'Should fail';

        Test.startTest();
        try {
            CaseCommentAdder.addCaseComment(new List<CaseCommentAdder.CaseCommentRequest>{req});
            System.assert(false, 'Expected exception for empty CaseIds');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('CaseIds cannot be null or empty.'), 'Expected exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAddCaseComment_MissingCommentBody() {
        Case c = new Case(Subject='Test Case', Status='New', Origin='Phone');
        insert c;

        CaseCommentAdder.CaseCommentRequest req = new CaseCommentAdder.CaseCommentRequest();
        req.CaseIds = new List<Id>{c.Id};
        req.CommentBody = '';

        Test.startTest();
        try {
            CaseCommentAdder.addCaseComment(new List<CaseCommentAdder.CaseCommentRequest>{req});
            System.assert(false, 'Expected exception for empty CommentBody');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('CommentBody is required.'), 'Expected exception');
        }
        Test.stopTest();
    }
}