@IsTest
public with sharing class Test_OrderItemQuantityUpdater {

    @IsTest
    static void testUpdateQuantities_Success() {
        Account acc = new Account(Name='Test Acc');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 product = new Product2(Name='Test Product', IsActive=true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=product.Id, UnitPrice=50, IsActive=true);
        insert pbe;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderItem oi = new OrderItem(OrderId=ord.Id, PricebookEntryId=pbe.Id, Quantity=2, UnitPrice=50);
        insert oi;

        OrderItemQuantityUpdater.UpdateRequest req = new OrderItemQuantityUpdater.UpdateRequest();
        req.OrderItemId = oi.Id;
        req.NewQuantity = 5;

        Test.startTest();
        OrderItemQuantityUpdater.updateQuantities(new List<OrderItemQuantityUpdater.UpdateRequest>{req});
        Test.stopTest();

        OrderItem updatedOi = [SELECT Quantity FROM OrderItem WHERE Id = :oi.Id];
        System.assertEquals(5, updatedOi.Quantity, 'Quantity should be updated to 5');
    }

    @IsTest
    static void testUpdateQuantities_FinalizedOrder() {
        Account acc = new Account(Name='Finalized Order Acc');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 product = new Product2(Name='Test Product', IsActive=true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=product.Id, UnitPrice=50, IsActive=true);
        insert pbe;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderItem oi = new OrderItem(OrderId=ord.Id, PricebookEntryId=pbe.Id, Quantity=2, UnitPrice=50);
        insert oi;

        OrderItemQuantityUpdater.UpdateRequest req = new OrderItemQuantityUpdater.UpdateRequest();
        req.OrderItemId = oi.Id;
        req.NewQuantity = 10;

        ord.Status = 'Activated';
        update ord;

        Test.startTest();
        try {
            OrderItemQuantityUpdater.updateQuantities(new List<OrderItemQuantityUpdater.UpdateRequest>{req});
            System.assert(false, 'Expected exception for finalized order');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Cannot update quantity because the order is finalized'), 'Expected finalized order exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuantities_NoRequests() {
        Test.startTest();
        try {
            OrderItemQuantityUpdater.updateQuantities(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuantities_MissingOrderItemId() {
        OrderItemQuantityUpdater.UpdateRequest req = new OrderItemQuantityUpdater.UpdateRequest();
        req.OrderItemId = null;
        req.NewQuantity = 5;

        Test.startTest();
        try {
            OrderItemQuantityUpdater.updateQuantities(new List<OrderItemQuantityUpdater.UpdateRequest>{req});
            System.assert(false, 'Expected exception for missing OrderItemId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('OrderItemId is required.'), 'Expected exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuantities_InvalidQuantity() {
        Account acc = new Account(Name='Invalid Q Acc');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 product = new Product2(Name='Test Product', IsActive=true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=product.Id, UnitPrice=50, IsActive=true);
        insert pbe;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderItem oi = new OrderItem(OrderId=ord.Id, PricebookEntryId=pbe.Id, Quantity=2, UnitPrice=50);
        insert oi;

        OrderItemQuantityUpdater.UpdateRequest req = new OrderItemQuantityUpdater.UpdateRequest();
        req.OrderItemId = oi.Id;
        req.NewQuantity = 0; 

        Test.startTest();
        try {
            OrderItemQuantityUpdater.updateQuantities(new List<OrderItemQuantityUpdater.UpdateRequest>{req});
            System.assert(false, 'Expected exception for invalid quantity');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('NewQuantity must be greater than 0.'), 'Expected invalid quantity exception');
        }
        Test.stopTest();
    }
}