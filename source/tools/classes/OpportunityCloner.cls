public with sharing class OpportunityCloner {

    @InvocableMethod(label='Clone Opportunity' description='Clones an opportunity with its products')
    public static List<Id> cloneOpportunities(List<CloneOpportunityRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        if (!Schema.sObjectType.Opportunity.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.Name.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.AccountId.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.CloseDate.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.Pricebook2Id.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.StageName.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required fields on Opportunity.');
        }

        if (!Schema.sObjectType.OpportunityLineItem.isAccessible() ||
            !Schema.sObjectType.OpportunityLineItem.fields.Product2Id.isAccessible() ||
            !Schema.sObjectType.OpportunityLineItem.fields.Quantity.isAccessible() ||
            !Schema.sObjectType.OpportunityLineItem.fields.UnitPrice.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required fields on OpportunityLineItem.');
        }

        List<Opportunity> clonedOpportunities = new List<Opportunity>();
        List<OpportunityLineItem> lineItemsToClone = new List<OpportunityLineItem>();
        Map<Id, Id> originalToClonedOppIdMap = new Map<Id, Id>();

        List<Id> opportunityIds = new List<Id>();
        for (CloneOpportunityRequest request : requests) {
            opportunityIds.add(request.OpportunityId);
        }

        List<Opportunity> originalOpportunities = [
            SELECT Name, AccountId, CloseDate, StageName, Amount, Probability, Description, Pricebook2Id
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        Map<Id, Opportunity> originalOppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : originalOpportunities) {
            originalOppMap.put(opp.Id, opp);
        }

        for (CloneOpportunityRequest request : requests) {
            Opportunity originalOpp = originalOppMap.get(request.OpportunityId);

            if (originalOpp == null) {
                throw new IllegalArgumentException('Opportunity not found for ID: ' + request.OpportunityId);
            }

            Opportunity clonedOpp = originalOpp.clone(false, false, false, false);
            clonedOpp.Name = originalOpp.Name + ' (Clone)';
            clonedOpp.CloseDate = Date.today().addDays(30);
            clonedOpp.StageName = 'Prospecting';

            clonedOpportunities.add(clonedOpp);
        }

        if (!clonedOpportunities.isEmpty()) {
            insert clonedOpportunities;
            for (Integer i = 0; i < clonedOpportunities.size(); i++) {
                originalToClonedOppIdMap.put(requests[i].OpportunityId, clonedOpportunities[i].Id);
            }
        }

        List<OpportunityLineItem> originalLineItems = [
            SELECT OpportunityId, Product2Id, Quantity, UnitPrice
            FROM OpportunityLineItem
            WHERE OpportunityId IN :originalToClonedOppIdMap.keySet()
        ];

        for (OpportunityLineItem item : originalLineItems) {
            OpportunityLineItem clonedItem = item.clone(false, false, false, false);
            clonedItem.OpportunityId = originalToClonedOppIdMap.get(item.OpportunityId);
            lineItemsToClone.add(clonedItem);
        }

        if (!lineItemsToClone.isEmpty()) {
            insert lineItemsToClone;
        }

        return new List<Id>(originalToClonedOppIdMap.values());
    }

    public class CloneOpportunityRequest {
        @InvocableVariable(required=true description='ID of the Opportunity to clone')
        public Id OpportunityId;
    }
}