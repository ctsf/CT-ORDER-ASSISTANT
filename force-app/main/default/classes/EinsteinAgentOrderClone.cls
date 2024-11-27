public with sharing class EinsteinAgentOrderClone {

    @InvocableMethod(label='Clone Order' description='Clones an order and its related records.')
    public static List<CloneOrderResponse> cloneOrders(List<CloneOrderRequest> requests) {
        List<CloneOrderResponse> responses = new List<CloneOrderResponse>();

        for (CloneOrderRequest request : requests) {
            CloneOrderResponse response = new CloneOrderResponse();

            try {
                if (String.isBlank(request.orderId)) {
                    response.status = 'ERROR';
                    response.message = 'Order ID is required.';
                    responses.add(response);
                    continue;
                }

                OrderCloneUtility util = new OrderCloneUtility();
                Id clonedOrderId = util.cloneOrder(request.orderId);

                if (clonedOrderId == null) {
                    response.status = 'ERROR';
                    response.message = 'Order cloning failed.';
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Order cloned successfully.';
                    response.clonedOrderId = clonedOrderId;
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
        @InvocableVariable(required=true label='Order ID' description='The ID of the order to clone.')
        public String orderId;
    }

    public class CloneOrderResponse {
        @InvocableVariable(label='Status' description='The status of the cloning operation.')
        public String status;

        @InvocableVariable(label='Message' description='Details about the cloning operation.')
        public String message;

        @InvocableVariable(label='Cloned Order ID' description='The ID of the cloned order.')
        public String clonedOrderId;
    }
}
