global with sharing class OrderRetrievalV2 {
    @InvocableMethod(label='Retrieve Orders V2' description='Retrieve orders by AutoNumber or Account ID with enhanced friendly UI details.')
    global static List<OrderRetrievalResponse> retrieveOrders(List<OrderRetrievalRequest> requests) {
        List<OrderRetrievalResponse> responses = new List<OrderRetrievalResponse>();

        for (OrderRetrievalRequest request : requests) {
            OrderRetrievalResponse response = new OrderRetrievalResponse();

            try {
                // Validate that at least one criteria is provided.
                if (String.isBlank(request.autoNumber) && request.accountId == null) {
                    response.status = 'ERROR';
                    response.message = 'Either AutoNumber or Account ID must be provided.';
                    response.friendlyUX = 'Please provide either an AutoNumber or an Account ID to retrieve orders.';
                    responses.add(response);
                    continue;
                }

                List<orders__Order__c> orders;

                // Retrieve by AutoNumber if provided.
                if (!String.isBlank(request.autoNumber)) {
                    orders = new List<orders__Order__c>();
                    orders__Order__c order = getOrderByAutoNumber(request.autoNumber);
                    if (order != null) {
                        orders.add(order);
                    }
                }
                // Otherwise retrieve by Account ID.
                else if (request.accountId != null) {
                    orders = getOrdersByAccount(request.accountId);
                }
                else {
                    orders = new List<orders__Order__c>();
                }

                // Build the response.
                if (orders.isEmpty()) {
                    response.status = 'SUCCESS';
                    response.message = 'No orders found for the given criteria.';
                    response.orders = new List<orders__Order__c>();
                    response.friendlyUX = 'No orders were found matching your criteria.';
                } else {
                    response.status = 'SUCCESS';
                    response.message = 'Orders retrieved successfully.';
                    response.orders = new List<orders__Order__c>();
                    response.orders.addAll(orders);

                    // Build a friendly UX summary for each order.
                    List<String> orderSummaries = new List<String>();
                    for (orders__Order__c o : orders) {
                        String orderName = o.Name;
                        // Use the relationship field to fetch the account name, if available.
                        String accountName = (o.orders__AccountId__r != null && !String.isBlank(o.orders__AccountId__r.Name))
                            ? o.orders__AccountId__r.Name
                            : 'N/A';
                        String stage = (o.orders__Stage__c != null) ? o.orders__Stage__c : 'N/A';
                        String createdDate = (o.CreatedDate != null) ? String.valueOf(o.CreatedDate) : 'N/A';
                        // Compose a summary string for the order.
                        String summary = 'Order "' + orderName + '" for account "' + accountName + 
                            '" is in stage "' + stage + '", created on ' + createdDate;
                        orderSummaries.add(summary);
                    }
                    response.friendlyUX = 'Retrieved Orders: ' + String.join(orderSummaries, '; ');
                }
            } catch (Exception e) {
                response.status = 'ERROR';
                response.message = 'An error occurred: ' + e.getMessage();
                response.friendlyUX = 'An unexpected error occurred while retrieving orders. Please contact support if the issue persists.';
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

        @InvocableVariable(label='Friendly UX Message' description='A user-friendly summary of the retrieved orders for display in chat.')
        global String friendlyUX;
    }

    public static orders__Order__c getOrderByAutoNumber(String autoNumber) {
        if (String.isBlank(autoNumber)) {
            throw new IllegalArgumentException('AutoNumber cannot be null or empty.');
        }
    
        if (!Schema.sObjectType.orders__Order__c.isAccessible()) {
            throw new Metadata.NoAccessException('Insufficient permissions to access Order records.');
        }
    
        List<orders__Order__c> orders = [
            SELECT Id, Name, orders__AccountId__c, orders__AccountId__r.Name, orders__Stage__c, CreatedDate
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
            SELECT Id, Name, orders__AccountId__c, orders__AccountId__r.Name, orders__Stage__c, CreatedDate
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
            SELECT Id, Name, orders__AccountId__c, orders__AccountId__r.Name, orders__Stage__c, CreatedDate
            FROM orders__Order__c
            WHERE orders__AccountId__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    
        return orders.isEmpty() ? null : orders[0];
    }
}