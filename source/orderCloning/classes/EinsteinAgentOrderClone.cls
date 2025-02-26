global with sharing class EinsteinAgentOrderClone {
    @InvocableMethod(label='Clone Order' description='Clones an order and its related records.')
    global static List<CloneOrderResponse> cloneOrders(List<CloneOrderRequest> requests) {
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

    global class CloneOrderRequest {
        @InvocableVariable(required=false label='Order ID' description='The ID of the order to clone.')
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

        @InvocableVariable(label='Cloned Order ID' description='The ID of the cloned order.')
        global String clonedOrderId;

        @InvocableVariable(label='Cloned Order Link' description='A hyperlink to view the cloned order in Salesforce.')
        global String clonedOrderLink;
    }
}