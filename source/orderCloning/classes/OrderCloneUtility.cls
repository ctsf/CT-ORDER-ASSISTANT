public with sharing class OrderCloneUtility {

    private Id orderId;
    private orders__Order__c originalOrder;
    private Id newAccountId;

    private Boolean isDeliveriesToBeCloned = true;
    private Boolean isDeliveryDatesToBeShifted = true;
    private Boolean isQtysToBeCloned = true;

    private List<Id> promotionsToAdd = new List<Id>();
    private Map<Id, Id> productsToReplace = new Map<Id, Id>();

    public OrderCloneUtility setOrderId(Id orderId) {
        this.orderId = orderId;
        return this;
    }

    public OrderCloneUtility setNewAccountId(Id newAccountId) {
        this.newAccountId = newAccountId;
        return this;
    }

    public OrderCloneUtility setIsDeliveriesToBeCloned(Boolean isDeliveriesToBeCloned) {
        this.isDeliveriesToBeCloned = isDeliveriesToBeCloned != null ? isDeliveriesToBeCloned : false;
        return this;
    }

    public OrderCloneUtility setIsDeliveryDatesToBeShifted(Boolean isDeliveryDatesToBeShifted) {
        this.isDeliveryDatesToBeShifted = isDeliveryDatesToBeShifted != null ? isDeliveryDatesToBeShifted : false;
        return this;
    }

    public OrderCloneUtility setIsQtysToBeCloned(Boolean isQtysToBeCloned) {
        this.isQtysToBeCloned = isQtysToBeCloned != null ? isQtysToBeCloned : true;
        return this;
    }

    public Id cloneOrder() {
        if (!Schema.sObjectType.orders__Order__c.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }

        Id sourceOrderId = orderId;

        if (sourceOrderId == null) {
            throw new IllegalArgumentException('No valid orderId or accountId provided for cloning.');
        }

        this.originalOrder = [
            SELECT Id, orders__OrderType__c, orders__Stage__c, orders__SalesOrganizationId__c,
                   orders__AccountId__c, orders__PriceBookId__c, CreatedDate
            FROM orders__Order__c
            WHERE Id = :sourceOrderId
            WITH USER_MODE
            LIMIT 1
        ];

        if (!Schema.sObjectType.orders__Order__c.isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create Order records.');
        }

        orders__Order__c clonedOrder = new orders__Order__c();
        clonedOrder.orders__OrderType__c = this.originalOrder.orders__OrderType__c;
        clonedOrder.orders__SalesOrganizationId__c = this.originalOrder.orders__SalesOrganizationId__c;
        clonedOrder.orders__AccountId__c = newAccountId != null ? newAccountId : originalOrder.orders__AccountId__c;
        clonedOrder.orders__PriceBookId__c = this.originalOrder.orders__PriceBookId__c;
        clonedOrder.orders__Stage__c = 'OnHold';

        try {
            insert as user clonedOrder ;
        } catch (DmlException e) {
            throw new Metadata.NoAccessException('Error inserting cloned Order: ' + e.getMessage());
        }

        // TODO: set product field dynamically
        List<orders__OrderLineItem__c> originalOrderLineItems = [
            SELECT Id, orders__CatalogLineItemId__c, orders__PromotionLineItemId__c,
            orders__CatalogId__c, orders__PromotionId__c, orders__Quantity__c, orders__Product2Id__c,
            orders__PriceBookId__c, orders__PriceBookLineItemId__c
            FROM orders__OrderLineItem__c
            WHERE orders__OrderId__c = :sourceOrderId
            WITH USER_MODE
        ];

        Map<Id, Id> orderLineItemIdMap = cloneOrderLineItems(originalOrderLineItems, clonedOrder.Id);

        if (isDeliveriesToBeCloned) {
            List<orders__Delivery__c> originalDeliveries = [
                SELECT Id, orders__DeliveryDate__c, orders__AccountId__c,
                       (SELECT Id, orders__Quantity__c, orders__Product2Id__c, orders__OrderLineItemId__c
                        FROM orders__DeliveryLineItems__r)
                FROM orders__Delivery__c
                WHERE orders__OrderId__c = :sourceOrderId
                WITH USER_MODE
            ];

            cloneDeliveries(originalDeliveries, clonedOrder.Id, orderLineItemIdMap);
        }

        return clonedOrder.Id;
    }

    private Map<Id, Id> cloneOrderLineItems(List<orders__OrderLineItem__c> originalOrderLineItems, Id clonedOrderId) {
        if (!Schema.sObjectType.orders__OrderLineItem__c.isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create OrderLineItem records.');
        }

        Map<Id, Id> orderLineItemIdMap = new Map<Id, Id>();
        List<orders__OrderLineItem__c> clonedOrderLineItems = new List<orders__OrderLineItem__c>();

        for (orders__OrderLineItem__c oli : originalOrderLineItems) {
            orders__OrderLineItem__c clonedOli = new orders__OrderLineItem__c();
            clonedOli.orders__OrderId__c = clonedOrderId;
            clonedOli.orders__PriceBookId__c = oli.orders__PriceBookId__c;
            clonedOli.orders__PriceBookLineItemId__c = oli.orders__PriceBookLineItemId__c;
            clonedOli.orders__CatalogId__c = oli.orders__CatalogId__c;
            clonedOli.orders__CatalogLineItemId__c = oli.orders__CatalogLineItemId__c;
            clonedOli.orders__PromotionId__c = oli.orders__PromotionId__c;
            clonedOli.orders__PromotionLineItemId__c = oli.orders__PromotionLineItemId__c;
            clonedOli.orders__Product2Id__c = oli.orders__Product2Id__c;
            clonedOli.orders__Quantity__c = isQtysToBeCloned ? oli.orders__Quantity__c : 0;
            clonedOrderLineItems.add(clonedOli);
        }

        if (!clonedOrderLineItems.isEmpty()) {
            insert as user clonedOrderLineItems;
            for (Integer i = 0; i < originalOrderLineItems.size(); i++) {
                orderLineItemIdMap.put(originalOrderLineItems[i].Id, clonedOrderLineItems[i].Id);
            }
        }

        return orderLineItemIdMap;
    }

    private void cloneDeliveries(List<orders__Delivery__c> originalDeliveries, Id clonedOrderId, Map<Id, Id> orderLineItemIdMap) {
        if (!Schema.sObjectType.orders__Delivery__c.isCreateable() || !Schema.sObjectType.orders__DeliveryLineItem__c.isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create Delivery or DeliveryLineItem records.');
        }
    
        List<orders__Delivery__c> clonedDeliveries = new List<orders__Delivery__c>();
        Map<Id, Id> deliveryIdMap = new Map<Id, Id>();
        List<orders__DeliveryLineItem__c> clonedDeliveryLineItems = new List<orders__DeliveryLineItem__c>();
    
        Date today = Date.today();
        Date earliestPastDate = null;
        Integer firstShiftDays = 0;
        
        for (orders__Delivery__c delivery : originalDeliveries) {
            if (delivery.orders__DeliveryDate__c < today) {
                if (earliestPastDate == null || delivery.orders__DeliveryDate__c < earliestPastDate) {
                    earliestPastDate = delivery.orders__DeliveryDate__c;
                }
            }
        }
    
        if (earliestPastDate != null) {
            firstShiftDays = today.daysBetween(earliestPastDate);
        }
    
        for (orders__Delivery__c originalDelivery : originalDeliveries) {
            orders__Delivery__c clonedDelivery = new orders__Delivery__c();
            clonedDelivery.orders__OrderId__c = clonedOrderId;
            clonedDelivery.orders__AccountId__c = newAccountId != null ? newAccountId : this.originalOrder.orders__AccountId__c;
            
            // Adjust delivery date logic
            if (isDeliveryDatesToBeShifted) {
                if (originalDelivery.orders__DeliveryDate__c >= today) {
                    // Keep future or today dates unchanged
                    clonedDelivery.orders__DeliveryDate__c = originalDelivery.orders__DeliveryDate__c;
                } else {
                    // Shift past dates forward
                    Integer shiftDays = originalDelivery.orders__DeliveryDate__c.daysBetween(earliestPastDate);
                    clonedDelivery.orders__DeliveryDate__c = today.addDays(shiftDays);
                }
            } else {
                clonedDelivery.orders__DeliveryDate__c = originalDelivery.orders__DeliveryDate__c;
            }
    
            clonedDeliveries.add(clonedDelivery);
        }
    
        if (!clonedDeliveries.isEmpty()) {
            insert clonedDeliveries;
            for (Integer i = 0; i < originalDeliveries.size(); i++) {
                deliveryIdMap.put(originalDeliveries[i].Id, clonedDeliveries[i].Id);
            }
        }
    
        // Clone delivery line items
        if (isQtysToBeCloned) {
            for (orders__Delivery__c originalDelivery : originalDeliveries) {
                if (originalDelivery.orders__DeliveryLineItems__r != null) {
                    for (orders__DeliveryLineItem__c originalLineItem : originalDelivery.orders__DeliveryLineItems__r) {
                        orders__DeliveryLineItem__c clonedLineItem = new orders__DeliveryLineItem__c();
                        clonedLineItem.orders__DeliveryId__c = deliveryIdMap.get(originalDelivery.Id);
                        clonedLineItem.orders__Quantity__c = originalLineItem.orders__Quantity__c;
                        clonedLineItem.orders__Product2Id__c = originalLineItem.orders__Product2Id__c;
                        if (orderLineItemIdMap.containsKey(originalLineItem.orders__OrderLineItemId__c)) {
                            clonedLineItem.orders__OrderLineItemId__c = orderLineItemIdMap.get(originalLineItem.orders__OrderLineItemId__c);
                        }
                        clonedDeliveryLineItems.add(clonedLineItem);
                    }
                }
            }
    
            if (!clonedDeliveryLineItems.isEmpty()) {
                insert clonedDeliveryLineItems;
            }
        }
    }
}