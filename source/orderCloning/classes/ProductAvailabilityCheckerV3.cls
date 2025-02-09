global with sharing class ProductAvailabilityCheckerV3 {

    @InvocableMethod(label='Check Product Availability V3' 
                       description='Checks product availability for an order and returns order line items with Product default availability set to NotAvailable. Each response includes the Product2 object, the Order Line Item, and a status.')
    global static List<ProductAvailabilityResponse> checkProductAvailability(List<ProductAvailabilityRequest> requests) {
        List<ProductAvailabilityResponse> responses = new List<ProductAvailabilityResponse>();
        for (ProductAvailabilityRequest request : requests) {
            responses.addAll(processSingleRequest(request));
        }
        return responses;
    }

    private static List<ProductAvailabilityResponse> processSingleRequest(ProductAvailabilityRequest request) {
        List<ProductAvailabilityResponse> localResponses = new List<ProductAvailabilityResponse>();
        
        // Validate orderId
        if (String.isBlank(request.orderId)) {
            ProductAvailabilityResponse resp = new ProductAvailabilityResponse();
            resp.status = 'ERROR';
            resp.orderLineItem = null;
            resp.product = null;
            localResponses.add(resp);
            return localResponses;
        }
        
        Id orderId;
        try {
            orderId = (Id) request.orderId;
        } catch(Exception e) {
            ProductAvailabilityResponse resp = new ProductAvailabilityResponse();
            resp.status = 'ERROR';
            resp.orderLineItem = null;
            resp.product = null;
            localResponses.add(resp);
            return localResponses;
        }
        
        orders__Order__c orderRecord = fetchOrder(orderId);
        if (orderRecord == null) {
            ProductAvailabilityResponse resp = new ProductAvailabilityResponse();
            resp.status = 'ERROR';
            resp.orderLineItem = null;
            resp.product = null;
            localResponses.add(resp);
            return localResponses;
        }
        
        List<orders__OrderLineItem__c> orderLineItems = fetchOrderLineItems(orderId);
        if (orderLineItems.isEmpty()) {
            ProductAvailabilityResponse resp = new ProductAvailabilityResponse();
            resp.status = 'ERROR';
            resp.orderLineItem = null;
            resp.product = null;
            localResponses.add(resp);
            return localResponses;
        }
        
        // Process each order line item; if its Product2 has default availability "NotAvailable", add to responses.
        for (orders__OrderLineItem__c oli : orderLineItems) {
            if (oli.orders__Product2Id__r != null &&
                oli.orders__Product2Id__r.orders__DefaultAvailabilityType__c != null &&
                oli.orders__Product2Id__r.orders__DefaultAvailabilityType__c.equalsIgnoreCase('NotAvailable')) {
                
                ProductAvailabilityResponse resp = new ProductAvailabilityResponse();
                resp.orderLineItem = oli;
                resp.product = oli.orders__Product2Id__r;
                resp.status = 'NOT AVAILABLE';
                localResponses.add(resp);
            }
        }
        
        // If no order line items were flagged, return a single response indicating all products are available.
        if (localResponses.isEmpty()) {
            ProductAvailabilityResponse resp = new ProductAvailabilityResponse();
            resp.status = 'SUCCESS';
            resp.orderLineItem = null;
            resp.product = null;
            localResponses.add(resp);
        }
        
        return localResponses;
    }
    
    private static orders__Order__c fetchOrder(Id orderId) {
        List<orders__Order__c> orders = [
            SELECT Id, orders__SalesOrganizationId__c, orders__PriceBookId__c, orders__AccountId__c
            FROM orders__Order__c
            WHERE Id = :orderId
            LIMIT 1
        ];
        return orders.isEmpty() ? null : orders[0];
    }
    
    private static List<orders__OrderLineItem__c> fetchOrderLineItems(Id orderId) {
        return [
            SELECT Id, orders__Product2Id__c, 
                   orders__Product2Id__r.Name, 
                   orders__Product2Id__r.orders__DefaultAvailabilityType__c,
                   orders__CatalogId__c, 
                   orders__PromotionId__c, 
                   orders__Quantity__c
            FROM orders__OrderLineItem__c
            WHERE orders__OrderId__c = :orderId
        ];
    }
    
    global class ProductAvailabilityRequest {
        @InvocableVariable(required=true label='Order ID' description='The ID of the order to check.')
        global String orderId;
    }
    
    global class ProductAvailabilityResponse {
        @InvocableVariable(label='Order Line Item' description='The Order Line Item with availability status.')
        global orders__OrderLineItem__c orderLineItem;
        
        @InvocableVariable(label='Product' description='The associated Product2 object.')
        global Product2 product;
        
        @InvocableVariable(label='Status' description='Availability status of the order line item.')
        global String status;
    }
}