public with sharing class OrderProductsFetcher {

    @InvocableMethod(label='Get Order Products' description='Returns order products (order items) for the specified orders')
    public static List<OrderProductResponse> getOrderProducts(List<OrderRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        if (!Schema.sObjectType.OrderItem.isAccessible() ||
            !Schema.sObjectType.OrderItem.fields.Product2Id.isAccessible() ||
            !Schema.sObjectType.OrderItem.fields.Quantity.isAccessible() ||
            !Schema.sObjectType.OrderItem.fields.UnitPrice.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required OrderItem fields.');
        }

        if (!Schema.sObjectType.Product2.isAccessible() ||
            !Schema.sObjectType.Product2.fields.Name.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access Product2 Name field.');
        }

        List<OrderProductResponse> allResponses = new List<OrderProductResponse>();

        for (OrderRequest req : requests) {
            if (req.OrderId == null) {
                throw new IllegalArgumentException('OrderId is required.');
            }

            List<OrderItem> orderItems = [
                SELECT Id, Quantity, UnitPrice, Product2.Name
                FROM OrderItem
                WHERE OrderId = :req.OrderId
                ORDER BY CreatedDate DESC
            ];

            for (OrderItem oi : orderItems) {
                allResponses.add(new OrderProductResponse(oi.Id, oi.Product2.Name, oi.Quantity, oi.UnitPrice));
            }
        }

        return allResponses;
    }

    public class OrderRequest {
        @InvocableVariable(required=true description='ID of the Order')
        public Id OrderId;
    }

    public class OrderProductResponse {
        @InvocableVariable(description='ID of the OrderItem')
        public Id OrderItemId;
        @InvocableVariable(description='Name of the Product')
        public String ProductName;
        @InvocableVariable(description='Quantity of the product in the order')
        public Decimal Quantity;
        @InvocableVariable(description='Unit price of the product in the order')
        public Decimal UnitPrice;

        public OrderProductResponse(Id orderItemId, String productName, Decimal quantity, Decimal unitPrice) {
            this.OrderItemId = orderItemId;
            this.ProductName = productName;
            this.Quantity = quantity;
            this.UnitPrice = unitPrice;
        }
    }
}
