public with sharing class OrderCloneUtility {


    private Id orderId;
    private Id newAccountId;
    private Boolean cloneDeliveriesFlag;
    private Id accountId;

    // Constructor to initialize variables
    public OrderCloneUtility(Id orderId, Id newAccountId, Boolean cloneDeliveriesFlag, Id accountId) {
        this.orderId = orderId;
        this.newAccountId = newAccountId;
        this.cloneDeliveriesFlag = cloneDeliveriesFlag;
        this.accountId = accountId;
    }

    public Id cloneOrder() {
        Id sourceOrderId = orderId != null ? orderId : getLastOrderForAccount();
        if (sourceOrderId == null) {
            throw new IllegalArgumentException('No valid orderId or accountId provided for cloning.');
        }

        orders__Order__c originalOrder = [
            SELECT  Id, 
                    orders__OrderType__c,
                    orders__Stage__c,
                    orders__SalesOrganizationId__c,
                    orders__AccountId__c,
                    orders__PriceBookId__c,
                    (SELECT Id, 
                            orders__CatalogId__c,
                            orders__PromotionId__c,
                            orders__CatalogLineItemId__c,
                            orders__PriceBookLineItemId__c, 
                            orders__PriceBookId__c,
                            orders__Quantity__c,
                            orders__Product2Id__c
                    FROM orders__OrderLineItems__r),
                   (SELECT Id, 
                           Name, 
                           orders__OrderId__c,
                           orders__AccountId__c,
                           orders__DeliveryDate__c,
                           (SELECT Id, 
                                   Name, 
                                   orders__DeliveryId__c, 
                                   orders__OrderLineItemId__c,
                                   orders__ListPrice__c,
                                   orders__TotalPrice__c,
                                   orders__Quantity__c,
                                   orders__Product2Id__c
                            FROM orders__DeliveryLineItems__r)
                    FROM orders__Deliveries__r)
            FROM orders__Order__c
            WHERE Id = :sourceOrderId
            LIMIT 1
        ];

        // Clone the order and replace AccountId if specified
        orders__Order__c clonedOrder = originalOrder.clone(false, true, false, false);
        if (newAccountId != null) {
            clonedOrder.orders__AccountId__c = newAccountId;
        }

        clonedOrder.orders__Stage__c = 'OnHold';

        insert clonedOrder;

        // Clone order line items
        Map<Id, Id> orderLineItemIdMap = cloneOrderLineItems(originalOrder.orders__OrderLineItems__r, clonedOrder.Id);

        // Conditionally clone deliveries
        if (cloneDeliveriesFlag) {
            cloneDeliveries(originalOrder, clonedOrder.Id, orderLineItemIdMap);
        }

        return clonedOrder.Id;
    }

    private Map<Id, Id> cloneOrderLineItems(List<orders__OrderLineItem__c> originalOrderLineItems, Id clonedOrderId) {
        Map<Id, Id> orderLineItemIdMap = new Map<Id, Id>();

        if (originalOrderLineItems != null && !originalOrderLineItems.isEmpty()) {
            List<orders__OrderLineItem__c> clonedOrderLineItems = new List<orders__OrderLineItem__c>();
            for (orders__OrderLineItem__c oli : originalOrderLineItems) {
                orders__OrderLineItem__c clonedOli = oli.clone(false, true, false, false);
                clonedOli.orders__OrderId__c = clonedOrderId;
                clonedOrderLineItems.add(clonedOli);
            }

            try {
                insert clonedOrderLineItems;
            } catch (DmlException e) {
                System.debug('Error inserting cloned OrderLineItems: ' + e.getMessage());
                throw e;
            }

            for (Integer i = 0; i < originalOrderLineItems.size(); i++) {
                orderLineItemIdMap.put(originalOrderLineItems[i].Id, clonedOrderLineItems[i].Id);
            }
        }

        return orderLineItemIdMap;
    }

    private void cloneDeliveries(orders__Order__c originalOrder, Id clonedOrderId, Map<Id, Id> orderLineItemIdMap) {
        List<orders__Delivery__c> clonedDeliveries = new List<orders__Delivery__c>();
        List<orders__DeliveryLineItem__c> clonedDeliveryLineItems = new List<orders__DeliveryLineItem__c>();

        Map<Id, Id> deliveryIdMap = new Map<Id, Id>();

        if (originalOrder.orders__Deliveries__r != null) {
            for (orders__Delivery__c originalDelivery : originalOrder.orders__Deliveries__r) {
                orders__Delivery__c clonedDelivery = originalDelivery.clone(false, true, false, false);
                clonedDelivery.orders__OrderId__c = clonedOrderId;

                if (newAccountId != null) {
                    clonedDelivery.orders__AccountId__c = newAccountId;
                }

                clonedDeliveries.add(clonedDelivery);
            }

            try {
                insert clonedDeliveries;
            } catch (DmlException e) {
                System.debug('Error inserting cloned Deliveries: ' + e.getMessage());
                throw e;
            }

            for (Integer i = 0; i < originalOrder.orders__Deliveries__r.size(); i++) {
                deliveryIdMap.put(originalOrder.orders__Deliveries__r[i].Id, clonedDeliveries[i].Id);
            }

            for (orders__Delivery__c originalDelivery : originalOrder.orders__Deliveries__r) {
                for (orders__DeliveryLineItem__c originalLineItem : originalDelivery.orders__DeliveryLineItems__r) {
                    orders__DeliveryLineItem__c clonedLineItem = originalLineItem.clone(false, true, false, false);
                    clonedLineItem.orders__DeliveryId__c = deliveryIdMap.get(originalDelivery.Id);

                    if (originalLineItem.orders__OrderLineItemId__c != null) {
                        clonedLineItem.orders__OrderLineItemId__c = orderLineItemIdMap.get(originalLineItem.orders__OrderLineItemId__c);
                    }

                    clonedDeliveryLineItems.add(clonedLineItem);
                }
            }

            if (!clonedDeliveryLineItems.isEmpty()) {
                try {
                    insert clonedDeliveryLineItems;
                } catch (DmlException e) {
                    System.debug('Error inserting cloned DeliveryLineItems: ' + e.getMessage());
                    throw e;
                }
            }
        }
    }

    private Id getLastOrderForAccount() {
        if (accountId == null) {
            return null;
        }

        // Query for the last draft order for the given account
        orders__Order__c lastDraftOrder = [
            SELECT Id
            FROM orders__Order__c
            WHERE orders__AccountId__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return lastDraftOrder != null ? lastDraftOrder.Id : null;
    }
}
