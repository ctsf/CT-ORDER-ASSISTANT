public with sharing class AvailableProductsFetcher {

    @InvocableMethod(label='List Available Products to Add' description='Returns a list of products (from the order pricebook) not yet added to the order')
    public static List<AvailableProductResponse> listAvailableProducts(List<OrderRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        OrderRequest req = requests[0];
        if (req.OrderId == null) {
            throw new IllegalArgumentException('OrderId is required.');
        }

        if (!Schema.sObjectType.Order.isAccessible() ||
            !Schema.sObjectType.Order.fields.Pricebook2Id.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Order fields.');
        }

        if (!Schema.sObjectType.PricebookEntry.isAccessible() ||
            !Schema.sObjectType.PricebookEntry.fields.Product2Id.isAccessible() ||
            !Schema.sObjectType.PricebookEntry.fields.UnitPrice.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required PricebookEntry fields.');
        }

        if (!Schema.sObjectType.Product2.isAccessible() ||
            !Schema.sObjectType.Product2.fields.Name.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access Product2 Name field.');
        }

        if (!Schema.sObjectType.OrderItem.isAccessible() ||
            !Schema.sObjectType.OrderItem.fields.PricebookEntryId.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access OrderItem fields.');
        }

        Order ord = [
            SELECT Pricebook2Id
            FROM Order
            WHERE Id = :req.OrderId
            LIMIT 1
        ];

        if (ord.Pricebook2Id == null) {
            return new List<AvailableProductResponse>();
        }

        List<PricebookEntry> pbes = [
            SELECT Id, Product2Id, UnitPrice, Product2.Name
            FROM PricebookEntry
            WHERE Pricebook2Id = :ord.Pricebook2Id
            AND IsActive = true
        ];

        List<OrderItem> orderItems = [
            SELECT Id, PricebookEntryId
            FROM OrderItem
            WHERE OrderId = :req.OrderId
        ];

        Set<Id> pbeIdsInOrder = new Set<Id>();
        for (OrderItem oi : orderItems) {
            pbeIdsInOrder.add(oi.PricebookEntryId);
        }

        List<AvailableProductResponse> responses = new List<AvailableProductResponse>();
        for (PricebookEntry pbe : pbes) {
            if (!pbeIdsInOrder.contains(pbe.Id)) {
                responses.add(new AvailableProductResponse(pbe.Id, pbe.Product2.Name, pbe.UnitPrice));
            }
        }

        return responses;
    }

    public class OrderRequest {
        @InvocableVariable(required=true description='ID of the Order')
        public Id OrderId;
    }

    public class AvailableProductResponse {
        @InvocableVariable(description='ID of the PricebookEntry')
        public Id PricebookEntryId;
        @InvocableVariable(description='Name of the Product')
        public String ProductName;
        @InvocableVariable(description='Unit price from the pricebook')
        public Decimal UnitPrice;

        public AvailableProductResponse(Id pbeId, String productName, Decimal unitPrice) {
            this.PricebookEntryId = pbeId;
            this.ProductName = productName;
            this.UnitPrice = unitPrice;
        }
    }
}