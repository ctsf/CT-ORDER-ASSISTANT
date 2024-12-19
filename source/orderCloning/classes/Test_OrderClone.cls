@IsTest
public with sharing class Test_OrderClone {
    @IsTest
    static void testCloneOrders() {
        Map<String, Object> testData = TestFactory.createTestData();
        SObject testOrder = (SObject)testData.get('testOrder');
        SObject testAccount = (SObject)testData.get('testAccount');

        List<OrderClone.CloneOrderRequest> requests = new List<OrderClone.CloneOrderRequest>();
        OrderClone.CloneOrderRequest request = new OrderClone.CloneOrderRequest();
        request.orderId = (Id)testOrder.get('Id');
        request.newAccountId = (Id)testAccount.get('Id');
        request.cloneDeliveries = true;
        request.shiftDeliveryDates = true;
        request.cloneQuantities = true;
        requests.add(request);

        Test.startTest();
        List<OrderClone.CloneOrderResponse> responses = OrderClone.cloneOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'There should be exactly one response.');
        OrderClone.CloneOrderResponse response = responses[0];
        String clonedOrderId = response.clonedOrderId;
        System.assertEquals('SUCCESS', response.status, 'The cloning operation should be successful.');
        System.assert(clonedOrderId != null, 'Cloned Order ID should not be null');
        System.assert(response.clonedOrderLink.contains(clonedOrderId), 'The cloned order link should contain the cloned order ID.');

        SObject clonedOrder = Database.query('SELECT Id, orders__AccountId__c, orders__Stage__c FROM orders__Order__c WHERE Id = :clonedOrderId LIMIT 1');

        System.assertEquals(testAccount.get('Id'), clonedOrder.get('orders__AccountId__c'), 'The account ID should match in the cloned order.');
        System.assertEquals('OnHold', clonedOrder.get('orders__Stage__c'), 'The stage of the cloned order should be OnHold.');

        List<SObject> clonedDeliveries = Database.query('SELECT Id, orders__DeliveryDate__c FROM orders__Delivery__c WHERE orders__OrderId__c = :clonedOrderId');
        System.assert(!clonedDeliveries.isEmpty(), 'Deliveries should be cloned successfully.');

        List<SObject> clonedDeliveryLineItems = Database.query('SELECT Id FROM orders__DeliveryLineItem__c WHERE orders__DeliveryId__c IN :clonedDeliveries');
        System.assert(!clonedDeliveryLineItems.isEmpty(), 'Delivery line items should be cloned successfully.');
    }

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