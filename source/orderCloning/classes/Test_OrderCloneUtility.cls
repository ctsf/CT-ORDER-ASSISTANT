@IsTest
public with sharing class Test_OrderCloneUtility {
    @IsTest
    static void testCloneOrderWithOrderId() {
        Map<String, Object> testData = TestFactory.createTestData();
        orders__Order__c testOrder = (orders__Order__c)testData.get('testOrder');

        Test.startTest();
        OrderCloneUtility util = new OrderCloneUtility()
            .setOrderId(testOrder.Id)
            .setIsDeliveriesToBeCloned(true)
            .setIsDeliveryDatesToBeShifted(true)
            .setIsQtysToBeCloned(true);
        Id clonedOrderId = util.cloneOrder();
        Test.stopTest();

        validateClone(testOrder.Id, clonedOrderId, true, null);
    }

    @IsTest
    static void testCloneOrderWithNewAccount() {
        Map<String, Object> testData = TestFactory.createTestData();
        orders__Order__c testOrder = (orders__Order__c)testData.get('testOrder');
        Account newAccount = new Account(Name = 'New Test Account');
        insert newAccount;

        Test.startTest();
        OrderCloneUtility util = new OrderCloneUtility()
            .setOrderId(testOrder.Id)
            .setNewAccountId(newAccount.Id)
            .setIsDeliveriesToBeCloned(true);
        Id clonedOrderId = util.cloneOrder();
        Test.stopTest();

        validateClone(testOrder.Id, clonedOrderId, true, newAccount.Id);
    }

    @IsTest
    static void testCloneOrderWithoutDeliveries() {
        Map<String, Object> testData = TestFactory.createTestData();
        orders__Order__c testOrder = (orders__Order__c)testData.get('testOrder');

        Test.startTest();
        OrderCloneUtility util = new OrderCloneUtility()
            .setOrderId(testOrder.Id)
            .setIsDeliveriesToBeCloned(false);
        Id clonedOrderId = util.cloneOrder();
        Test.stopTest();

        validateClone(testOrder.Id, clonedOrderId, false, null);
    }

    private static void validateClone(Id originalOrderId, Id clonedOrderId, Boolean expectDeliveries, Id expectedNewAccountId) {
        orders__Order__c clonedOrder = [SELECT Id, orders__AccountId__c, orders__Stage__c FROM orders__Order__c WHERE Id = :clonedOrderId];
        orders__Order__c originalOrder = [SELECT Id, orders__AccountId__c FROM orders__Order__c WHERE Id = :originalOrderId];

        System.assertNotEquals(clonedOrder.Id, originalOrder.Id, 'Cloned order should have a different ID');
        System.assertEquals(clonedOrder.orders__Stage__c, 'OnHold', 'Cloned order stage should be "OnHold"');

        if (expectedNewAccountId != null) {
            System.assertEquals(clonedOrder.orders__AccountId__c, expectedNewAccountId, 'Cloned order AccountId should match the new AccountId');
        } else {
            System.assertEquals(clonedOrder.orders__AccountId__c, originalOrder.orders__AccountId__c, 'Cloned order AccountId should match the original');
        }

        List<orders__Delivery__c> clonedDeliveries = [
            SELECT Id
            FROM orders__Delivery__c
            WHERE orders__OrderId__c = :clonedOrderId
        ];

        if (expectDeliveries) {
            System.assertNotEquals(clonedDeliveries.size(), 0, 'Deliveries should be cloned');
        } else {
            System.assertEquals(clonedDeliveries.size(), 0, 'No deliveries should be cloned');
        }
    }
}