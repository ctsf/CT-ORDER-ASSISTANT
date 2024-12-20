public with sharing class OrderProductAdding {
    @InvocableMethod(label='Add Product to Order' description='Adds a product to an order')
    public static void addProductToOrder(List<OrderProductRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        Set<Id> orderIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        for (OrderProductRequest request : requests) {
            if (request.OrderId == null) {
                throw new IllegalArgumentException('OrderId is required.');
            }
            if (request.Quantity == null || request.Quantity <= 0) {
                throw new IllegalArgumentException('Quantity must be greater than 0.');
            }

            orderIds.add(request.OrderId);
            productIds.add(request.ProductId);
        }

        if (!Schema.sObjectType.OrderItem.isCreateable()) {
            throw new Metadata.NoAccessException('You do not have permission to create Order Items.');
        }

        if (!Schema.sObjectType.Order.fields.Status.isAccessible() || !Schema.sObjectType.Order.fields.Pricebook2Id.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access Order fields.');
        }

        Map<Id, Order> orders = new Map<Id, Order>([
            SELECT Status, Pricebook2Id
            FROM Order
            WHERE Id IN :orderIds
        ]);

        if (!Schema.sObjectType.PricebookEntry.fields.UnitPrice.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access PricebookEntry fields.');
        }

        Map<Id, PricebookEntry> pricebookEntries = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, UnitPrice, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
        ]) {
            pricebookEntries.put(pbe.Product2Id, pbe);
        }

        List<OrderItem> orderItems = new List<OrderItem>();

        for (OrderProductRequest request : requests) {
            Order order = orders.get(request.OrderId);
            if (order == null) {
                throw new IllegalArgumentException('Order not found for Id: ' + request.OrderId);
            }

            if (order.Status == 'Activated' || order.Status == 'Completed') {
                throw new IllegalArgumentException('Cannot add products to a finalized order.');
            }

            PricebookEntry pricebookEntry = pricebookEntries.get(request.ProductId);
            if (pricebookEntry == null || pricebookEntry.Pricebook2Id != order.Pricebook2Id) {
                throw new IllegalArgumentException('No matching PricebookEntry found for the specified product in the orders pricebook.');
            }

            OrderItem orderItem = new OrderItem(
                OrderId = request.OrderId,
                PricebookEntryId = pricebookEntry.Id,
                Quantity = request.Quantity,
                UnitPrice = pricebookEntry.UnitPrice
            );

            orderItems.add(orderItem);
        }

        try {
            insert orderItems;
        } catch (Exception e) {
            System.debug('Error adding product to order: ' + e.getMessage());
            throw e;
        }
    }

    public class OrderProductRequest {
        @InvocableVariable(required=true description='ID of the Order to which the product will be added')
        public Id OrderId;

        @InvocableVariable(required=true description='ID of the Product to add')
        public Id ProductId;

        @InvocableVariable(required=true description='Quantity of the product to add')
        public Decimal Quantity;
    }  
}