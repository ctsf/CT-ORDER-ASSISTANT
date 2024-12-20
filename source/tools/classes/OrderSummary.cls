public with sharing class OrderSummary {

    @InvocableMethod(label='Get Order Summary for Account' description='Returns a summary of orders for a specified account')
    public static List<OrderSummaryResponse> getOrderSummary(List<OrderSummaryRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        Set<Id> accountIds = new Set<Id>();
        for (OrderSummaryRequest request : requests) {
            if (request.AccountId == null) {
                throw new IllegalArgumentException('AccountId is required.');
            }
            accountIds.add(request.AccountId);
        }

        if (!Schema.sObjectType.Order.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access Orders.');
        }

        if (!Schema.sObjectType.Order.fields.AccountId.isAccessible() ||
            !Schema.sObjectType.Order.fields.TotalAmount.isAccessible() ||
            !Schema.sObjectType.Order.fields.Status.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access one or more fields on the Order object.');
        }

        Map<Id, OrderSummaryResponse> summaries = new Map<Id, OrderSummaryResponse>();

        for (Order order : [
            SELECT AccountId, TotalAmount, Status
            FROM Order
            WHERE AccountId IN :accountIds
        ]) {
            if (!summaries.containsKey(order.AccountId)) {
                summaries.put(order.AccountId, new OrderSummaryResponse(order.AccountId));
            }
            OrderSummaryResponse summary = summaries.get(order.AccountId);

            summary.TotalOrders++;
            summary.TotalRevenue += order.TotalAmount != null ? order.TotalAmount : 0;
            if (order.Status == 'Activated') {
                summary.ActivatedOrders++;
            }
        }

        return new List<OrderSummaryResponse>(summaries.values());
    }

    public class OrderSummaryRequest {
        @InvocableVariable(required=true description='ID of the Account for which to retrieve the order summary')
        public Id AccountId;
    }

    public class OrderSummaryResponse {
        @InvocableVariable(description='ID of the Account')
        public Id AccountId;

        @InvocableVariable(description='Total number of orders')
        public Integer TotalOrders = 0;

        @InvocableVariable(description='Total revenue from orders')
        public Decimal TotalRevenue = 0;

        @InvocableVariable(description='Number of activated orders')
        public Integer ActivatedOrders = 0;

        public OrderSummaryResponse(Id accountId) {
            this.AccountId = accountId;
        }
    }
}