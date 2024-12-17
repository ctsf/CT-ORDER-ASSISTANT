@IsTest
public with sharing class Test_AccountRetrieval {
    @IsTest
    static void testRetrieveAccountsWithPartialName() {
        Account testAccount1 = new Account(Name = 'Test Company Alpha', Industry = 'Technology', Phone = '1234567890', BillingCity = 'New York');
        Account testAccount2 = new Account(Name = 'Test Company Beta', Industry = 'Finance', Phone = '9876543210', BillingCity = 'San Francisco');
        insert new List<Account>{testAccount1, testAccount2};

        AccountRetrieval.AccountRetrievalRequest request = new AccountRetrieval.AccountRetrievalRequest();
        request.partialName = 'Test Company';

        List<AccountRetrieval.AccountRetrievalRequest> requests = new List<AccountRetrieval.AccountRetrievalRequest>{request};

        Test.startTest();
        List<AccountRetrieval.AccountRetrievalResponse> responses = AccountRetrieval.retrieveAccounts(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'One response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        System.assertEquals('Accounts retrieved successfully.', responses[0].message, 'Message should indicate successful retrieval.');
        System.assertNotEquals(null, responses[0].accounts, 'Accounts list should not be null.');
        System.assertEquals(2, responses[0].accounts.size(), 'Two accounts should be retrieved.');
    }

    @IsTest
    static void testRetrieveAccountsNoMatchingRecords() {
        AccountRetrieval.AccountRetrievalRequest request = new AccountRetrieval.AccountRetrievalRequest();
        request.partialName = 'NonExistentName';

        List<AccountRetrieval.AccountRetrievalRequest> requests = new List<AccountRetrieval.AccountRetrievalRequest>{request};
        
        Test.startTest();
        List<AccountRetrieval.AccountRetrievalResponse> responses = AccountRetrieval.retrieveAccounts(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'One response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        System.assertEquals('No accounts found for the given partial name.', responses[0].message, 'Message should indicate no records found.');
        System.assertEquals(0, responses[0].accounts.size(), 'No accounts should be retrieved.');
    }

    @IsTest
    static void testRetrieveAccountsMissingPartialName() {
        AccountRetrieval.AccountRetrievalRequest request = new AccountRetrieval.AccountRetrievalRequest();
        request.partialName = null;

        List<AccountRetrieval.AccountRetrievalRequest> requests = new List<AccountRetrieval.AccountRetrievalRequest>{request};

        Test.startTest();
        List<AccountRetrieval.AccountRetrievalResponse> responses = AccountRetrieval.retrieveAccounts(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'One response should be returned.');
        System.assertEquals('ERROR', responses[0].status, 'The response status should be ERROR.');
        System.assertEquals('Partial name must be provided.', responses[0].message, 'Error message should match.');
    }
}