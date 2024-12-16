public with sharing class OrderCloneUtility {

    private Id orderId;
    private Id newAccountId;

    private Boolean isDeliveriesToBeCloned = true;
    private Boolean isDeliveryDatesToBeShifted = true;
    private Boolean isQtysToBeCloned = true;

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
        Id sourceOrderId = orderId;
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
                    CreatedDate,
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

        orders__Order__c clonedOrder = originalOrder.clone(false, true, false, false);
        if (newAccountId != null) {
            clonedOrder.orders__AccountId__c = newAccountId;
        }

        clonedOrder.orders__Stage__c = 'OnHold';

        try {
            insert clonedOrder;
        } catch (DmlException e) {
            System.debug('Error inserting cloned Order: ' + e.getMessage());
            throw e;
        }

        // Clone order line items
        Map<Id, Id> orderLineItemIdMap = cloneOrderLineItems(originalOrder.orders__OrderLineItems__r, clonedOrder.Id);

        // Conditionally clone deliveries
        if (isDeliveriesToBeCloned) {
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

                if (!isQtysToBeCloned) {
                    clonedOli.orders__Quantity__c = 0; // Reset quantity if not cloning.
                }

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
    
        if (originalOrder.orders__Deliveries__r != null && !originalOrder.orders__Deliveries__r.isEmpty()) {
            // Sort original deliveries by DeliveryDate
            List<orders__Delivery__c> sortedDeliveries = originalOrder.orders__Deliveries__r;
            sortedDeliveries.sort();
    
            Date newBaseDate = originalOrder.CreatedDate.date(); // Convert Datetime to Date
            Date previousOriginalDate = null; // To calculate intervals
    
            for (orders__Delivery__c originalDelivery : sortedDeliveries) {
                orders__Delivery__c clonedDelivery = originalDelivery.clone(false, true, false, false);
                clonedDelivery.orders__OrderId__c = clonedOrderId;
    
                if (newAccountId != null) {
                    clonedDelivery.orders__AccountId__c = newAccountId;
                }
    
                if (isDeliveryDatesToBeShifted) {
                    if (previousOriginalDate == null) {
                        // First delivery: interval is calculated from the order's CreatedDate
                        Integer interval = originalDelivery.orders__DeliveryDate__c.daysBetween(newBaseDate);
                        clonedDelivery.orders__DeliveryDate__c = newBaseDate.addDays(interval);
                    } else {
                        // Subsequent deliveries: calculate interval from the previous delivery
                        Integer interval = originalDelivery.orders__DeliveryDate__c.daysBetween(previousOriginalDate);
                        clonedDelivery.orders__DeliveryDate__c = previousOriginalDate.addDays(interval);
                    }
                }
    
                clonedDeliveries.add(clonedDelivery);
                previousOriginalDate = originalDelivery.orders__DeliveryDate__c; // Update for the next interval calculation
            }
    
            try {
                insert clonedDeliveries;
            } catch (DmlException e) {
                System.debug('Error inserting cloned Deliveries: ' + e.getMessage());
                throw e;
            }
    
            for (Integer i = 0; i < sortedDeliveries.size(); i++) {
                deliveryIdMap.put(sortedDeliveries[i].Id, clonedDeliveries[i].Id);
            }
    
            if (isQtysToBeCloned) {
                for (orders__Delivery__c originalDelivery : sortedDeliveries) {
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
    }
}
