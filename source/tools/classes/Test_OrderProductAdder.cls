@IsTest
public with sharing class Test_OrderProductAdder {

    @IsTest
    static void testAddProducts_Success() {
        Account acc = new Account(Name='Add Prod Acc');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 productA = new Product2(Name='Product A', IsActive=true);
        insert productA;

        PricebookEntry pbeA = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=productA.Id, UnitPrice=50, IsActive=true);
        insert pbeA;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderProductAdder.AddProductRequest req = new OrderProductAdder.AddProductRequest();
        req.OrderId = ord.Id;
        req.ProductId = productA.Id;
        req.Quantity = 3;

        Test.startTest();
        OrderProductAdder.addProducts(new List<OrderProductAdder.AddProductRequest>{req});
        Test.stopTest();

        List<OrderItem> items = [SELECT Quantity, UnitPrice, PricebookEntryId FROM OrderItem WHERE OrderId = :ord.Id];
        System.assertEquals(1, items.size(), 'One order item should be added');
        System.assertEquals(3, items[0].Quantity, 'Quantity should match');
        System.assertEquals(50, items[0].UnitPrice, 'UnitPrice should come from PricebookEntry');
        System.assertEquals(pbeA.Id, items[0].PricebookEntryId, 'PricebookEntry should match');
    }

    @IsTest
    static void testAddProducts_FinalizedOrder() {
        Account acc = new Account(Name='Finalized');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 product = new Product2(Name='Test Product', IsActive=true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=product.Id, UnitPrice=100, IsActive=true);
        insert pbe;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderItem oi = new OrderItem(OrderId=ord.Id, PricebookEntryId=pbe.Id, Quantity=2, UnitPrice=50);
        insert oi;

        OrderProductAdder.AddProductRequest req = new OrderProductAdder.AddProductRequest();
        req.OrderId = ord.Id;
        req.ProductId = product.Id;
        req.Quantity = 1;

        ord.Status = 'Activated';
        update ord;

        Test.startTest();
        try {
            OrderProductAdder.addProducts(new List<OrderProductAdder.AddProductRequest>{req});
            System.assert(false, 'Expected exception for finalized order');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Cannot add products because the order is finalized'), 'Expected finalized order exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAddProducts_NoRequests() {
        Test.startTest();
        try {
            OrderProductAdder.addProducts(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAddProducts_InvalidQuantity() {
        Account acc = new Account(Name='Invalid Q Acc');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 product = new Product2(Name='Invalid Q Product', IsActive=true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=product.Id, UnitPrice=100, IsActive=true);
        insert pbe;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderProductAdder.AddProductRequest req = new OrderProductAdder.AddProductRequest();
        req.OrderId = ord.Id;
        req.ProductId = product.Id;
        req.Quantity = 0; 

        Test.startTest();
        try {
            OrderProductAdder.addProducts(new List<OrderProductAdder.AddProductRequest>{req});
            System.assert(false, 'Expected exception for invalid quantity');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Quantity must be greater than 0.'), 'Expected invalid quantity exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAddProducts_NoPbeFound() {
        Account acc = new Account(Name='No PBE Acc');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 productNoPbe = new Product2(Name='NoPBE Product', IsActive=true);
        insert productNoPbe;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderProductAdder.AddProductRequest req = new OrderProductAdder.AddProductRequest();
        req.OrderId = ord.Id;
        req.ProductId = productNoPbe.Id;
        req.Quantity = 1;

        Test.startTest();
        try {
            OrderProductAdder.addProducts(new List<OrderProductAdder.AddProductRequest>{req});
            System.assert(false, 'Expected exception for no pricebook entry');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('No active pricebook entry found'), 'Expected no pbe exception');
        }
        Test.stopTest();
    }
}