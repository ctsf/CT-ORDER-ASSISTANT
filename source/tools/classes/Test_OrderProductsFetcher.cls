@IsTest
public with sharing class Test_OrderProductsFetcher {

    @IsTest
    static void testGetOrderProducts_MultipleOrders() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 productA = new Product2(Name='Product A', IsActive=true);
        Product2 productB = new Product2(Name='Product B', IsActive=true);
        insert new List<Product2>{productA, productB};

        PricebookEntry pbeA = new PricebookEntry(
            Pricebook2Id=standardPbId, 
            Product2Id=productA.Id, 
            UnitPrice=50, 
            IsActive=true
        );
        PricebookEntry pbeB = new PricebookEntry(
            Pricebook2Id=standardPbId, 
            Product2Id=productB.Id, 
            UnitPrice=100, 
            IsActive=true
        );
        insert new List<PricebookEntry>{pbeA, pbeB};

        Order ord1 = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        Order ord2 = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert new List<Order>{ord1, ord2};

        OrderItem oi1 = new OrderItem(OrderId=ord1.Id, PricebookEntryId=pbeA.Id, Quantity=2, UnitPrice=50);
        OrderItem oi2 = new OrderItem(OrderId=ord1.Id, PricebookEntryId=pbeB.Id, Quantity=3, UnitPrice=100);
        insert new List<OrderItem>{oi1, oi2};

        OrderItem oi3 = new OrderItem(OrderId=ord2.Id, PricebookEntryId=pbeA.Id, Quantity=1, UnitPrice=50);
        insert oi3;

        OrderProductsFetcher.OrderRequest req1 = new OrderProductsFetcher.OrderRequest();
        req1.OrderId = ord1.Id;

        OrderProductsFetcher.OrderRequest req2 = new OrderProductsFetcher.OrderRequest();
        req2.OrderId = ord2.Id;

        Test.startTest();
        List<OrderProductsFetcher.OrderProductResponse> responses = OrderProductsFetcher.getOrderProducts(
            new List<OrderProductsFetcher.OrderRequest>{req1, req2}
        );
        Test.stopTest();

        System.assertEquals(3, responses.size(), 'Should return 3 order items in total');

        Set<Id> returnedItemIds = new Set<Id>();
        for (OrderProductsFetcher.OrderProductResponse r : responses) {
            returnedItemIds.add(r.OrderItemId);
        }

        System.assert(returnedItemIds.contains(oi1.Id), 'Should contain oi1');
        System.assert(returnedItemIds.contains(oi2.Id), 'Should contain oi2');
        System.assert(returnedItemIds.contains(oi3.Id), 'Should contain oi3');
    }

    @IsTest
    static void testGetOrderProducts_EmptyRequests() {
        Test.startTest();
        try {
            OrderProductsFetcher.getOrderProducts(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetOrderProducts_MissingOrderId() {
        OrderProductsFetcher.OrderRequest req = new OrderProductsFetcher.OrderRequest();
        req.OrderId = null;

        Test.startTest();
        try {
            OrderProductsFetcher.getOrderProducts(new List<OrderProductsFetcher.OrderRequest>{req});
            System.assert(false, 'Expected exception for missing OrderId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('OrderId is required.'), 'Expected exception for missing OrderId');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetOrderProducts_NoItemsForOrder() {
        Account acc = new Account(Name='No Items Acc');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Order emptyOrder = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert emptyOrder;

        OrderProductsFetcher.OrderRequest req = new OrderProductsFetcher.OrderRequest();
        req.OrderId = emptyOrder.Id;

        Test.startTest();
        List<OrderProductsFetcher.OrderProductResponse> responses = OrderProductsFetcher.getOrderProducts(new List<OrderProductsFetcher.OrderRequest>{req});
        Test.stopTest();

        System.assertEquals(0, responses.size(), 'No order items means empty list');
    }
}
