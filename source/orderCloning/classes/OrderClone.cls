public with sharing class OrderClone {

    @InvocableMethod(label='Clone Order' description='Clones an order and its related records.')
    public static List<CloneOrderResponse> cloneOrders(List<CloneOrderRequest> requests) {
        List<CloneOrderResponse> responses = new List<CloneOrderResponse>();

        for (CloneOrderRequest request : requests) {
            CloneOrderResponse response = new CloneOrderResponse();

            try {
                if (String.isBlank(request.orderId)) {
                    response.status = 'ERROR';
                    response.message = 'Order ID must be provided.';
                    responses.add(response);
                    continue;
                }

                OrderClone util = new OrderClone()
                    .setOrderId(request.orderId)
                    .setNewAccountId(request.newAccountId)
                    .setIsDeliveriesToBeCloned(request.cloneDeliveries)
                    .setIsDeliveryDatesToBeShifted(request.shiftDeliveryDates)
                    .setIsQtysToBeCloned(request.cloneQuantities);

                Id clonedOrderId = util.cloneOrder();

                if (clonedOrderId == null) {
                    response.status = 'ERROR';
                    response.message = 'Order cloning failed.';
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Order cloned successfully.';
                    response.clonedOrderId = clonedOrderId;
                    response.clonedOrderLink = '<a href="/' + clonedOrderId + '" target="_blank">View Cloned Order</a>';
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }

    public class CloneOrderRequest {
        @InvocableVariable(required=false label='Order ID' description='The ID of the order to clone.')
        public Id orderId;

        @InvocableVariable(required=false label='New Account ID' description='The new Account ID to replace in the cloned order.')
        public Id newAccountId;

        @InvocableVariable(required=true label='Clone Deliveries' description='Whether to clone the deliveries associated with the order.')
        public Boolean cloneDeliveries;

        @InvocableVariable(required=false label='Shift Delivery Dates' description='Whether to shift delivery dates based on the original intervals.')
        public Boolean shiftDeliveryDates;

        @InvocableVariable(required=false label='Clone Quantities' description='Whether to clone the quantities in the order.')
        public Boolean cloneQuantities;
    }

    public class CloneOrderResponse {
        @InvocableVariable(label='Status' description='The status of the cloning operation.')
        public String status;

        @InvocableVariable(label='Message' description='Details about the cloning operation.')
        public String message;

        @InvocableVariable(label='Cloned Order ID' description='The ID of the cloned order.')
        public String clonedOrderId;

        @InvocableVariable(label='Cloned Order Link' description='A hyperlink to view the cloned order in Salesforce.')
        public String clonedOrderLink;
    }

    private Id orderId;
    private Id newAccountId;

    private Boolean isDeliveriesToBeCloned = true;
    private Boolean isDeliveryDatesToBeShifted = true;
    private Boolean isQtysToBeCloned = true;

    public OrderClone setOrderId(Id orderId) {
        this.orderId = orderId;
        return this;
    }

    public OrderClone setNewAccountId(Id newAccountId) {
        this.newAccountId = newAccountId;
        return this;
    }

    public OrderClone setIsDeliveriesToBeCloned(Boolean isDeliveriesToBeCloned) {
        this.isDeliveriesToBeCloned = isDeliveriesToBeCloned != null ? isDeliveriesToBeCloned : false;
        return this;
    }

    public OrderClone setIsDeliveryDatesToBeShifted(Boolean isDeliveryDatesToBeShifted) {
        this.isDeliveryDatesToBeShifted = isDeliveryDatesToBeShifted != null ? isDeliveryDatesToBeShifted : false;
        return this;
    }

    public OrderClone setIsQtysToBeCloned(Boolean isQtysToBeCloned) {
        this.isQtysToBeCloned = isQtysToBeCloned != null ? isQtysToBeCloned : true;
        return this;
    }

    public Id cloneOrder() {
        String orderObjectName = 'orders__Order__c';

        Schema.DescribeSObjectResult orderDescribe = Metadata.getDescribe(orderObjectName);

        if (!orderDescribe.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }

        Id sourceOrderId = orderId;

        if (sourceOrderId == null) {
            throw new IllegalArgumentException('No valid orderId or accountId provided for cloning.');
        }

        List<SObject> orderResults = Database.query('SELECT Id, orders__OrderType__c, orders__Stage__c, orders__SalesOrganizationId__c, ' +
            'orders__AccountId__c, orders__PriceBookId__c, CreatedDate, ' +
            '(SELECT Id, orders__CatalogId__c, orders__PromotionId__c, orders__Quantity__c, orders__Product2Id__c FROM orders__OrderLineItems__r), ' +
            '(SELECT Id, Name, orders__DeliveryDate__c, ' +
            '(SELECT Id, orders__Quantity__c, orders__Product2Id__c, orders__OrderLineItemId__c FROM orders__DeliveryLineItems__r) FROM orders__Deliveries__r) ' +
            'FROM orders__Order__c WHERE Id = :sourceOrderId LIMIT 1');

        if (orderResults.isEmpty()) {
            throw new IllegalArgumentException('No Order found for the provided Id.');
        }

        SObject originalOrder = orderResults[0];

        if (!orderDescribe.isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create Order records.');
        }

        SObject clonedOrder = originalOrder.clone(false, true, false, false);
        clonedOrder.put('orders__AccountId__c', newAccountId != null ? newAccountId : clonedOrder.get('orders__AccountId__c'));
        clonedOrder.put('orders__Stage__c', 'OnHold');

        try {
            insert clonedOrder;
        } catch (DmlException e) {
            throw new Metadata.NoAccessException('Error inserting cloned Order: ' + e.getMessage());
        }

        Map<Id, Id> orderLineItemIdMap = cloneOrderLineItems((List<SObject>)originalOrder.getSObjects('orders__OrderLineItems__r'), (Id)clonedOrder.get('Id'));

        if (isDeliveriesToBeCloned) {
            cloneDeliveries(originalOrder, clonedOrder, orderLineItemIdMap);
        }

        return (Id)clonedOrder.get('Id');
    }

    private Map<Id, Id> cloneOrderLineItems(List<SObject> originalOrderLineItems, Id clonedOrderId) {
        String orderLineItemObjectName = 'orders__OrderLineItem__c';

        if (!Metadata.getDescribe(orderLineItemObjectName).isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create OrderLineItem records.');
        }

        Map<Id, Id> orderLineItemIdMap = new Map<Id, Id>();
        if (originalOrderLineItems != null && !originalOrderLineItems.isEmpty()) {
            List<SObject> clonedOrderLineItems = new List<SObject>();
            for (SObject oli : originalOrderLineItems) {
                SObject clonedOli = oli.clone(false, true, false, false);
                clonedOli.put('orders__OrderId__c', clonedOrderId);

                if (!isQtysToBeCloned) {
                    clonedOli.put('orders__Quantity__c', 0);
                }
                clonedOrderLineItems.add(clonedOli);
            }

            insert clonedOrderLineItems;
            for (Integer i = 0; i < originalOrderLineItems.size(); i++) {
                orderLineItemIdMap.put((Id)originalOrderLineItems[i].get('Id'), (Id)clonedOrderLineItems[i].get('Id'));
            }
        }
        return orderLineItemIdMap;
    }

    private void cloneDeliveries(SObject originalOrder, SObject clonedOrder, Map<Id, Id> orderLineItemIdMap) {
        String deliveryObjectName = 'orders__Delivery__c';
        String deliveryLineItemObjectName = 'orders__DeliveryLineItem__c';

        if (!Metadata.getDescribe(deliveryObjectName).isCreateable() || !Metadata.getDescribe(deliveryLineItemObjectName).isCreateable()) {
            throw new Metadata.NoAccessException('Insufficient permissions to create Delivery or DeliveryLineItem records.');
        }

        List<SObject> clonedDeliveries = new List<SObject>();
        List<SObject> clonedDeliveryLineItems = new List<SObject>();
        Map<Id, Id> deliveryIdMap = new Map<Id, Id>();

        List<SObject> originalDeliveries = (List<SObject>)originalOrder.getSObjects('orders__Deliveries__r');

        if (originalDeliveries != null && !originalDeliveries.isEmpty()) {
            Date newBaseDate = (Date)clonedOrder.get('CreatedDate') != null ? ((DateTime)clonedOrder.get('CreatedDate')).date() : Date.today();
            Date previousOriginalDate = null;
            Date previousNewDate = newBaseDate;

            for (SObject originalDelivery : originalDeliveries) {
                SObject clonedDelivery = originalDelivery.clone(false, true, false, false);
                clonedDelivery.put('orders__OrderId__c', clonedOrder.get('Id'));

                if (isDeliveryDatesToBeShifted) {
                    if (previousOriginalDate == null) {
                        clonedDelivery.put('orders__DeliveryDate__c', newBaseDate);
                    } else {
                        Integer interval = ((Date)originalDelivery.get('orders__DeliveryDate__c')).daysBetween(previousOriginalDate);
                        previousNewDate = previousNewDate.addDays(interval);
                        clonedDelivery.put('orders__DeliveryDate__c', previousNewDate);
                    }
                }

                clonedDeliveries.add(clonedDelivery);
                previousOriginalDate = (Date)originalDelivery.get('orders__DeliveryDate__c');
            }

            insert clonedDeliveries;

            for (Integer i = 0; i < originalDeliveries.size(); i++) {
                deliveryIdMap.put((Id)originalDeliveries[i].get('Id'), (Id)clonedDeliveries[i].get('Id'));
            }

            for (SObject originalDelivery : originalDeliveries) {
                List<SObject> originalLineItems = (List<SObject>)originalDelivery.getSObjects('orders__DeliveryLineItems__r');
                if (originalLineItems != null && !originalLineItems.isEmpty()) {
                    for (SObject originalLineItem : originalLineItems) {
                        SObject clonedLineItem = originalLineItem.clone(false, true, false, false);
                        clonedLineItem.put('orders__DeliveryId__c', deliveryIdMap.get((Id)originalDelivery.get('Id')));

                        if (originalLineItem.get('orders__OrderLineItemId__c') != null) {
                            clonedLineItem.put('orders__OrderLineItemId__c', orderLineItemIdMap.get((Id)originalLineItem.get('orders__OrderLineItemId__c')));
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
