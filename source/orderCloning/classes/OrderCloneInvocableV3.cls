global with sharing class OrderCloneInvocableV3 {
    @InvocableMethod(label='Clone Order V3' description='Clones an order and its related records and returns the cloned order object with enhanced friendly UX details.')
    global static List<CloneOrderResponse> cloneOrders(List<CloneOrderRequest> requests) {
        List<CloneOrderResponse> responses = new List<CloneOrderResponse>();

        for (CloneOrderRequest request : requests) {
            CloneOrderResponse response = new CloneOrderResponse();

            try {
                if (request.orderId == null) {
                    response.status = 'ERROR';
                    response.message = 'Order ID must be provided.';
                    response.friendlyUX = 'Please provide a valid Order ID to clone your order.';
                    responses.add(response);
                    continue;
                }

                OrderCloneUtility util = new OrderCloneUtility()
                    .setOrderId(request.orderId)
                    .setNewAccountId(request.newAccountId)
                    .setIsDeliveriesToBeCloned(request.cloneDeliveries)
                    .setIsDeliveryDatesToBeShifted(request.shiftDeliveryDates)
                    .setIsQtysToBeCloned(request.cloneQuantities);

                Id clonedOrderId = util.cloneOrder();

                if (clonedOrderId == null) {
                    response.status = 'ERROR';
                    response.message = 'Order cloning failed.';
                    response.friendlyUX = 'We encountered an issue while cloning your order. Please try again later or contact support if the problem persists.';
                } else {

                    orders__Order__c clonedOrder = [
                        SELECT Name,
                               orders__AccountId__r.Name,
                               orders__Stage__c,
                               CreatedDate
                        FROM orders__Order__c
                        WHERE Id = :clonedOrderId
                        LIMIT 1
                    ];

                    response.status = 'SUCCESS';
                    response.message = 'Order cloned successfully.';
                    response.clonedOrder = clonedOrder;

                    // Build a friendly UX message.
                    String orderName = clonedOrder.Name;
                    String accountName = (clonedOrder.orders__AccountId__r != null) ? clonedOrder.orders__AccountId__r.Name : 'N/A';
                    String stage = clonedOrder.orders__Stage__c;
                    String createdDate = String.valueOf(clonedOrder.CreatedDate);

                    response.friendlyUX = 'Order "' + orderName + '" for account "' + accountName + ' at stage "' + stage + 
                        '" was created on ' + createdDate + '.';
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
                response.friendlyUX = 'An unexpected error occurred while processing your order. Please contact support if this issue persists.';
            }

            responses.add(response);
        }

        return responses;
    }

    global class CloneOrderRequest {
        @InvocableVariable(required=true label='Order ID' description='The ID of the order to clone.')
        global Id orderId;

        @InvocableVariable(required=false label='New Account ID' description='The new Account ID to replace in the cloned order.')
        global Id newAccountId;

        @InvocableVariable(required=true label='Clone Deliveries' description='Whether to clone the deliveries associated with the order.')
        global Boolean cloneDeliveries;

        @InvocableVariable(required=false label='Shift Delivery Dates' description='Whether to shift delivery dates based on the original intervals.')
        global Boolean shiftDeliveryDates;

        @InvocableVariable(required=false label='Clone Quantities' description='Whether to clone the quantities in the order.')
        global Boolean cloneQuantities;
    }

    global class CloneOrderResponse {
        @InvocableVariable(label='Status' description='The status of the cloning operation.')
        global String status;

        @InvocableVariable(label='Message' description='Details about the cloning operation.')
        global String message;

        @InvocableVariable(label='Cloned Order' description='The cloned order object.')
        global orders__Order__c clonedOrder;

        @InvocableVariable(label='Friendly UX Message' description='A user-friendly summary of the cloned order details for display in chat.')
        global String friendlyUX;
    }
}