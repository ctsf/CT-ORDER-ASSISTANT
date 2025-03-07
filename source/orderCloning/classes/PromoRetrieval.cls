global with sharing class PromoRetrieval {
    @InvocableMethod(label='Retrieve Promotions' description='Retrieve promotions assigned to a given account.')
    global static List<PromotionRetrievalResponse> retrievePromotions(List<PromotionRetrievalRequest> requests) {
        List<PromotionRetrievalResponse> responses = new List<PromotionRetrievalResponse>();

        if (!Schema.sObjectType.orders__Promotion__c.isAccessible() || 
            !Schema.sObjectType.orders__Promotion__c.fields.Name.isAccessible() || 
            !Schema.sObjectType.orders__Promotion__c.fields.orders__ExternalId__c.isAccessible() || 
            !Schema.sObjectType.orders__Promotion__c.fields.orders__OrderStartDate__c.isAccessible() || 
            !Schema.sObjectType.orders__Promotion__c.fields.orders__OrderEndDate__c.isAccessible()) {
            throw new System.SecurityException('Insufficient permissions to access Promotion fields.');
        }

        for (PromotionRetrievalRequest request : requests) {
            PromotionRetrievalResponse response = new PromotionRetrievalResponse();

            try {
                if (request.accountId == null) {
                    response.status = 'ERROR';
                    response.message = 'Account ID must be provided.';
                    responses.add(response);
                    continue;
                }

                List<orders__Promotion__c> promotions = [
                    SELECT Id, Name, orders__ExternalId__c, orders__OrderStartDate__c, orders__OrderEndDate__c
                    FROM orders__Promotion__c
                    WHERE orders__IsActive__c = true
                          AND Id IN (SELECT orders__PromotionId__c FROM orders__PromotionAssignment__c WHERE orders__AccountId__c = :request.accountId)
                    ORDER BY Name
                    LIMIT 50
                ];

                if (promotions.isEmpty()) {
                    response.status = 'SUCCESS';
                    response.message = 'No promotions assigned to the given account.';
                    response.promotions = new List<orders__Promotion__c>();
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Promotions retrieved successfully.';
                    response.promotions = promotions;
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }

    global class PromotionRetrievalRequest {
        @InvocableVariable(required=true label='Account ID' description='The Account ID to retrieve promotions for.')
        global Id accountId;
    }

    global class PromotionRetrievalResponse {
        @InvocableVariable(label='Status' description='The status of the promotion retrieval operation.')
        global String status;

        @InvocableVariable(label='Message' description='Details about the promotion retrieval operation.')
        global String message;

        @InvocableVariable(label='Promotions' description='The list of retrieved promotions.')
        global List<orders__Promotion__c> promotions;
    }
}