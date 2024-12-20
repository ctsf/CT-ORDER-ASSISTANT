@IsTest
public with sharing class Test_StandartOrderClone {

    @IsTest
    static void testCloneOrderWithProducts_Success() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = order.Pricebook2Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert orderItem;

        StandartOrderClone.OrderCloneRequest request = new StandartOrderClone.OrderCloneRequest();
        request.orderId = order.Id;

        Test.startTest();
        List<Id> clonedOrderIds = StandartOrderClone.cloneOrderWithProducts(new List<StandartOrderClone.OrderCloneRequest>{request});
        Test.stopTest();

        System.assertEquals(1, clonedOrderIds.size(), 'One order should be cloned.');

        Order clonedOrder = [SELECT AccountId, Pricebook2Id, Status FROM Order WHERE Id = :clonedOrderIds[0]];
        System.assertEquals(order.AccountId, clonedOrder.AccountId, 'Cloned order should have the same AccountId.');
        System.assertEquals(order.Pricebook2Id, clonedOrder.Pricebook2Id, 'Cloned order should have the same Pricebook2Id.');
        System.assertEquals('Draft', clonedOrder.Status, 'Cloned order should have Draft status.');

        List<OrderItem> clonedItems = [SELECT OrderId, PricebookEntryId, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :clonedOrderIds[0]];
        System.assertEquals(1, clonedItems.size(), 'One order item should be cloned.');
        System.assertEquals(orderItem.Quantity, clonedItems[0].Quantity, 'Cloned order item should have the same Quantity.');
        System.assertEquals(orderItem.UnitPrice, clonedItems[0].UnitPrice, 'Cloned order item should have the same UnitPrice.');
    }

    @IsTest
    static void testCloneOrderWithProducts_FinalizedOrder() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = order.Pricebook2Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert orderItem;

        order.Status = 'Activated';
        update order;

        StandartOrderClone.OrderCloneRequest request = new StandartOrderClone.OrderCloneRequest();
        request.orderId = order.Id;

        Test.startTest();
        List<Id> clonedOrderIds = StandartOrderClone.cloneOrderWithProducts(new List<StandartOrderClone.OrderCloneRequest>{request});
        Test.stopTest();

        Order clonedOrder = [SELECT Status FROM Order WHERE Id = :clonedOrderIds[0]];
        System.assertEquals('Draft', clonedOrder.Status, 'Cloned order should have Draft status even if the original order was finalized.');
    }

    @IsTest
    static void testCloneOrderWithProducts_NoOrderItems() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;

        StandartOrderClone.OrderCloneRequest request = new StandartOrderClone.OrderCloneRequest();
        request.orderId = order.Id;

        Test.startTest();
        List<Id> clonedOrderIds = StandartOrderClone.cloneOrderWithProducts(new List<StandartOrderClone.OrderCloneRequest>{request});
        Test.stopTest();

        System.assertEquals(1, clonedOrderIds.size(), 'One order should be cloned.');

        List<OrderItem> clonedItems = [SELECT Id FROM OrderItem WHERE OrderId = :clonedOrderIds[0]];
        System.assertEquals(0, clonedItems.size(), 'No order items should be cloned if the original order had none.');
    }
}