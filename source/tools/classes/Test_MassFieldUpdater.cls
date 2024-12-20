@IsTest
public with sharing class Test_MassFieldUpdater {

    @IsTest
    static void testUpdateField_Success() {
        Contact c1 = new Contact(LastName='Test1');
        Contact c2 = new Contact(LastName='Test2');
        insert new List<Contact>{c1, c2};

        MassFieldUpdater.FieldUpdateRequest req = new MassFieldUpdater.FieldUpdateRequest();
        req.ObjectName = 'Contact';
        req.FieldName = 'LastName';
        req.NewValue = 'Updated';
        req.RecordIds = new List<Id>{c1.Id, c2.Id};

        Test.startTest();
        MassFieldUpdater.updateField(new List<MassFieldUpdater.FieldUpdateRequest>{req});
        Test.stopTest();

        Contact updatedC1 = [SELECT LastName FROM Contact WHERE Id = :c1.Id];
        Contact updatedC2 = [SELECT LastName FROM Contact WHERE Id = :c2.Id];

        System.assertEquals('Updated', updatedC1.LastName, 'LastName should be updated for c1');
        System.assertEquals('Updated', updatedC2.LastName, 'LastName should be updated for c2');
    }

    @IsTest
    static void testUpdateField_NoRequests() {
        Test.startTest();
        try {
            MassFieldUpdater.updateField(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateField_MissingFieldName() {
        Contact c = new Contact(LastName='NoFieldName');
        insert c;

        MassFieldUpdater.FieldUpdateRequest req = new MassFieldUpdater.FieldUpdateRequest();
        req.ObjectName = 'Contact';
        req.FieldName = '';
        req.NewValue = 'ShouldFail';
        req.RecordIds = new List<Id>{c.Id};

        Test.startTest();
        try {
            MassFieldUpdater.updateField(new List<MassFieldUpdater.FieldUpdateRequest>{req});
            System.assert(false, 'Expected exception for missing FieldName');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('FieldName is required.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateField_InvalidObject() {
        MassFieldUpdater.FieldUpdateRequest req = new MassFieldUpdater.FieldUpdateRequest();
        req.ObjectName = 'InvalidObject';
        req.FieldName = 'Name';
        req.NewValue = 'ShouldFail';
        req.RecordIds = new List<Id>{UserInfo.getUserId()};

        Test.startTest();
        try {
            MassFieldUpdater.updateField(new List<MassFieldUpdater.FieldUpdateRequest>{req});
            System.assert(false, 'Expected exception for invalid object');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid ObjectName'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateField_FieldDoesNotExist() {
        Contact c = new Contact(LastName='FieldDoesNotExist');
        insert c;

        MassFieldUpdater.FieldUpdateRequest req = new MassFieldUpdater.FieldUpdateRequest();
        req.ObjectName = 'Contact';
        req.FieldName = 'NonExistentField';
        req.NewValue = 'ShouldFail';
        req.RecordIds = new List<Id>{c.Id};

        Test.startTest();
        try {
            MassFieldUpdater.updateField(new List<MassFieldUpdater.FieldUpdateRequest>{req});
            System.assert(false, 'Expected exception for non existent field');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('does not exist on Contact'), 'Expected exception message');
        }
        Test.stopTest();
    }
}