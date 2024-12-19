public with sharing class OrderRetrieval {

    @InvocableMethod(label='Retrieve Orders' description='Retrieve orders by AutoNumber or Account ID.')
    public static List<OrderRetrievalResponse> retrieveOrders(List<OrderRetrievalRequest> requests) {
        List<OrderRetrievalResponse> responses = new List<OrderRetrievalResponse>();

        for (OrderRetrievalRequest request : requests) {
            OrderRetrievalResponse response = new OrderRetrievalResponse();

            try {
                if (String.isBlank(request.autoNumber) && request.accountId == null) {
                    response.status = 'ERROR';
                    response.message = 'Either AutoNumber or Account ID must be provided.';
                    responses.add(response);
                    continue;
                }

                List<SObject> orders;

                if (!String.isBlank(request.autoNumber)) {
                    orders = new List<SObject>();
                    SObject order = getOrderByAutoNumber(request.autoNumber);
                    if (order != null) {
                        orders.add(order);
                    }
                } else if (request.accountId != null) {
                    orders = getOrdersByAccount(request.accountId);
                } else {
                    orders = new List<SObject>();
                }

                if (orders.isEmpty()) {
                    response.status = 'SUCCESS';
                    response.message = 'No orders found for the given criteria.';
                    response.orders = new List<SObject>();
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Orders retrieved successfully.';
                    response.orders = new List<SObject>();
                    response.orders.addAll(orders);
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }

    public class OrderRetrievalRequest {
        @InvocableVariable(required=false label='AutoNumber' description='The AutoNumber of the order to retrieve.')
        public String autoNumber;

        @InvocableVariable(required=false label='Account ID' description='The Account ID to retrieve orders for.')
        public Id accountId;
    }

    public class OrderRetrievalResponse {
        @InvocableVariable(label='Status' description='The status of the order retrieval operation.')
        public String status;

        @InvocableVariable(label='Message' description='Details about the order retrieval operation.')
        public String message;

        @InvocableVariable(label='Orders' description='The list of retrieved orders.')
        public List<SObject> orders;
    }

    public static SObject getOrderByAutoNumber(String autoNumber) {
        if (String.isBlank(autoNumber)) {
            throw new IllegalArgumentException('AutoNumber cannot be null or empty.');
        }

        Schema.DescribeSObjectResult orderDescribe = Metadata.getDescribe('orders__Order__c');
        if (!orderDescribe.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }

        String query = 'SELECT Id, Name, orders__AccountId__c, orders__Stage__c, CreatedDate ' +
                       'FROM orders__Order__c WHERE Name LIKE :autoNumber ORDER BY CreatedDate DESC LIMIT 1';
        List<SObject> orders = Database.query(query);

        return orders.isEmpty() ? null : orders[0];
    }

    public static List<SObject> getOrdersByAccount(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null.');
        }

        Schema.DescribeSObjectResult orderDescribe = Metadata.getDescribe('orders__Order__c');
        if (!orderDescribe.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }

        String query = 'SELECT Id, Name, orders__AccountId__c, orders__Stage__c, CreatedDate ' +
                       'FROM orders__Order__c WHERE orders__AccountId__c = :accountId ORDER BY CreatedDate DESC';
        return Database.query(query);
    }

    public static SObject getMostRecentOrderByAccount(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null.');
        }

        Schema.DescribeSObjectResult orderDescribe = Metadata.getDescribe('orders__Order__c');
        if (!orderDescribe.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }

        String query = 'SELECT Id, Name, orders__AccountId__c, orders__Stage__c, CreatedDate ' +
                       'FROM orders__Order__c WHERE orders__AccountId__c = :accountId ORDER BY CreatedDate DESC LIMIT 1';
        List<SObject> orders = Database.query(query);

        return orders.isEmpty() ? null : orders[0];
    }
}