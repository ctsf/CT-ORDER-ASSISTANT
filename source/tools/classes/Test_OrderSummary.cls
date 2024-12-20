@IsTest
public with sharing class Test_OrderSummary {

    @IsTest
    static void testGetOrderSummary_Success() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Order order1 = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order1;

        Order order2 = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order2;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = order1.Pricebook2Id,
            Product2Id = product.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pricebookEntry;

        OrderItem orderItem1 = new OrderItem(
            OrderId = order1.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 500
        );
        insert orderItem1;

        OrderItem orderItem2 = new OrderItem(
            OrderId = order2.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 700
        );
        insert orderItem2;

        order2.Status = 'Activated';
        update order2;

        OrderSummary.OrderSummaryRequest request = new OrderSummary.OrderSummaryRequest();
        request.AccountId = account.Id;

        Test.startTest();
        List<OrderSummary.OrderSummaryResponse> responses = OrderSummary.getOrderSummary(new List<OrderSummary.OrderSummaryRequest>{request});
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'There should be one summary response.');
        OrderSummary.OrderSummaryResponse response = responses[0];
        System.assertEquals(account.Id, response.AccountId, 'AccountId should match the requested Account.');
        System.assertEquals(2, response.TotalOrders, 'TotalOrders should be 2.');
        System.assertEquals(1200, response.TotalRevenue, 'TotalRevenue should be the sum of all orders.');
        System.assertEquals(1, response.ActivatedOrders, 'ActivatedOrders should count only activated orders.');
    }

    @IsTest
    static void testGetOrderSummary_MultipleAccounts() {
        Account account1 = new Account(Name = 'Test Account 1');
        insert account1;
    
        Account account2 = new Account(Name = 'Test Account 2');
        insert account2;
    
        Order order1 = new Order(
            AccountId = account1.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order1;
    
        Order order2 = new Order(
            AccountId = account2.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order2;
    
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
    
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = order1.Pricebook2Id,
            Product2Id = product.Id,
            UnitPrice = 300,
            IsActive = true
        );
        insert pricebookEntry;
    
        OrderItem orderItem1 = new OrderItem(
            OrderId = order1.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 300
        );
        insert orderItem1;
    
        OrderItem orderItem2 = new OrderItem(
            OrderId = order2.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 400
        );
        insert orderItem2;
    
        order2.Status = 'Activated';
        update order2;
    
        OrderSummary.OrderSummaryRequest request1 = new OrderSummary.OrderSummaryRequest();
        request1.AccountId = account1.Id;
    
        OrderSummary.OrderSummaryRequest request2 = new OrderSummary.OrderSummaryRequest();
        request2.AccountId = account2.Id;
    
        Test.startTest();
        List<OrderSummary.OrderSummaryResponse> responses = OrderSummary.getOrderSummary(new List<OrderSummary.OrderSummaryRequest>{request1, request2});
        Test.stopTest();
    
        System.assertEquals(2, responses.size(), 'There should be two summary responses.');
    
        for (OrderSummary.OrderSummaryResponse response : responses) {
            if (response.AccountId == account1.Id) {
                System.assertEquals(1, response.TotalOrders, 'TotalOrders for Account 1 should be 1.');
                System.assertEquals(300, response.TotalRevenue, 'TotalRevenue for Account 1 should be 300.');
                System.assertEquals(0, response.ActivatedOrders, 'ActivatedOrders for Account 1 should be 0.');
            } else if (response.AccountId == account2.Id) {
                System.assertEquals(1, response.TotalOrders, 'TotalOrders for Account 2 should be 1.');
                System.assertEquals(400, response.TotalRevenue, 'TotalRevenue for Account 2 should be 400.');
                System.assertEquals(1, response.ActivatedOrders, 'ActivatedOrders for Account 2 should be 1.');
            } else {
                System.assert(false, 'Unexpected AccountId in response.');
            }
        }
    }   
}