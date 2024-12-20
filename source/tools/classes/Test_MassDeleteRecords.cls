@IsTest
public with sharing class Test_MassDeleteRecords {

    @IsTest
    static void testDeleteRecords_Success() {
        Account a1 = new Account(Name='To Delete 1');
        Account a2 = new Account(Name='To Delete 2');
        insert new List<Account>{a1, a2};

        MassDeleteRecords.RecordDeleteRequest req = new MassDeleteRecords.RecordDeleteRequest();
        req.RecordIds = new List<Id>{a1.Id, a2.Id};

        Test.startTest();
        MassDeleteRecords.deleteRecords(new List<MassDeleteRecords.RecordDeleteRequest>{req});
        Test.stopTest();

        Integer countRemaining = [SELECT COUNT() FROM Account WHERE Id IN :req.RecordIds];
        System.assertEquals(0, countRemaining, 'All specified accounts should be deleted.');
    }

    @IsTest
    static void testDeleteRecords_NoRequests() {
        Test.startTest();
        try {
            MassDeleteRecords.deleteRecords(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testDeleteRecords_EmptyRecordIds() {
        MassDeleteRecords.RecordDeleteRequest req = new MassDeleteRecords.RecordDeleteRequest();
        req.RecordIds = new List<Id>();

        Test.startTest();
        try {
            MassDeleteRecords.deleteRecords(new List<MassDeleteRecords.RecordDeleteRequest>{req});
            System.assert(false, 'Expected exception for empty RecordIds');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('RecordIds cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }
}