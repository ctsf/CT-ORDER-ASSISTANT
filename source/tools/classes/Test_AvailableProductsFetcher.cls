@IsTest
public with sharing class Test_AvailableProductsFetcher {

    @IsTest
    static void testListAvailableProducts_Success() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Id standardPbId = Test.getStandardPricebookId();

        Product2 productA = new Product2(Name='Product A', IsActive=true);
        Product2 productB = new Product2(Name='Product B', IsActive=true);
        Product2 productC = new Product2(Name='Product C', IsActive=true);
        insert new List<Product2>{productA, productB, productC};

        PricebookEntry pbeA = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=productA.Id, UnitPrice=50, IsActive=true);
        PricebookEntry pbeB = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=productB.Id, UnitPrice=100, IsActive=true);
        PricebookEntry pbeC = new PricebookEntry(Pricebook2Id=standardPbId, Product2Id=productC.Id, UnitPrice=200, IsActive=true);
        insert new List<PricebookEntry>{pbeA, pbeB, pbeC};

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=standardPbId);
        insert ord;

        OrderItem oiB = new OrderItem(OrderId=ord.Id, PricebookEntryId=pbeB.Id, Quantity=2, UnitPrice=100);
        insert oiB;

        AvailableProductsFetcher.OrderRequest req = new AvailableProductsFetcher.OrderRequest();
        req.OrderId = ord.Id;

        Test.startTest();
        List<AvailableProductsFetcher.AvailableProductResponse> responses = AvailableProductsFetcher.listAvailableProducts(new List<AvailableProductsFetcher.OrderRequest>{req});
        Test.stopTest();

        System.assertEquals(2, responses.size(), 'Should return 2 available products');
        Set<String> productNames = new Set<String>();
        for (AvailableProductsFetcher.AvailableProductResponse r : responses) {
            productNames.add(r.ProductName);
        }

        System.assert(productNames.contains('Product A'), 'Should contain Product A');
        System.assert(productNames.contains('Product C'), 'Should contain Product C');
    }

    @IsTest
    static void testListAvailableProducts_NoPricebook() {
        Account acc = new Account(Name='No PB Account');
        insert acc;

        Order ord = new Order(AccountId=acc.Id, EffectiveDate=Date.today(), Status='Draft');
        insert ord;

        AvailableProductsFetcher.OrderRequest req = new AvailableProductsFetcher.OrderRequest();
        req.OrderId = ord.Id;

        Test.startTest();
        List<AvailableProductsFetcher.AvailableProductResponse> responses = AvailableProductsFetcher.listAvailableProducts(new List<AvailableProductsFetcher.OrderRequest>{req});
        Test.stopTest();

        System.assertEquals(0, responses.size(), 'No pricebook means no products');
    }

    @IsTest
    static void testListAvailableProducts_NoRequests() {
        Test.startTest();
        try {
            AvailableProductsFetcher.listAvailableProducts(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testListAvailableProducts_MissingOrderId() {
        AvailableProductsFetcher.OrderRequest req = new AvailableProductsFetcher.OrderRequest();
        req.OrderId = null;

        Test.startTest();
        try {
            AvailableProductsFetcher.listAvailableProducts(new List<AvailableProductsFetcher.OrderRequest>{req});
            System.assert(false, 'Expected exception for missing OrderId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('OrderId is required.'), 'Expected exception');
        }
        Test.stopTest();
    }
}