public class AccountCreation {
    @InvocableMethod(label='Create Single Account' description='Creates a single Account based on input')
    public static void createSingleAccount(List<AccountRequest> requests) {
        if (requests == null || requests.size() != 1) {
            throw new IllegalArgumentException('Exactly one request must be provided.');
        }

        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new Metadata.NoAccessException('You do not have permission to create Accounts.');
        }

        AccountRequest request = requests[0];
        Account acc = new Account();

        if (Schema.sObjectType.Account.fields.Name.isCreateable()) {
            acc.Name = request.Name;
        } else {
            throw new Metadata.NoAccessException('You do not have permission to set the Name field.');
        }

        if (Schema.sObjectType.Account.fields.Industry.isCreateable()) {
            acc.Industry = request.Industry;
        }

        if (Schema.sObjectType.Account.fields.Phone.isCreateable()) {
            acc.Phone = request.Phone;
        }

        try {
            insert acc;
        } catch (Exception e) {
            System.debug('Error in inserting account: ' + e.getMessage());
            throw e;
        }
    }
    
    public class AccountRequest {
        @InvocableVariable(required=true description='Name of the Account')
        public String Name;

        @InvocableVariable(description='Industry of the Account')
        public String Industry;

        @InvocableVariable(description='Phone number of the Account')
        public String Phone;
    }
}