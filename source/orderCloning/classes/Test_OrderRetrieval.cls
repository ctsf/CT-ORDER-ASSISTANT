@IsTest
public with sharing class Test_OrderRetrieval {
    @IsTest
    static void testRetrieveOrdersWithAutoNumber() {
        Map<String, Object> testData = TestFactory.createTestData();
        SObject testOrder = (SObject) testData.get('testOrder');

        OrderRetrieval.OrderRetrievalRequest request = new OrderRetrieval.OrderRetrievalRequest();
        String orderAutoNumber = (String) testOrder.get('Name');
        request.autoNumber = orderAutoNumber;

        List<OrderRetrieval.OrderRetrievalRequest> requests = new List<OrderRetrieval.OrderRetrievalRequest>{request};

        Test.startTest();
        List<OrderRetrieval.OrderRetrievalResponse> responses = OrderRetrieval.retrieveOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Only one response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        System.assertNotEquals(null, responses[0].orders, 'Orders list should not be null.');
        System.assertEquals(1, responses[0].orders.size(), 'One order should be returned.');
        System.assertEquals(testOrder.get('Id'), responses[0].orders[0].get('Id'), 'The returned order ID should match the test order.');
    }

    @IsTest
    static void testRetrieveOrdersWithInvalidAutoNumber() {
        OrderRetrieval.OrderRetrievalRequest request = new OrderRetrieval.OrderRetrievalRequest();
        request.autoNumber = 'InvalidAutoNumber123';

        List<OrderRetrieval.OrderRetrievalRequest> requests = new List<OrderRetrieval.OrderRetrievalRequest>{request};

        Test.startTest();
        List<OrderRetrieval.OrderRetrievalResponse> responses = OrderRetrieval.retrieveOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Only one response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        System.assertEquals('No orders found for the given criteria.', responses[0].message, 'Message should indicate no orders found.');
        System.assertEquals(0, responses[0].orders.size(), 'No orders should be returned.');
    }

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

    @IsTest
    static void testRetrieveOrdersWithAccountId() {
        Map<String, Object> testData = TestFactory.createTestData();
        SObject testAccount = (SObject) testData.get('testAccount');
        SObject testOrder = (SObject) testData.get('testOrder');

        OrderRetrieval.OrderRetrievalRequest request = new OrderRetrieval.OrderRetrievalRequest();
        request.accountId = (Id) testAccount.get('Id');

        List<OrderRetrieval.OrderRetrievalRequest> requests = new List<OrderRetrieval.OrderRetrievalRequest>{request};

        Test.startTest();
        List<OrderRetrieval.OrderRetrievalResponse> responses = OrderRetrieval.retrieveOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Only one response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        System.assertNotEquals(null, responses[0].orders, 'Orders list should not be null.');
        System.assertEquals(1, responses[0].orders.size(), 'One order should be returned for the account.');
        System.assertEquals(testOrder.get('Id'), responses[0].orders[0].get('Id'), 'The returned order ID should match the test order.');
        System.assertEquals(testAccount.get('Id'), responses[0].orders[0].get('orders__AccountId__c'), 'The order should belong to the correct account.');
    }
}