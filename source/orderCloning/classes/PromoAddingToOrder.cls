global with sharing class PromoAddingToOrder {
    @InvocableMethod(label='Add Promotions to Order' description='Adds promotion line items to an existing order.')
    global static List<PromotionAddingResponse> addPromotions(List<PromotionAddingRequest> requests) {
        List<PromotionAddingResponse> responses = new List<PromotionAddingResponse>();

        for (PromotionAddingRequest request : requests) {
            PromotionAddingResponse response = new PromotionAddingResponse();

            try {
                if (String.isBlank(request.orderId) || String.isBlank(request.promotionId)) {
                    response.status = 'ERROR';
                    response.message = 'Order ID and Promotion ID must be provided.';
                    responses.add(response);
                    continue;
                }

                // Retrieve existing order
                orders__Order__c order = [
                    SELECT Id, orders__AccountId__c, orders__SalesOrganizationId__c, orders__PriceBookId__c
                    FROM orders__Order__c
                    WHERE Id = :request.orderId
                    LIMIT 1
                ];

                if (order == null) {
                    response.status = 'ERROR';
                    response.message = 'Order not found.';
                    responses.add(response);
                    continue;
                }

                // Retrieve promotion line items for the given promotion
                List<orders__PromotionLineItem__c> promoLineItems = [
                    SELECT Id, orders__Product2Id__c, orders__PromotionId__c, orders__IsActive__c
                    FROM orders__PromotionLineItem__c
                    WHERE orders__PromotionId__c = :request.promotionId
                          AND orders__IsActive__c = true
                ];

                if (promoLineItems.isEmpty()) {
                    response.status = 'ERROR';
                    response.message = 'No active promotion line items found for this promotion.';
                    responses.add(response);
                    continue;
                }

                // Collect product IDs from promo line items
                Set<Id> productIds = new Set<Id>();
                for (orders__PromotionLineItem__c promoItem : promoLineItems) {
                    productIds.add(promoItem.orders__Product2Id__c);
                }

                // Retrieve PriceBookLineItems for the order's PriceBook and the relevant products
                Map<Id, Id> productToPriceBookLineItemMap = new Map<Id, Id>();
                List<orders__PriceBookLineItem__c> priceBookLineItems = [
                    SELECT Id, orders__Product2Id__c
                    FROM orders__PriceBookLineItem__c
                    WHERE orders__PriceBookId__c = :order.orders__PriceBookId__c
                          AND orders__Product2Id__c IN :productIds
                ];

                for (orders__PriceBookLineItem__c pbli : priceBookLineItems) {
                    productToPriceBookLineItemMap.put(pbli.orders__Product2Id__c, pbli.Id);
                }

                // Create order line items from promotion line items
                List<orders__OrderLineItem__c> newOrderLineItems = new List<orders__OrderLineItem__c>();

                for (orders__PromotionLineItem__c promoItem : promoLineItems) {
                    orders__OrderLineItem__c orderLineItem = new orders__OrderLineItem__c();
                    orderLineItem.orders__OrderId__c = request.orderId;
                    orderLineItem.orders__Product2Id__c = promoItem.orders__Product2Id__c;
                    orderLineItem.orders__PromotionId__c = promoItem.orders__PromotionId__c;
                    orderLineItem.orders__PromotionLineItemId__c = promoItem.Id;
                    orderLineItem.orders__PriceBookId__c = order.orders__PriceBookId__c;

                    // Link the correct PriceBookLineItem if available
                    if (productToPriceBookLineItemMap.containsKey(promoItem.orders__Product2Id__c)) {
                        orderLineItem.orders__PriceBookLineItemId__c = productToPriceBookLineItemMap.get(promoItem.orders__Product2Id__c);
                    }

                    newOrderLineItems.add(orderLineItem);
                }

                // Insert the new order line items
                if (!newOrderLineItems.isEmpty()) {
                    insert newOrderLineItems;
                    response.status = 'SUCCESS';
                    response.message = 'Promotions added successfully.';
                    response.addedOrderLineItems = newOrderLineItems;
                } else {
                    response.status = 'ERROR';
                    response.message = 'No order line items were created.';
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }

    global class PromotionAddingRequest {
        @InvocableVariable(required=true label='Order ID' description='The ID of the order to which promotions will be added.')
        global Id orderId;

        @InvocableVariable(required=true label='Promotion ID' description='The ID of the promotion whose items will be added.')
        global Id promotionId;
    }

    global class PromotionAddingResponse {
        @InvocableVariable(label='Status' description='The status of the promotion addition operation.')
        global String status;

        @InvocableVariable(label='Message' description='Details about the promotion addition operation.')
        global String message;

        @InvocableVariable(label='Added Order Line Items' description='The list of added order line items.')
        global List<orders__OrderLineItem__c> addedOrderLineItems;
    }
}