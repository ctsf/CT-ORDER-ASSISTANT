@isTest
public class Test_ObjectAccessChecker {

    @isTest
    static void testCheckObjectAccessValid() {
        ObjectAccessChecker.ObjectAccessRequest request = new ObjectAccessChecker.ObjectAccessRequest();
        request.objectName = 'Account';

        List<ObjectAccessChecker.ObjectAccessRequest> requests = new List<ObjectAccessChecker.ObjectAccessRequest>{ request };

        Test.startTest();
        List<ObjectAccessChecker.AccessResult> results = ObjectAccessChecker.checkObjectAccess(requests);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One result should be returned.');
        ObjectAccessChecker.AccessResult result = results[0];
        System.assertEquals('Account', result.objectName, 'Object name should match the request.');
        System.assert(result.exists, 'Account object should exist.');
        System.assertNotEquals(null, result.isCreateable, 'isCreateable should not be null.');
        System.assertNotEquals(null, result.isReadable, 'isReadable should not be null.');
        System.assertNotEquals(null, result.isUpdateable, 'isUpdateable should not be null.');
        System.assertNotEquals(null, result.isDeleteable, 'isDeleteable should not be null.');
    }

    @isTest
    static void testCheckObjectAccessInvalidObject() {
        ObjectAccessChecker.ObjectAccessRequest request = new ObjectAccessChecker.ObjectAccessRequest();
        request.objectName = 'NonExistentObject';

        List<ObjectAccessChecker.ObjectAccessRequest> requests = new List<ObjectAccessChecker.ObjectAccessRequest>{ request };

        Test.startTest();
        List<ObjectAccessChecker.AccessResult> results = ObjectAccessChecker.checkObjectAccess(requests);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One result should be returned.');
        ObjectAccessChecker.AccessResult result = results[0];
        System.assertEquals('NonExistentObject', result.objectName, 'Object name should match the request.');
        System.assert(!result.exists, 'NonExistentObject should not exist.');
        System.assertEquals('Object does not exist.', result.message, 'Message should indicate object does not exist.');
    }

    @isTest
    static void testCheckObjectAccessEmptyRequest() {
        try {
            Test.startTest();
            ObjectAccessChecker.checkObjectAccess(new List<ObjectAccessChecker.ObjectAccessRequest>());
            Test.stopTest();
            System.assert(false, 'An exception should have been thrown for empty requests.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('At least one request must be provided.', e.getMessage(), 'Exception message should match.');
        }
    }

    @isTest
    static void testCheckObjectAccessBlankObjectName() {
        ObjectAccessChecker.ObjectAccessRequest request = new ObjectAccessChecker.ObjectAccessRequest();
        request.objectName = '';

        List<ObjectAccessChecker.ObjectAccessRequest> requests = new List<ObjectAccessChecker.ObjectAccessRequest>{ request };

        try {
            Test.startTest();
            ObjectAccessChecker.checkObjectAccess(requests);
            Test.stopTest();
            System.assert(false, 'An exception should have been thrown for blank object name.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Object name must be provided for each request.', e.getMessage(), 'Exception message should match.');
        }
    }
}