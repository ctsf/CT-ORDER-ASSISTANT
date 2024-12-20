public with sharing class OrderProductAdder {

    @InvocableMethod(label='Add Products to Order by ProductId' description='Adds specified products to the order using the order pricebook')
    public static void addProducts(List<AddProductRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        if (!Schema.sObjectType.OrderItem.isCreateable() ||
            !Schema.sObjectType.OrderItem.fields.PricebookEntryId.isCreateable() ||
            !Schema.sObjectType.OrderItem.fields.Quantity.isCreateable() ||
            !Schema.sObjectType.OrderItem.fields.UnitPrice.isCreateable()) {
            throw new Metadata.NoAccessException('You do not have permission to create Order Items or access required fields.');
        }

        Set<Id> orderIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        for (AddProductRequest req : requests) {
            if (req.OrderId == null) {
                throw new IllegalArgumentException('OrderId is required.');
            }
            if (req.ProductId == null) {
                throw new IllegalArgumentException('ProductId is required.');
            }
            if (req.Quantity == null || req.Quantity <= 0) {
                throw new IllegalArgumentException('Quantity must be greater than 0.');
            }
            orderIds.add(req.OrderId);
            productIds.add(req.ProductId);
        }

        if (orderIds.size() != 1) {
            throw new IllegalArgumentException('All requests must be for the same Order.');
        }

        Id singleOrderId = orderIds.iterator().next();

        if (!Schema.sObjectType.Order.isAccessible() ||
            !Schema.sObjectType.Order.fields.Status.isAccessible() ||
            !Schema.sObjectType.Order.fields.Pricebook2Id.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Order fields.');
        }

        Order ord = [
            SELECT Id, Status, Pricebook2Id
            FROM Order
            WHERE Id = :singleOrderId
            LIMIT 1
        ];

        if (ord.Status == 'Activated' || ord.Status == 'Completed') {
            throw new IllegalArgumentException('Cannot add products because the order is finalized: ' + ord.Id);
        }

        if (ord.Pricebook2Id == null) {
            throw new IllegalArgumentException('Order does not have a Pricebook associated, cannot add products.');
        }

        if (!Schema.sObjectType.PricebookEntry.isAccessible() ||
            !Schema.sObjectType.PricebookEntry.fields.Product2Id.isAccessible() ||
            !Schema.sObjectType.PricebookEntry.fields.UnitPrice.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access PricebookEntry fields.');
        }

        Map<Id, PricebookEntry> productToPbe = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2Id IN :productIds AND Pricebook2Id = :ord.Pricebook2Id AND IsActive=true
        ]) {
            productToPbe.put(pbe.Product2Id, pbe);
        }

        List<OrderItem> newItems = new List<OrderItem>();
        for (AddProductRequest req : requests) {
            PricebookEntry pbe = productToPbe.get(req.ProductId);
            if (pbe == null) {
                throw new IllegalArgumentException('No active pricebook entry found for ProductId ' + req.ProductId + ' in order pricebook.');
            }

            OrderItem oi = new OrderItem(
                OrderId = req.OrderId,
                PricebookEntryId = pbe.Id,
                Quantity = req.Quantity,
                UnitPrice = pbe.UnitPrice
            );
            newItems.add(oi);
        }

        insert newItems;
    }

    public class AddProductRequest {
        @InvocableVariable(required=true description='ID of the Order to which products will be added')
        public Id OrderId;

        @InvocableVariable(required=true description='ID of the Product to add')
        public Id ProductId;

        @InvocableVariable(required=true description='Quantity of the product to add')
        public Decimal Quantity;
    }
}