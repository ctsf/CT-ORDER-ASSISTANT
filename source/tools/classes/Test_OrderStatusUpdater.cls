@IsTest
public class Test_OrderStatusUpdater {
    @IsTest
    static void testUpdateOrderStatus_Success() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebookId
        );
        insert order;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert orderItem;

        OrderStatusUpdater.OrderStatusRequest request = new OrderStatusUpdater.OrderStatusRequest();
        request.OrderId = order.Id;
        request.Status = 'Activated';

        Test.startTest();
        OrderStatusUpdater.updateOrderStatus(new List<OrderStatusUpdater.OrderStatusRequest>{request});
        Test.stopTest();

        Order updatedOrder = [SELECT Status FROM Order WHERE Id = :order.Id];
        System.assertEquals('Activated', updatedOrder.Status, 'Order status should be updated to Activated');
    }

    @IsTest
    static void testUpdateOrderStatus_MissingOrderId() {
        OrderStatusUpdater.OrderStatusRequest request = new OrderStatusUpdater.OrderStatusRequest();
        request.Status = 'Activated';

        Test.startTest();
        try {
            OrderStatusUpdater.updateOrderStatus(new List<OrderStatusUpdater.OrderStatusRequest>{request});
            System.assert(false, 'Exception should have been thrown for missing OrderId.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('OrderId is required.'), 'Exception message should match');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateOrderStatus_MissingStatus() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert order;

        OrderStatusUpdater.OrderStatusRequest request = new OrderStatusUpdater.OrderStatusRequest();
        request.OrderId = order.Id;

        Test.startTest();
        try {
            OrderStatusUpdater.updateOrderStatus(new List<OrderStatusUpdater.OrderStatusRequest>{request});
            System.assert(false, 'Exception should have been thrown for missing Status.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Status is required.'), 'Exception message should match');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateOrderStatus_nullRequestList() {
        Test.startTest();
        try {
            OrderStatusUpdater.updateOrderStatus(null);
            System.Assert(false, 'Exception should have been thrown for null requests list.');
        } catch (Exception e) {
            System.Assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Exception message should match');
        }
        Test.stopTest();
    }
}