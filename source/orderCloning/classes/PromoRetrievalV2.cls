global with sharing class PromoRetrievalV2 {
    @InvocableMethod(label='Retrieve Promotions V2' description='Retrieve promotions assigned to a given account with enhanced friendly UI details.')
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
                    response.friendlyUX = 'Please provide a valid Account ID to retrieve promotions.';
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
                    response.friendlyUX = 'No active promotions were found for the provided account.';
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Promotions retrieved successfully.';
                    response.promotions = promotions;

                    // Build a friendly UX summary for each promotion.
                    List<String> promotionSummaries = new List<String>();
                    for (orders__Promotion__c promo : promotions) {
                        String promoName = promo.Name;
                        String externalId = (promo.orders__ExternalId__c != null) ? String.valueOf(promo.orders__ExternalId__c) : 'N/A';
                        String startDate = (promo.orders__OrderStartDate__c != null) ? String.valueOf(promo.orders__OrderStartDate__c) : 'N/A';
                        String endDate = (promo.orders__OrderEndDate__c != null) ? String.valueOf(promo.orders__OrderEndDate__c) : 'N/A';
                        String summary = 'Promotion "' + promoName + '" (External ID: ' + externalId + ') is valid from ' + startDate + ' to ' + endDate;
                        promotionSummaries.add(summary);
                    }
                    response.friendlyUX = 'Retrieved Promotions: ' + String.join(promotionSummaries, '; ');
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
                response.friendlyUX = 'An unexpected error occurred while retrieving promotions. Please contact support if the issue persists.';
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

        @InvocableVariable(label='Friendly UX Message' description='A user-friendly summary of the retrieved promotions for display in chat.')
        global String friendlyUX;
    }
}