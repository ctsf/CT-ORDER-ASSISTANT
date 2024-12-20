@isTest
public class Test_AccountCreation {

    @isTest
    static void testCreateSingleAccount() {
        AccountCreation.AccountRequest request = new AccountCreation.AccountRequest();
        request.Name = 'Test Account';
        request.Industry = 'Technology';
        request.Phone = '1234567890';

        List<AccountCreation.AccountRequest> requests = new List<AccountCreation.AccountRequest>{ request };

        Test.startTest();
        AccountCreation.createSingleAccount(requests);
        Test.stopTest();

        Account createdAccount = [SELECT Name, Industry, Phone FROM Account WHERE Name = :request.Name LIMIT 1];
        System.assertNotEquals(null, createdAccount, 'Account should be created');
        System.assertEquals('Test Account', createdAccount.Name, 'Account Name should match');
        System.assertEquals('Technology', createdAccount.Industry, 'Account Industry should match');
        System.assertEquals('1234567890', createdAccount.Phone, 'Account Phone should match');
    }

    @isTest
    static void testCreateSingleAccountWithMultipleRequests() {
        AccountCreation.AccountRequest request1 = new AccountCreation.AccountRequest();
        request1.Name = 'Test Account 1';
        
        AccountCreation.AccountRequest request2 = new AccountCreation.AccountRequest();
        request2.Name = 'Test Account 2';

        List<AccountCreation.AccountRequest> requests = new List<AccountCreation.AccountRequest>{ request1, request2 };

        Test.startTest();
        try {
            AccountCreation.createSingleAccount(requests);
            System.assert(false, 'Method should throw an exception for multiple requests');
        } catch (Exception e) {
            System.assertEquals('Exactly one request must be provided.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSingleAccountWithNullRequest() {
        Test.startTest();
        try {
            AccountCreation.createSingleAccount(null);
            System.assert(false, 'Method should throw an exception for null requests');
        } catch (Exception e) {
            System.assertEquals('Exactly one request must be provided.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
}
