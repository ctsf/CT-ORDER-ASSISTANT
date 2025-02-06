global with sharing class ProductAvailabilityChecker {

    @InvocableMethod(label='Check Product Availability' description='Checks product availability for an order and suggests replacements if needed.')
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
                return response;
            }
     
            Id orderId;
            try {
                orderId = (Id) request.orderId;
            } catch(Exception e) {
                response.status = 'ERROR';
                response.message = 'Invalid Order ID format.';
                return response;
            }

            orders__Order__c orderRecord = fetchOrder(orderId);
            if (orderRecord == null) {
                response.status = 'ERROR';
                response.message = 'Order not found.';
                return response;
            }

            List<orders__OrderLineItem__c> orderLineItems = fetchOrderLineItems(orderId);
            if (orderLineItems.isEmpty()) {
                response.status = 'ERROR';
                response.message = 'No order line items found for order ' + orderId;
                return response;
            }

            Set<Id> orderLineItemIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            for (orders__OrderLineItem__c oli : orderLineItems) {
                orderLineItemIds.add(oli.Id);
                productIds.add(oli.orders__Product2Id__c);
            }

            Map<Id, Id> oliToDeliveryMap = fetchDeliveryMap(orderLineItemIds);
            Set<Id> deliveryIds = new Set<Id>(oliToDeliveryMap.values());

            Set<Date> deliveryDates = fetchDeliveryDates(deliveryIds);
            if (deliveryDates.isEmpty()) {
                response.status = 'ERROR';
                response.message = 'No delivery dates found for this order.';
                return response;
            }

            Map<Id, List<orders__ProductAvailability__c>> availabilityMap = fetchProductAvailabilities(productIds, orderRecord, deliveryDates);

           
            List<ReplacementMapping> replacementMappings = new List<ReplacementMapping>();
            for (orders__OrderLineItem__c oli : orderLineItems) {
                if (!availabilityMap.containsKey(oli.orders__Product2Id__c)) {
                    List<Id> replacements = findReplacementProducts(oli.orders__Product2Id__c, oli.orders__CatalogId__c, oli.orders__PromotionId__c, orderRecord.orders__PriceBookId__c);
                    if (!replacements.isEmpty()) {
                        ReplacementMapping rm = new ReplacementMapping();
            
                        rm.unavailableProductId = String.valueOf(oli.orders__Product2Id__c);
                        rm.replacementProductIds = new List<String>();
                        for (Id repId : replacements) {
                            rm.replacementProductIds.add(String.valueOf(repId));
                        }
                        replacementMappings.add(rm);
                    }
                }
            }

            response.status = 'SUCCESS';
            response.message = 'Product availability checked successfully.';
            response.replacementMappings = replacementMappings;
        } catch (Exception e) {
            response.status = 'ERROR';
            response.message = 'An error occurred: ' + e.getMessage();
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
            SELECT Id, orders__Product2Id__c, orders__CatalogId__c, orders__PromotionId__c, orders__Quantity__c
            FROM orders__OrderLineItem__c
            WHERE orders__OrderId__c = :orderId
        ];
    }

    private static Map<Id, Id> fetchDeliveryMap(Set<Id> orderLineItemIds) {
        Map<Id, Id> oliToDeliveryMap = new Map<Id, Id>();
        for (orders__DeliveryLineItem__c dli : [
            SELECT orders__OrderLineItemId__c, orders__DeliveryId__c, orders__Quantity__c
            FROM orders__DeliveryLineItem__c
            WHERE orders__OrderLineItemId__c IN :orderLineItemIds AND orders__Quantity__c > 0
        ]) {
            oliToDeliveryMap.put(dli.orders__OrderLineItemId__c, dli.orders__DeliveryId__c);
        }
        return oliToDeliveryMap;
    }

    private static Set<Date> fetchDeliveryDates(Set<Id> deliveryIds) {
        Set<Date> dates = new Set<Date>();
        for (orders__Delivery__c delivery : [
            SELECT Id, orders__DeliveryDate__c
            FROM orders__Delivery__c
            WHERE Id IN :deliveryIds
        ]) {
            dates.add(delivery.orders__DeliveryDate__c);
        }
        return dates;
    }

    private static Map<Id, List<orders__ProductAvailability__c>> fetchProductAvailabilities(
        Set<Id> productIds, orders__Order__c orderRecord, Set<Date> deliveryDates
    ) {
        Map<Id, List<orders__ProductAvailability__c>> availabilityMap = new Map<Id, List<orders__ProductAvailability__c>>();
        List<orders__ProductAvailability__c> availabilities = [
            SELECT orders__Product2Id__c, orders__AvailabilityType__c, orders__StartDate__c, orders__EndDate__c
            FROM orders__ProductAvailability__c
            WHERE orders__IsActive__c = TRUE
              AND orders__SalesOrganizationId__c = :orderRecord.orders__SalesOrganizationId__c
              AND orders__AccountId__c = :orderRecord.orders__AccountId__c
              AND orders__EndDate__c >= :deliveryDates
              AND orders__StartDate__c <= :deliveryDates
              AND orders__Product2Id__c IN :productIds
        ];
        for (orders__ProductAvailability__c pa : availabilities) {
            if (!availabilityMap.containsKey(pa.orders__Product2Id__c)) {
                availabilityMap.put(pa.orders__Product2Id__c, new List<orders__ProductAvailability__c>());
            }
            availabilityMap.get(pa.orders__Product2Id__c).add(pa);
        }
        return availabilityMap;
    }

    private static List<Id> findReplacementProducts(Id productId, Id catalogId, Id promotionId, Id priceBookId) {
        List<Id> replacements = new List<Id>();

        if (catalogId != null) {
            for (orders__CatalogLineItem__c cli : [
                SELECT orders__Product2Id__c 
                FROM orders__CatalogLineItem__c
                WHERE orders__CatalogId__c = :catalogId
            ]) {
                replacements.add(cli.orders__Product2Id__c);
            }
        }

        if (promotionId != null) {
            for (orders__PromotionLineItem__c pli : [
                SELECT orders__Product2Id__c
                FROM orders__PromotionLineItem__c
                WHERE orders__PromotionId__c = :promotionId
            ]) {
                replacements.add(pli.orders__Product2Id__c);
            }
        }
        return replacements;
    }


    global class ProductAvailabilityRequest {
        @InvocableVariable(required=true label='Order ID' description='The ID of the order to check.')
        global String orderId;
    }

    global class ProductAvailabilityResponse {
        @InvocableVariable(label='Status' description='The status of the product availability check.')
        global String status;

        @InvocableVariable(label='Message' description='Details about the availability check.')
        global String message;

        @InvocableVariable(label='Replacement Mappings' description='List of replacement mappings for unavailable products.')
        global List<ReplacementMapping> replacementMappings;
    }

    global class ReplacementMapping {
        @InvocableVariable(label='Unavailable Product ID' description='ID of the unavailable product.')
        global String unavailableProductId;

        @InvocableVariable(label='Replacement Product IDs' description='List of replacement product IDs.')
        global List<String> replacementProductIds;
    }
}
