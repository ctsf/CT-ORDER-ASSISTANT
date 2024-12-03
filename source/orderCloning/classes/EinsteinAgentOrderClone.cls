public with sharing class EinsteinAgentOrderClone {
    // Would you like to have quantities for products in your Order? 
    // Would you like to have unavailable products replaced with the best alternative? 
    // Would you like to add recommended products? 
    // Would you like to recommend quantities to reach the next discount threshold? 
    // Would you like to include promo-products?
    @InvocableMethod(label='Clone Order' description='Clones an order and its related records.')
    public static List<CloneOrderResponse> cloneOrders(List<CloneOrderRequest> requests) {
        List<CloneOrderResponse> responses = new List<CloneOrderResponse>();

        for (CloneOrderRequest request : requests) {
            CloneOrderResponse response = new CloneOrderResponse();

            try {
                if (String.isBlank(request.orderId) && String.isBlank(request.accountId)) {
                    response.status = 'ERROR';
                    response.message = 'Either Order ID or Account ID must be provided.';
                    responses.add(response);
                    continue;
                }

                OrderCloneUtility util = new OrderCloneUtility(
                    String.isNotBlank(request.orderId) ? request.orderId : null,
                    String.isNotBlank(request.newAccountId) ? request.newAccountId : null,
                    request.cloneDeliveries,
                    String.isNotBlank(request.accountId) ? request.accountId : null
                );

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
        public String orderId;

        @InvocableVariable(required=false label='Account ID' description='The Account ID to use if Order ID is not provided.')
        public String accountId;

        @InvocableVariable(required=false label='New Account ID' description='The new Account ID to replace in the cloned order.')
        public String newAccountId;

        @InvocableVariable(required=true label='Clone Deliveries' description='Whether to clone the deliveries associated with the order.')
        public Boolean cloneDeliveries;
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
}
