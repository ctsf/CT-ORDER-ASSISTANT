public with sharing class AccountOpportunityFetcher {

    @InvocableMethod(label='Get Related Opportunities for Account' description='Returns a list of opportunities related to the specified account')
    public static List<List<OpportunityResponse>> getOpportunities(List<AccountRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        AccountRequest req = requests[0];

        if (req.AccountId == null) {
            throw new IllegalArgumentException('AccountId is required.');
        }

        if (!Schema.sObjectType.Opportunity.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.Name.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.StageName.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.Amount.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Opportunity fields.');
        }

        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount
            FROM Opportunity
            WHERE AccountId = :req.AccountId
            ORDER BY LastModifiedDate DESC
        ];

        List<OpportunityResponse> responses = new List<OpportunityResponse>();
        for (Opportunity o : opps) {
            responses.add(new OpportunityResponse(o.Id, o.Name, o.StageName, o.Amount));
        }

        return new List<List<OpportunityResponse>>{responses};
    }

    public class AccountRequest {
        @InvocableVariable(required=true description='ID of the Account')
        public Id AccountId;
    }

    public class OpportunityResponse {
        @InvocableVariable(description='ID of the Opportunity')
        public Id OpportunityId;
        @InvocableVariable(description='Name of the Opportunity')
        public String Name;
        @InvocableVariable(description='Stage Name of the Opportunity')
        public String StageName;
        @InvocableVariable(description='Amount of the Opportunity')
        public Decimal Amount;

        public OpportunityResponse(Id opportunityId, String name, String stageName, Decimal amount) {
            this.OpportunityId = opportunityId;
            this.Name = name;
            this.StageName = stageName;
            this.Amount = amount;
        }
    }
}