public with sharing class OrderItemQuantityUpdater {

    @InvocableMethod(label='Update OrderItem Quantity' description='Updates the quantity of order items, ensuring the order is not finalized')
    public static void updateQuantities(List<UpdateRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        if (!Schema.sObjectType.OrderItem.isAccessible() ||
            !Schema.sObjectType.OrderItem.fields.Quantity.isUpdateable()) {
            throw new Metadata.NoAccessException('You do not have permission to update Quantity on OrderItem.');
        }

        if (!Schema.sObjectType.Order.isAccessible() ||
            !Schema.sObjectType.Order.fields.Status.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Order fields.');
        }

        Set<Id> orderItemIds = new Set<Id>();
        for (UpdateRequest req : requests) {
            if (req.OrderItemId == null) {
                throw new IllegalArgumentException('OrderItemId is required.');
            }
            if (req.NewQuantity == null || req.NewQuantity <= 0) {
                throw new IllegalArgumentException('NewQuantity must be greater than 0.');
            }
            orderItemIds.add(req.OrderItemId);
        }

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>([
            SELECT Id, Quantity, Order.Status, OrderId
            FROM OrderItem
            WHERE Id IN :orderItemIds
        ]);

        if (orderItemsMap.size() != orderItemIds.size()) {
            throw new IllegalArgumentException('Some OrderItems not found.');
        }

        List<OrderItem> itemsToUpdate = new List<OrderItem>();
        for (UpdateRequest req : requests) {
            OrderItem oi = orderItemsMap.get(req.OrderItemId);

            if (oi.Order.Status == 'Activated' || oi.Order.Status == 'Completed') {
                throw new IllegalArgumentException('Cannot update quantity because the order is finalized: ' + oi.OrderId);
            }
            oi.Quantity = req.NewQuantity;
            itemsToUpdate.add(oi);
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
    }

    public class UpdateRequest {
        @InvocableVariable(required=true description='ID of the OrderItem to update')
        public Id OrderItemId;

        @InvocableVariable(required=true description='New quantity for the OrderItem')
        public Decimal NewQuantity;
    }
}