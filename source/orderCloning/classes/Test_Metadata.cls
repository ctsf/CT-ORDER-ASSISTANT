@IsTest
public class Test_Metadata {

    @IsTest
    static void testGetSObjectType_ValidObject() {
        Schema.SObjectType result = Metadata.getSObjectType('Account');
        System.assert(result != null, 'The SObjectType for Account should not be null.');
        System.assertEquals('Account', result.getDescribe().getName(), 'The SObjectType should correspond to the Account object.');
    }

    @IsTest
    static void testGetSObjectType_InvalidObject() {
        try {
            Metadata.getSObjectType('NonExistentObject');
            System.assert(false, 'Expected IllegalArgumentException for a non-existent object.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Object NonExistentObject does not exist'), 'Expected exception message for non-existent object.');
        }
    }

    @IsTest
    static void testGetDescribe_ValidObject() {
        Schema.DescribeSObjectResult describeResult = Metadata.getDescribe('Contact');
        System.assert(describeResult != null, 'The DescribeSObjectResult for Contact should not be null.');
        System.assertEquals('Contact', describeResult.getName(), 'The DescribeSObjectResult should correspond to the Contact object.');
    }

    @IsTest
    static void testGetDescribe_InvalidObject() {
        try {
            Metadata.getDescribe('InvalidObject');
            System.assert(false, 'Expected IllegalArgumentException for a non-existent object.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Object InvalidObject does not exist'), 'Expected exception message for non-existent object.');
        }
    }

    @IsTest
    static void testGlobalDescribe_KeyPresence() {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        System.assert(globalDescribe.containsKey('Opportunity'), 'GlobalDescribe should contain Opportunity object.');
    }

    @IsTest
    static void testGlobalDescribe_KeyAbsence() {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        System.assert(!globalDescribe.containsKey('NonExistentObject'), 'GlobalDescribe should not contain NonExistentObject.');
    }
}
