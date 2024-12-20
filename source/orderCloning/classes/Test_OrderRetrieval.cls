@IsTest
public with sharing class Test_OrderRetrieval {
    @IsTest
    static void testRetrieveOrdersWithNoCriteria() {
        OrderRetrieval.OrderRetrievalRequest request = new OrderRetrieval.OrderRetrievalRequest();
        request.autoNumber = null;
        request.accountId = null;

        List<OrderRetrieval.OrderRetrievalRequest> requests = new List<OrderRetrieval.OrderRetrievalRequest>{request};

        Test.startTest();
        List<OrderRetrieval.OrderRetrievalResponse> responses = OrderRetrieval.retrieveOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Only one response should be returned.');
        System.assertEquals('ERROR', responses[0].status, 'The response status should be ERROR.');
        System.assertEquals('Either AutoNumber or Account ID must be provided.', responses[0].message, 'Error message should match.');
    }
}