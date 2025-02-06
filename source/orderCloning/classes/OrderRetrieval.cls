global with sharing class OrderRetrieval {
    @InvocableMethod(label='Retrieve Orders' description='Retrieve orders by AutoNumber or Account ID.')
    global static List<OrderRetrievalResponse> retrieveOrders(List<OrderRetrievalRequest> requests) {
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

                List<orders__Order__c> orders;

                if (!String.isBlank(request.autoNumber)) {
                    orders = new List<orders__Order__c>();
                    orders__Order__c order = getOrderByAutoNumber(request.autoNumber);
                    if (order != null) {
                        orders.add(order);
                    }
                } else if (request.accountId != null) {
                    orders = getOrdersByAccount(request.accountId);
                } else {
                    orders = new List<orders__Order__c>();
                }

                if (orders.isEmpty()) {
                    response.status = 'SUCCESS';
                    response.message = 'No orders found for the given criteria.';
                    response.orders = new List<orders__Order__c>();
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Orders retrieved successfully.';
                    response.orders = new List<orders__Order__c>();
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

    global class OrderRetrievalRequest {
        @InvocableVariable(required=false label='AutoNumber' description='The AutoNumber of the order to retrieve.')
        global String autoNumber;

        @InvocableVariable(required=false label='Account ID' description='The Account ID to retrieve orders for.')
        global Id accountId;
    }

    global class OrderRetrievalResponse {
        @InvocableVariable(label='Status' description='The status of the order retrieval operation.')
        global String status;

        @InvocableVariable(label='Message' description='Details about the order retrieval operation.')
        global String message;

        @InvocableVariable(label='Orders' description='The list of retrieved orders.')
        global List<orders__Order__c> orders;
    }

    public static orders__Order__c getOrderByAutoNumber(String autoNumber) {
        if (String.isBlank(autoNumber)) {
            throw new IllegalArgumentException('AutoNumber cannot be null or empty.');
        }
    
        if (!Schema.sObjectType.orders__Order__c.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }
    
        List<orders__Order__c> orders = [
            SELECT Id, Name, orders__AccountId__c, orders__Stage__c, CreatedDate
            FROM orders__Order__c
            WHERE Name LIKE :('%' + autoNumber)
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    
        return orders.isEmpty() ? null : orders[0];
    }
    
    public static List<orders__Order__c> getOrdersByAccount(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null.');
        }

        if (!Schema.sObjectType.orders__Order__c.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }

        return [
            SELECT Id, Name, orders__AccountId__c, orders__Stage__c, CreatedDate
            FROM orders__Order__c
            WHERE orders__AccountId__c = :accountId
            ORDER BY CreatedDate DESC
        ];
    }


    public static orders__Order__c getMostRecentOrderByAccount(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null.');
        }

        if (!Schema.sObjectType.orders__Order__c.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }

        List<orders__Order__c> orders = [
            SELECT Id, Name, orders__AccountId__c, orders__Stage__c, CreatedDate
            FROM orders__Order__c
            WHERE orders__AccountId__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return orders.isEmpty() ? null : orders[0];
    }
}