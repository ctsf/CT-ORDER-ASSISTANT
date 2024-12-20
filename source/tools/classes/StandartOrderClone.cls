public with sharing class StandartOrderClone {

    @InvocableMethod(label='Clone Order with Products' description='Clones an order along with its associated products')
    public static List<Id> cloneOrderWithProducts(List<OrderCloneRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        List<Id> clonedOrderIds = new List<Id>();

        Set<Id> orderIds = new Set<Id>();
        for (OrderCloneRequest request : requests) {
            if (request.orderId == null) {
                throw new IllegalArgumentException('OrderId is required.');
            }
            orderIds.add(request.orderId);
        }

        if (!Schema.sObjectType.Order.isCreateable() || !Schema.sObjectType.Order.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access or create Orders.');
        }

        if (!Schema.sObjectType.OrderItem.isCreateable() || !Schema.sObjectType.OrderItem.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access or create Order Items.');
        }

        Map<Id, Order> originalOrders = new Map<Id, Order>([
            SELECT AccountId, Pricebook2Id, EffectiveDate, Status
            FROM Order
            WHERE Id IN :orderIds
        ]);

        Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
        for (OrderItem item : [
            SELECT OrderId, PricebookEntryId, Quantity, UnitPrice
            FROM OrderItem
            WHERE OrderId IN :orderIds
        ]) {
            if (!orderItemsMap.containsKey(item.OrderId)) {
                orderItemsMap.put(item.OrderId, new List<OrderItem>());
            }
            orderItemsMap.get(item.OrderId).add(item);
        }

        for (OrderCloneRequest request : requests) {
            Order originalOrder = originalOrders.get(request.orderId);
            if (originalOrder == null) {
                throw new IllegalArgumentException('No Order found for the given OrderId: ' + request.orderId);
            }

            String newStatus = 'Draft';

            Order clonedOrder = new Order(
                AccountId = originalOrder.AccountId,
                Pricebook2Id = originalOrder.Pricebook2Id,
                EffectiveDate = Date.today(),
                Status = newStatus
            );

            insert clonedOrder;
            clonedOrderIds.add(clonedOrder.Id);

            List<OrderItem> originalOrderItems = orderItemsMap.get(request.orderId);
            if (originalOrderItems != null && !originalOrderItems.isEmpty()) {
                List<OrderItem> clonedOrderItems = new List<OrderItem>();

                for (OrderItem item : originalOrderItems) {
                    OrderItem clonedItem = new OrderItem(
                        OrderId = clonedOrder.Id,
                        PricebookEntryId = item.PricebookEntryId,
                        Quantity = item.Quantity,
                        UnitPrice = item.UnitPrice
                    );
                    clonedOrderItems.add(clonedItem);
                }

                insert clonedOrderItems;
            }
        }

        return clonedOrderIds;
    }

    public class OrderCloneRequest {
        @InvocableVariable(required=true description='ID of the Order to be cloned')
        public Id orderId;
    }
}