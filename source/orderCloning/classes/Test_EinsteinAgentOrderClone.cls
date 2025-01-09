@isTest
public with sharing class Test_EinsteinAgentOrderClone {
    @IsTest
    static void testCloneOrderWithOrderId() {
        Map<String, Object> testData = TestFactory.createTestData();
        orders__Order__c testOrder = (orders__Order__c)testData.get('testOrder');

        EinsteinAgentOrderClone.CloneOrderRequest request = new EinsteinAgentOrderClone.CloneOrderRequest();
        request.orderId = testOrder.Id;
        request.cloneDeliveries = true;
        request.shiftDeliveryDates = true;
        request.cloneQuantities = true;

        List<EinsteinAgentOrderClone.CloneOrderRequest> requests = new List<EinsteinAgentOrderClone.CloneOrderRequest>{request};
        
        Test.startTest();
        List<EinsteinAgentOrderClone.CloneOrderResponse> responses = EinsteinAgentOrderClone.cloneOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'One response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        validateClone(testOrder.Id, responses[0].clonedOrderId, true, null);
    }

    @IsTest
    static void testCloneOrderWithNewAccount() {
        // Arrange
        Map<String, Object> testData = TestFactory.createTestData();
        orders__Order__c testOrder = (orders__Order__c)testData.get('testOrder');
        Account newAccount = new Account(Name = 'New Test Account');
        insert newAccount;

        EinsteinAgentOrderClone.CloneOrderRequest request = new EinsteinAgentOrderClone.CloneOrderRequest();
        request.orderId = testOrder.Id;
        request.newAccountId = newAccount.Id;
        request.cloneDeliveries = true;
        request.shiftDeliveryDates = false;

        List<EinsteinAgentOrderClone.CloneOrderRequest> requests = new List<EinsteinAgentOrderClone.CloneOrderRequest>{request};

        Test.startTest();
        List<EinsteinAgentOrderClone.CloneOrderResponse> responses = EinsteinAgentOrderClone.cloneOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'One response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        validateClone(testOrder.Id, responses[0].clonedOrderId, true, newAccount.Id);
    }

    @IsTest
    static void testCloneOrderWithoutDeliveries() {
        Map<String, Object> testData = TestFactory.createTestData();
        orders__Order__c testOrder = (orders__Order__c)testData.get('testOrder');

        EinsteinAgentOrderClone.CloneOrderRequest request = new EinsteinAgentOrderClone.CloneOrderRequest();
        request.orderId = testOrder.Id;
        request.cloneDeliveries = false;

        List<EinsteinAgentOrderClone.CloneOrderRequest> requests = new List<EinsteinAgentOrderClone.CloneOrderRequest>{request};

        Test.startTest();
        List<EinsteinAgentOrderClone.CloneOrderResponse> responses = EinsteinAgentOrderClone.cloneOrders(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'One response should be returned.');
        System.assertEquals('SUCCESS', responses[0].status, 'The response status should be SUCCESS.');
        validateClone(testOrder.Id, responses[0].clonedOrderId, false, null);
    }

    private static void validateClone(Id originalOrderId, String clonedOrderIdStr, Boolean expectDeliveries, Id expectedNewAccountId) {
        Id clonedOrderId = (Id)clonedOrderIdStr;

        orders__Order__c clonedOrder = [SELECT Id, orders__AccountId__c, orders__Stage__c FROM orders__Order__c WHERE Id = :clonedOrderId];
        orders__Order__c originalOrder = [SELECT Id, orders__AccountId__c FROM orders__Order__c WHERE Id = :originalOrderId];

        System.assertNotEquals(clonedOrder.Id, originalOrder.Id, 'Cloned order should have a different ID.');
        System.assertEquals(clonedOrder.orders__Stage__c, 'OnHold', 'Cloned order stage should be "OnHold".');

        if (expectedNewAccountId != null) {
            System.assertEquals(clonedOrder.orders__AccountId__c, expectedNewAccountId, 'Cloned order AccountId should match the new AccountId.');
        } else {
            System.assertEquals(clonedOrder.orders__AccountId__c, originalOrder.orders__AccountId__c, 'Cloned order AccountId should match the original.');
        }

        List<orders__Delivery__c> clonedDeliveries = [
            SELECT Id FROM orders__Delivery__c WHERE orders__OrderId__c = :clonedOrderId
        ];

        if (expectDeliveries) {
            System.assertNotEquals(clonedDeliveries.size(), 0, 'Deliveries should be cloned.');
        } else {
            System.assertEquals(clonedDeliveries.size(), 0, 'No deliveries should be cloned.');
        }
    }
}