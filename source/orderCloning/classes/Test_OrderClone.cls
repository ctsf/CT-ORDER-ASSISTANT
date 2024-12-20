@IsTest
public with sharing class Test_OrderClone {
    @IsTest
    static void testCloneOrdersInvalidRequest() {
        List<OrderClone.CloneOrderRequest> requests = new List<OrderClone.CloneOrderRequest>();
        OrderClone.CloneOrderRequest invalidRequest = new OrderClone.CloneOrderRequest();
        requests.add(invalidRequest);

        Test.startTest();
        List<OrderClone.CloneOrderResponse> responses = OrderClone.cloneOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'There should be exactly one response.');
        OrderClone.CloneOrderResponse response = responses[0];
        System.assertEquals('ERROR', response.status, 'The response status should be ERROR for invalid request.');
        System.assertEquals('Order ID must be provided.', response.message, 'The error message should indicate missing Order ID.');
    }
}