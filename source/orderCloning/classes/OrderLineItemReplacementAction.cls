global with sharing class OrderLineItemReplacementAction {

    /**
     * Replaces a single OrderLineItem’s product with a new product and refreshes related lookup fields.
     * The following fields on the OrderLineItem are updated:
     *   - orders__Product2Id__c is set to the new product Id.
     *   - orders__CatalogLineItemId__c is set by querying the Catalog Line Item for the new product.
     *   - orders__PriceBookLineItemId__c is set by querying the PriceBook Line Item for the new product using the PriceBookId from the Order.
     *
     * Delivery line items are not modified.
     */
    @InvocableMethod(label='Replace Single Order Line Item'
                       description='Updates a single order line item with a new product and returns the updated object.')
    public static List<ReplacementActionResponse> replaceOrderLineItem(List<ReplacementActionRequest> requests) {
        List<ReplacementActionResponse> responses = new List<ReplacementActionResponse>();
        
        for (ReplacementActionRequest req : requests) {
            ReplacementActionResponse resp = new ReplacementActionResponse();
            resp.orderLineItemId = req.orderLineItemId;
            
            if (String.isBlank(req.orderLineItemId) || String.isBlank(req.newProductId)) {
                resp.status = 'ERROR';
                resp.message = 'OrderLineItem Id and New Product Id must be provided.';
                responses.add(resp);
                continue;
            }
            
            try {
                Id oliId = (Id) req.orderLineItemId;
                Id newProdId = (Id) req.newProductId;
                
                // Query the OrderLineItem record including the related Order's PriceBookId.
                orders__OrderLineItem__c oli = [
                    SELECT Id, orders__Quantity__c, orders__Product2Id__c, 
                           orders__CatalogLineItemId__c, orders__PriceBookLineItemId__c,
                           orders__OrderId__r.orders__PriceBookId__c
                    FROM orders__OrderLineItem__c
                    WHERE Id = :oliId
                    LIMIT 1
                ];
                
                // Query Catalog Line Item for the new product.
                orders__CatalogLineItem__c catalogItem;
                List<orders__CatalogLineItem__c> catalogList = [
                    SELECT Id
                    FROM orders__CatalogLineItem__c
                    WHERE orders__Product2Id__c = :newProdId
                    LIMIT 1
                ];
                if (!catalogList.isEmpty()) {
                    catalogItem = catalogList[0];
                }
                
                // Query PriceBook Line Item for the new product using PriceBookId from the Order.
                orders__PriceBookLineItem__c pbLineItem;
                List<orders__PriceBookLineItem__c> pbList = [
                    SELECT Id
                    FROM orders__PriceBookLineItem__c
                    WHERE orders__Product2Id__c = :newProdId
                      AND orders__PriceBookId__c = :oli.orders__OrderId__r.orders__PriceBookId__c
                    LIMIT 1
                ];
                if (!pbList.isEmpty()) {
                    pbLineItem = pbList[0];
                }
                
                // Update OrderLineItem fields.
                oli.orders__Product2Id__c = newProdId;
                oli.orders__CatalogLineItemId__c = (catalogItem != null) ? catalogItem.Id : null;
                oli.orders__PriceBookLineItemId__c = (pbLineItem != null) ? pbLineItem.Id : null;
                
                update oli;
                
                resp.status = 'SUCCESS';
                resp.message = 'Order line item updated successfully.';
                resp.updatedOrderLineItem = oli;
            } catch (Exception e) {
                resp.status = 'ERROR';
                resp.message = 'Error during replacement: ' + e.getMessage();
            }
            responses.add(resp);
        }
        
        return responses;
    }
    
    global class ReplacementActionRequest {
        @InvocableVariable(label='Order Line Item Id'
                             description='The Id of the order line item to be replaced.')
        global String orderLineItemId;
        
        @InvocableVariable(label='New Product Id'
                             description='The Id of the new product that should replace the current product.')
        global String newProductId;
    }
    
    global class ReplacementActionResponse {
        @InvocableVariable(label='Order Line Item Id'
                             description='The Id of the order line item that was processed.')
        global String orderLineItemId;
        
        @InvocableVariable(label='Status'
                             description='The status of the replacement action (SUCCESS or ERROR).')
        global String status;
        
        @InvocableVariable(label='Message'
                             description='A message describing the outcome of the action.')
        global String message;
        
        @InvocableVariable(label='Updated Order Line Item'
                             description='The updated OrderLineItem object after replacement.')
        global orders__OrderLineItem__c updatedOrderLineItem;
    }
}