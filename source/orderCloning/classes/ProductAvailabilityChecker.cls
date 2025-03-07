global with sharing class ProductAvailabilityChecker {

    @InvocableMethod(label='Check Product Availability' 
                       description='Checks product availability for an order and returns order line items with their availability status.')
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

            // Собираем ID продуктов и строки заказа.
            Set<Id> productIds = new Set<Id>();
            Set<Id> orderLineItemIds = new Set<Id>();
            for (orders__OrderLineItem__c oli : orderLineItems) {
                orderLineItemIds.add(oli.Id);
                productIds.add(oli.orders__Product2Id__c);
            }
            
            // Получаем связанные доставки для строк заказа.
            Map<Id, Id> oliToDeliveryMap = fetchDeliveryMap(orderLineItemIds);
            Set<Id> deliveryIds = new Set<Id>(oliToDeliveryMap.values());
            Set<Date> deliveryDates = fetchDeliveryDates(deliveryIds);
            if (deliveryDates.isEmpty()) {
                response.status = 'ERROR';
                response.message = 'No delivery dates found for this order.';
                return response;
            }
            
            // Запрашиваем записи Product Availability для всех продуктов.
            Map<Id, List<orders__ProductAvailability__c>> availabilityMap = fetchProductAvailabilities(productIds, orderRecord, deliveryDates);
            
            // Формируем список обёрток для строк заказа.
            List<OrderLineItemResponse> oliResponses = new List<OrderLineItemResponse>();
            for (orders__OrderLineItem__c oli : orderLineItems) {
                OrderLineItemResponse oliResp = new OrderLineItemResponse();
                oliResp.orderLineItemId = String.valueOf(oli.Id);
                oliResp.productName = oli.orders__Product2Id__r.Name;
                
                // Если дефолтное состояние продукта равно "unavailable", проверяем записи PA.
                if (oli.orders__Product2Id__r.orders__DefaultAvailabilityType__c != null &&
                    oli.orders__Product2Id__r.orders__DefaultAvailabilityType__c.equalsIgnoreCase('unavailable')) {
                    
                    List<orders__ProductAvailability__c> paList = availabilityMap.get(oli.orders__Product2Id__c);
                    Boolean productIsUnavailable = false;
                    // Если нет PA записей – продукт недоступен.
                    if (paList == null || paList.isEmpty()) {
                        productIsUnavailable = true;
                    } else {
                        // Если записи PA есть, проверяем наличие хотя бы одной с типом "available".
                        Boolean foundAvailable = false;
                        for (orders__ProductAvailability__c pa : paList) {
                            if (pa.orders__AvailabilityType__c != null &&
                                pa.orders__AvailabilityType__c.equalsIgnoreCase('available')) {
                                foundAvailable = true;
                                break;
                            }
                        }
                        // Если не найдено ни одной записи с типом "available", продукт недоступен.
                        if (!foundAvailable) {
                            productIsUnavailable = true;
                        }
                    }
                    
                    if (productIsUnavailable) {
                        oliResp.status = 'UNAVAILABLE';
                        oliResp.message = 'Product is unavailable (default is unavailable and no available PA found).';
                    } else {
                        oliResp.status = 'AVAILABLE';
                        oliResp.message = 'Product is available.';
                    }
                } else {
                    // Если дефолтное состояние продукта не "unavailable", считаем его доступным.
                    oliResp.status = 'AVAILABLE';
                    oliResp.message = 'Product is available.';
                }
                oliResponses.add(oliResp);
            }

            response.status = 'SUCCESS';
            response.message = 'Product availability checked successfully.';
            response.orderLineItems = oliResponses;
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
            SELECT Id, orders__Product2Id__c, orders__Product2Id__r.Name, orders__Product2Id__r.orders__DefaultAvailabilityType__c,
                   orders__CatalogId__c, orders__PromotionId__c, orders__Quantity__c
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

    global class ProductAvailabilityRequest {
        @InvocableVariable(required=true label='Order ID' description='The ID of the order to check.')
        global String orderId;
    }

    global class ProductAvailabilityResponse {
        @InvocableVariable(label='Status' description='The overall status of the product availability check.')
        global String status;

        @InvocableVariable(label='Message' description='Overall message about the availability check.')
        global String message;

        @InvocableVariable(label='Order Line Items' description='List of order line items with their availability status and message.')
        global List<OrderLineItemResponse> orderLineItems;
    }

    global class OrderLineItemResponse {
        @InvocableVariable(label='Order Line Item ID' description='ID of the order line item.')
        global String orderLineItemId;

        @InvocableVariable(label='Product Name' description='Name of the product.')
        global String productName;

        @InvocableVariable(label='Status' description='Availability status of the order line item.')
        global String status;

        @InvocableVariable(label='Message' description='Message regarding the product availability for this order line item.')
        global String message;
    }
}