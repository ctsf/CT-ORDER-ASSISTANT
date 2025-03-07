global with sharing class ProductAvailabilityCheckerV2 {

    @InvocableMethod(label='Check Product Availability V2' 
                       description='Checks product availability for an order and returns order line items with Product default availability set to NotAvailable, along with a friendly UX message.')
    global static List<ProductAvailabilityResponse> checkProductAvailability(List<ProductAvailabilityRequest> requests) {
        List<ProductAvailabilityResponse> responses = new List<ProductAvailabilityResponse>();
        for (ProductAvailabilityRequest request : requests) {
            responses.add(processSingleRequest(request));
        }
        return responses;
    }

    private static ProductAvailabilityResponse processSingleRequest(ProductAvailabilityRequest request) {
        ProductAvailabilityResponse response = new ProductAvailabilityResponse();
        try {
            if (String.isBlank(request.orderId)) {
                response.status = 'ERROR';
                response.message = 'Order ID must be provided.';
                response.friendlyUX = 'Please provide a valid Order ID to check product availability.';
                return response;
            }
     
            Id orderId;
            try {
                orderId = (Id) request.orderId;
            } catch(Exception e) {
                response.status = 'ERROR';
                response.message = 'Invalid Order ID format.';
                response.friendlyUX = 'The Order ID provided appears to be invalid. Please check and try again.';
                return response;
            }

            orders__Order__c orderRecord = fetchOrder(orderId);
            if (orderRecord == null) {
                response.status = 'ERROR';
                response.message = 'Order not found.';
                response.friendlyUX = 'No order could be found for the provided ID. Please verify the Order ID.';
                return response;
            }

            List<orders__OrderLineItem__c> orderLineItems = fetchOrderLineItems(orderId);
            if (orderLineItems.isEmpty()) {
                response.status = 'ERROR';
                response.message = 'No order line items found for order ' + orderId;
                response.friendlyUX = 'No products were found on the order. Please check the order details.';
                return response;
            }

            List<OrderLineItemResponse> notAvailableItems = new List<OrderLineItemResponse>();
            for (orders__OrderLineItem__c oli : orderLineItems) {
                if (oli.orders__Product2Id__r != null &&
                    oli.orders__Product2Id__r.orders__DefaultAvailabilityType__c != null &&
                    oli.orders__Product2Id__r.orders__DefaultAvailabilityType__c.equalsIgnoreCase('NotAvailable')) {
                    
                    OrderLineItemResponse oliResp = new OrderLineItemResponse();
                    oliResp.orderLineItemId = String.valueOf(oli.Id);
                    oliResp.productName = oli.orders__Product2Id__r.Name;
                    oliResp.productId= oli.orders__Product2Id__c;
                    oliResp.status = 'NOT AVAILABLE';
                    oliResp.message = 'Product default availability is set to NotAvailable.';
                    notAvailableItems.add(oliResp);
                }
            }

            if (notAvailableItems.isEmpty()) {
                response.status = 'SUCCESS';
                response.message = 'No order line items with Product default availability set to NotAvailable were found.';
                response.friendlyUX = 'All products on this order appear to be available.';
            } else {
                response.status = 'SUCCESS';
                response.message = 'Order line items with Product default availability set to NotAvailable found.';
                response.orderLineItems = notAvailableItems;
                
                // Build a friendly UX summary for the unavailable products.
                List<String> summaryList = new List<String>();
                for (OrderLineItemResponse item : notAvailableItems) {
                    summaryList.add('Product "' + item.productName + '" is not available');
                }
                response.friendlyUX = 'Unavailable Products: ' + String.join(summaryList, '; ');
            }
        } catch (Exception e) {
            response.status = 'ERROR';
            response.message = 'An error occurred: ' + e.getMessage();
            response.friendlyUX = 'An unexpected error occurred while checking product availability. Please contact support if this persists.';
        }
        return response;
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
        @InvocableVariable(label='Status' description='The overall status of the product availability check.')
        global String status;

        @InvocableVariable(label='Message' description='Overall message about the availability check.')
        global String message;

        @InvocableVariable(label='Order Line Items' description='List of order line items with availability status that have Product default availability set to NotAvailable.')
        global List<OrderLineItemResponse> orderLineItems;

        @InvocableVariable(label='Friendly UX Message' description='A user-friendly summary of the unavailable products for display in chat.')
        global String friendlyUX;
    }

    global class OrderLineItemResponse {
        @InvocableVariable(label='Order Line Item ID' description='ID of the order line item.')
        global String orderLineItemId;

        @InvocableVariable(label='Product2 ID' description='ID of the Product2.')
        global String productId;

        @InvocableVariable(label='Product Name' description='Name of the product.')
        global String productName;

        @InvocableVariable(label='Status' description='Availability status of the order line item.')
        global String status;

        @InvocableVariable(label='Message' description='Message regarding the product availability for this order line item.')
        global String message;
    }
}