@IsTest
public class Test_ContactCreation {
    @IsTest
    static void testCreateContact_Success() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        ContactCreation.ContactRequest request = new ContactCreation.ContactRequest();
        request.AccountId = account.Id;
        request.LastName = 'Doe';
        request.FirstName = 'John';
        request.Email = 'john.doe@example.com';
        request.Phone = '1234567890';

        Test.startTest();
        ContactCreation.createContact(new List<ContactCreation.ContactRequest>{request});
        Test.stopTest();

        Contact contact = [SELECT Id, AccountId, FirstName, LastName, Email, Phone FROM Contact WHERE AccountId = :account.Id];
        System.assertEquals('John', contact.FirstName);
        System.assertEquals('Doe', contact.LastName);
        System.assertEquals('john.doe@example.com', contact.Email);
        System.assertEquals('1234567890', contact.Phone);
    }

    @IsTest
    static void testCreateContact_MissingAccountId() {
        ContactCreation.ContactRequest request = new ContactCreation.ContactRequest();
        request.LastName = 'Doe';

        Test.startTest();
        try {
            ContactCreation.createContact(new List<ContactCreation.ContactRequest>{request});
            System.assert(false, 'Exception should have been thrown for missing AccountId.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('AccountId is required.'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateContact_MissingLastName() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        ContactCreation.ContactRequest request = new ContactCreation.ContactRequest();
        request.AccountId = account.Id;

        Test.startTest();
        try {
            ContactCreation.createContact(new List<ContactCreation.ContactRequest>{request});
            System.assert(false, 'Exception should have been thrown for missing LastName.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('LastName is required.'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateContact_MultipleRequests() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        ContactCreation.ContactRequest request1 = new ContactCreation.ContactRequest();
        request1.AccountId = account.Id;
        request1.LastName = 'Doe';

        ContactCreation.ContactRequest request2 = new ContactCreation.ContactRequest();
        request2.AccountId = account.Id;
        request2.LastName = 'Smith';

        Test.startTest();
        try {
            ContactCreation.createContact(new List<ContactCreation.ContactRequest>{request1, request2});
            System.assert(false, 'Exception should have been thrown for multiple requests.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Exactly one request must be provided.'));
        }
        Test.stopTest();
    }
}
