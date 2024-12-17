public with sharing class OrderCloneUtility {

    private Id orderId;
    private Id newAccountId;

    private Boolean isDeliveriesToBeCloned = true;
    private Boolean isDeliveryDatesToBeShifted = true;
    private Boolean isQtysToBeCloned = true;

    private List<Id> promotionsToAdd = new List<Id>();
    private Map<Id, Id> productsToRepalce = new Map<Id, Id>();

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

        orders__Order__c originalOrder = [
            SELECT Id, orders__OrderType__c, orders__Stage__c, orders__SalesOrganizationId__c,
                   orders__AccountId__c, orders__PriceBookId__c, CreatedDate,
                   (SELECT Id, orders__CatalogId__c, orders__PromotionId__c, orders__Quantity__c,
                           orders__Product2Id__c
                    FROM orders__OrderLineItems__r),
                   (SELECT Id, Name, orders__DeliveryDate__c,
                           (SELECT Id, orders__Quantity__c, orders__Product2Id__c, orders__OrderLineItemId__c
                            FROM orders__DeliveryLineItems__r)
                    FROM orders__Deliveries__r)
            FROM orders__Order__c
            WHERE Id = :sourceOrderId
            LIMIT 1
        ];

        if (!Schema.sObjectType.orders__Order__c.isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create Order records.');
        }

        orders__Order__c clonedOrder = originalOrder.clone(false, true, false, false);
        if (newAccountId != null) {
            clonedOrder.orders__AccountId__c = newAccountId;
        }

        clonedOrder.orders__Stage__c = 'OnHold';

        try {
            insert clonedOrder;
        } catch (DmlException e) {
            throw new Metadata.NoAccessException('Error inserting cloned Order: ' + e.getMessage());
        }

        Map<Id, Id> orderLineItemIdMap = cloneOrderLineItems(originalOrder.orders__OrderLineItems__r, clonedOrder.Id);

        if (isDeliveriesToBeCloned) {
            cloneDeliveries(originalOrder, clonedOrder, orderLineItemIdMap);
        }

        return clonedOrder.Id;
    }

    private Map<Id, Id> cloneOrderLineItems(List<orders__OrderLineItem__c> originalOrderLineItems, Id clonedOrderId) {
        if (!Schema.sObjectType.orders__OrderLineItem__c.isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create OrderLineItem records.');
        }

        Map<Id, Id> orderLineItemIdMap = new Map<Id, Id>();
        if (originalOrderLineItems != null && !originalOrderLineItems.isEmpty()) {
            List<orders__OrderLineItem__c> clonedOrderLineItems = new List<orders__OrderLineItem__c>();
            for (orders__OrderLineItem__c oli : originalOrderLineItems) {
                orders__OrderLineItem__c clonedOli = oli.clone(false, true, false, false);
                clonedOli.orders__OrderId__c = clonedOrderId;

                if (!isQtysToBeCloned) {
                    clonedOli.orders__Quantity__c = 0; // Reset quantity if not cloning.
                }
                clonedOrderLineItems.add(clonedOli);
            }

            insert clonedOrderLineItems;
            for (Integer i = 0; i < originalOrderLineItems.size(); i++) {
                orderLineItemIdMap.put(originalOrderLineItems[i].Id, clonedOrderLineItems[i].Id);
            }
        }
        return orderLineItemIdMap;
    }

    private void cloneDeliveries(orders__Order__c originalOrder, orders__Order__c clonedOrder, Map<Id, Id> orderLineItemIdMap) {
        if (!Schema.sObjectType.orders__Delivery__c.isCreateable() || !Schema.sObjectType.orders__DeliveryLineItem__c.isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create Delivery or DeliveryLineItem records.');
        }

        List<orders__Delivery__c> clonedDeliveries = new List<orders__Delivery__c>();
        List<orders__DeliveryLineItem__c> clonedDeliveryLineItems = new List<orders__DeliveryLineItem__c>();
        Map<Id, Id> deliveryIdMap = new Map<Id, Id>();

        if (originalOrder.orders__Deliveries__r != null && !originalOrder.orders__Deliveries__r.isEmpty()) {
            Date newBaseDate = clonedOrder.CreatedDate != null ? clonedOrder.CreatedDate.date() : Date.today();
            Date previousOriginalDate = null;
            Date previousNewDate = newBaseDate;

            // Clone deliveries
            for (orders__Delivery__c originalDelivery : originalOrder.orders__Deliveries__r) {
                orders__Delivery__c clonedDelivery = originalDelivery.clone(false, true, false, false);
                clonedDelivery.orders__OrderId__c = clonedOrder.Id;

                if (newAccountId != null) {
                    clonedDelivery.orders__AccountId__c = newAccountId;
                }

                // Shift delivery dates based on intervals from original deliveries
                if (isDeliveryDatesToBeShifted) {
                    if (previousOriginalDate == null) {
                        clonedDelivery.orders__DeliveryDate__c = newBaseDate;
                    } else {
                        Integer interval = originalDelivery.orders__DeliveryDate__c.daysBetween(previousOriginalDate);
                        previousNewDate = previousNewDate.addDays(interval);
                        clonedDelivery.orders__DeliveryDate__c = previousNewDate;
                    }
                }

                clonedDeliveries.add(clonedDelivery);
                previousOriginalDate = originalDelivery.orders__DeliveryDate__c;
            }

            insert clonedDeliveries;

            for (Integer i = 0; i < originalOrder.orders__Deliveries__r.size(); i++) {
                deliveryIdMap.put(originalOrder.orders__Deliveries__r[i].Id, clonedDeliveries[i].Id);
            }

            // Clone delivery line items
            if (isQtysToBeCloned) {
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
                    insert clonedDeliveryLineItems;
                }
            }
        }
    }
}