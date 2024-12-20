public class OrderStatusUpdater {
    @InvocableMethod(label='Update Order Status' description='Updates the status of multiple Orders')
    public static void updateOrderStatus(List<OrderStatusRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        List<Order> ordersToUpdate = new List<Order>();

        for (OrderStatusRequest request : requests) {
            if (request.OrderId == null) {
                throw new IllegalArgumentException('OrderId is required.');
            }
            if (String.isEmpty(request.Status)) {
                throw new IllegalArgumentException('Status is required.');
            }

            if (!Schema.sObjectType.Order.isUpdateable()) {
                throw new Metadata.NoAccessException('You do not have permission to update Orders.');
            }

            Order ord = new Order(Id = request.OrderId);
            if (Schema.sObjectType.Order.fields.Status.isUpdateable()) {
                ord.Status = request.Status;
            } else {
                throw new Metadata.NoAccessException('You do not have permission to update the Status field.');
            }
            ordersToUpdate.add(ord);
        }

        try {
            update ordersToUpdate;
        } catch (Exception e) {
            System.debug('Error updating orders: ' + e.getMessage());
            throw e;
        }
    }

    public class OrderStatusRequest {
        @InvocableVariable(required=true description='ID of the Order to update')
        public Id OrderId;

        @InvocableVariable(required=true description='New status for the Order')
        public String Status;
    }
}