public with sharing class AccountRetrieval {
    private static final Integer DEFAULT_LIMIT = 5;

    @InvocableMethod(label='Retrieve Accounts' description='Retrieve accounts by partial name.')
    public static List<AccountRetrievalResponse> retrieveAccounts(List<AccountRetrievalRequest> requests) {
        List<AccountRetrievalResponse> responses = new List<AccountRetrievalResponse>();

        for (AccountRetrievalRequest request : requests) {
            AccountRetrievalResponse response = new AccountRetrievalResponse();

            try {
                if (String.isBlank(request.partialName)) {
                    response.status = 'ERROR';
                    response.message = 'Partial name must be provided.';
                    responses.add(response);
                    continue;
                }

                List<Account> accounts = getAccountsByNameLike(request.partialName);

                if (accounts.isEmpty()) {
                    response.status = 'SUCCESS';
                    response.message = 'No accounts found for the given partial name.';
                    response.accounts = new List<Account>();
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Accounts retrieved successfully.';
                    response.accounts = new List<Account>();
                    response.accounts.addAll(accounts);
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }

    public class AccountRetrievalRequest {
        @InvocableVariable(required=true label='Partial Name' description='The partial name to search for.')
        public String partialName;
    }

    public class AccountRetrievalResponse {
        @InvocableVariable(label='Status' description='The status of the account retrieval operation.')
        public String status;

        @InvocableVariable(label='Message' description='Details about the account retrieval operation.')
        public String message;

        @InvocableVariable(label='Accounts' description='The list of retrieved accounts.')
        public List<Account> accounts;
    }

    public static List<Account> getAccountsByNameLike(String partialName) {
        if (String.isBlank(partialName)) {
            throw new IllegalArgumentException('Partial name cannot be null or empty.');
        }
       
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Account records.');
        }

        String searchPattern = '%' + partialName + '%';

        return [
            SELECT Id, Name, Industry, Phone, BillingCity
            FROM Account
            WHERE Name LIKE :searchPattern
            ORDER BY Name ASC
            LIMIT :DEFAULT_LIMIT
        ];
    }
}