public with sharing class OpportunityMerger {

    @InvocableMethod(label='Merge Opportunities' description='Merges data from a secondary opportunity into a primary one, then deletes the secondary')
    public static void mergeOpps(List<MergeOppRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        MergeOppRequest req = requests[0];

        if (req.PrimaryOppId == null) {
            throw new IllegalArgumentException('PrimaryOppId is required.');
        }
        if (req.SecondaryOppId == null) {
            throw new IllegalArgumentException('SecondaryOppId is required.');
        }
        if (req.PrimaryOppId == req.SecondaryOppId) {
            throw new IllegalArgumentException('Primary and Secondary Opp Id cannot be the same.');
        }

        Schema.DescribeSObjectResult oppDescribe = Opportunity.SObjectType.getDescribe();
        if (!oppDescribe.isAccessible() || !oppDescribe.isUpdateable() || !oppDescribe.isDeletable()) {
            throw new Metadata.NoAccessException('You do not have permission to access or modify Opportunities.');
        }

        List<Opportunity> opps = [
            SELECT Id, Amount, CloseDate, Description, StageName
            FROM Opportunity
            WHERE Id IN :new List<Id>{req.PrimaryOppId, req.SecondaryOppId}
        ];

        if (opps.size() != 2) {
            throw new IllegalArgumentException('Could not find both opportunities.');
        }

        Opportunity primaryOpp;
        Opportunity secondaryOpp;

        for (Opportunity o : opps) {
            if (o.Id == req.PrimaryOppId) {
                primaryOpp = o;
            } else {
                secondaryOpp = o;
            }
        }

        if (primaryOpp == null || secondaryOpp == null) {
            throw new IllegalArgumentException('Primary or secondary opportunity not found.');
        }

        if (primaryOpp.Amount == null && secondaryOpp.Amount != null) {
            primaryOpp.Amount = secondaryOpp.Amount;
        }
        if (primaryOpp.CloseDate == null && secondaryOpp.CloseDate != null) {
            primaryOpp.CloseDate = secondaryOpp.CloseDate;
        }
        if ((primaryOpp.Description == null || String.isBlank(primaryOpp.Description.trim())) && secondaryOpp.Description != null) {
            primaryOpp.Description = secondaryOpp.Description;
        }

        update primaryOpp;
        delete secondaryOpp;
    }

    public class MergeOppRequest {
        @InvocableVariable(required=true description='ID of the primary Opportunity')
        public Id PrimaryOppId;

        @InvocableVariable(required=true description='ID of the secondary Opportunity to merge and delete')
        public Id SecondaryOppId;
    }
}