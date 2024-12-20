@IsTest
public with sharing class Test_OrderProductAdding {

    @IsTest
    static void testAddProductToOrder_Success() {
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

        OrderProductAdding.OrderProductRequest request = new OrderProductAdding.OrderProductRequest();
        request.OrderId = order.Id;
        request.ProductId = product.Id;
        request.Quantity = 2;

        Test.startTest();
        OrderProductAdding.addProductToOrder(new List<OrderProductAdding.OrderProductRequest>{request});
        Test.stopTest();

        OrderItem orderItem = [SELECT Id, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :order.Id AND PricebookEntryId = :pricebookEntry.Id LIMIT 1];
        System.assertNotEquals(null, orderItem, 'OrderItem should be created');
        System.assertEquals(2, orderItem.Quantity, 'Quantity should match');
        System.assertEquals(100, orderItem.UnitPrice, 'Unit price should match');
    }

    @IsTest
    static void testAddProductToOrder_FinalizedOrder() {
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

        OrderProductAdding.OrderProductRequest request = new OrderProductAdding.OrderProductRequest();
        request.OrderId = order.Id;
        request.ProductId = product.Id;
        request.Quantity = 1;

        Test.startTest();
        try {
            OrderProductAdding.addProductToOrder(new List<OrderProductAdding.OrderProductRequest>{request});
            System.assert(false, 'Exception should have been thrown for a finalized order.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Cannot add products to a finalized order.'), 'Exception message should match');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAddProductToOrder_NoMatchingPricebookEntry() {
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

        OrderProductAdding.OrderProductRequest request = new OrderProductAdding.OrderProductRequest();
        request.OrderId = order.Id;
        request.ProductId = product.Id; // Intentionally no matching PricebookEntry
        request.Quantity = 1;

        Test.startTest();
        try {
            OrderProductAdding.addProductToOrder(new List<OrderProductAdding.OrderProductRequest>{request});
            System.assert(false, 'Exception should have been thrown for missing PricebookEntry.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('No matching PricebookEntry found for the specified product in the orders pricebook.'), 'Exception message should match');
        }
        Test.stopTest();
    }
}