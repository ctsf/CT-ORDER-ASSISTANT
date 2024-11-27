@IsTest
public with sharing class Test_OrderCloneUtility {
    @IsTest
    static void testCloneOrderWithFullRelationships() {
        // Step 1: Create test data
        Map<String, Object> testData = createTestData();
        orders__Order__c testOrder = (orders__Order__c)testData.get('testOrder');
        List<Product2> products = (List<Product2>)testData.get('products');
        List<orders__PriceBookLineItem__c> pricebookEntries = (List<orders__PriceBookLineItem__c>)testData.get('pricebookEntries');
        List<orders__OrderLineItem__c> orderLineItems = (List<orders__OrderLineItem__c>)testData.get('orderLineItems');
        List<orders__DeliveryLineItem__c> deliveryLineItems = (List<orders__DeliveryLineItem__c>)testData.get('deliveryLineItems');

        // Step 2: Execute cloning
        Test.startTest();
        OrderCloneUtility util = new OrderCloneUtility();
        Id clonedOrderId = util.cloneOrder(testOrder.Id);
        Test.stopTest();

        // Step 3: Assertions

        // Verify the cloned Order
        orders__Order__c clonedOrder = [SELECT Id, orders__SalesOrganizationId__c, orders__AccountId__c FROM orders__Order__c WHERE Id = :clonedOrderId];
        System.assertNotEquals(clonedOrder.Id, testOrder.Id, 'Cloned order should have a different ID');
        System.assertEquals(clonedOrder.orders__SalesOrganizationId__c, testOrder.orders__SalesOrganizationId__c, 'SalesOrganization should match the original');
        System.assertEquals(clonedOrder.orders__AccountId__c, testOrder.orders__AccountId__c, 'Account should match the original');

        // Verify the cloned Order Line Items
        List<orders__OrderLineItem__c> clonedOLIs = [
            SELECT Id, orders__OrderId__c, orders__Product2Id__c, orders__PriceBookLineItemId__c
            FROM orders__OrderLineItem__c
            WHERE orders__OrderId__c = :clonedOrderId
        ];
        System.assertEquals(3, clonedOLIs.size(), 'Cloned order should have the same number of Order Line Items as the original');
        for (Integer i = 0; i < clonedOLIs.size(); i++) {
            System.assertEquals(products[i].Id, clonedOLIs[i].orders__Product2Id__c, 'Product link should be preserved in cloned Order Line Items');
            System.assertEquals(pricebookEntries[i].Id, clonedOLIs[i].orders__PriceBookLineItemId__c, 'PriceBookLineItem link should be preserved in cloned Order Line Items');
        }

        // Verify the cloned Deliveries
        List<orders__Delivery__c> clonedDeliveries = [
            SELECT Id, orders__OrderId__c FROM orders__Delivery__c WHERE orders__OrderId__c = :clonedOrderId
        ];
        System.assertEquals(1, clonedDeliveries.size(), 'Cloned order should have the same number of Deliveries as the original');

        // Verify the cloned Delivery Line Items
        List<orders__DeliveryLineItem__c> clonedDLIs = [
            SELECT Id, orders__DeliveryId__c, orders__OrderLineItemId__c
            FROM orders__DeliveryLineItem__c
            WHERE orders__DeliveryId__c = :clonedDeliveries[0].Id
        ];
        System.assertEquals(3, clonedDLIs.size(), 'Cloned Delivery should have the same number of Delivery Line Items as the original');

        // Verify relationships in Delivery Line Items
        for (Integer i = 0; i < clonedDLIs.size(); i++) {
            System.assertEquals(clonedOLIs[i].Id, clonedDLIs[i].orders__OrderLineItemId__c, 'Delivery Line Item should point to the correct cloned Order Line Item');
        }
    }

    private static Map<String, Object> createTestData() {
        Map<String, Object> testData = new Map<String, Object>();

        orders__SalesOrganization__c salesOrg = new orders__SalesOrganization__c(orders__SalesPoint__c = 'Account');
        insert salesOrg;

        List<orders__OMSettings__c> settings = getSettings(salesOrg.Id);
        insert settings;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        orders__PriceBook__c priceBook = new orders__PriceBook__c(
            Name = 'Custom Price Book',
            orders__IsActive__c = true
        );
        insert priceBook;

        List<Product2> products = new List<Product2>();
        for (Integer i = 1; i <= 3; i++) {
            products.add(new Product2(Name = 'Test Product ' + i, IsActive = true));
        }
        insert products;

        List<orders__PriceBookLineItem__c> pricebookLineItems = new List<orders__PriceBookLineItem__c>();
        for (Product2 product : products) {
            pricebookLineItems.add(new orders__PriceBookLineItem__c(
                orders__PriceBookId__c = priceBook.Id,
                orders__Product2Id__c = product.Id,
                orders__ListPrice__c = 100 * Math.random(),
                orders__IsActive__c = true
            ));
        }
        insert pricebookLineItems;

        orders__Order__c testOrder = new orders__Order__c(
            orders__OrderType__c = 'Order',
            orders__SalesOrganizationId__c = salesOrg.Id,
            orders__AccountId__c = testAccount.Id
        );
        insert testOrder;

        List<orders__OrderLineItem__c> orderLineItems = new List<orders__OrderLineItem__c>();
        for (Integer i = 0; i < products.size(); i++) {
            orderLineItems.add(new orders__OrderLineItem__c(
                orders__OrderId__c = testOrder.Id,
                orders__Product2Id__c = products[i].Id,
                orders__PriceBookLineItemId__c = pricebookLineItems[i].Id,
                orders__Quantity__c = 1
            ));
        }
        insert orderLineItems;

        orders__Delivery__c testDelivery = new orders__Delivery__c(
            orders__OrderId__c = testOrder.Id,
            orders__DeliveryDate__c = Date.today()
        );
        insert testDelivery;

        List<orders__DeliveryLineItem__c> deliveryLineItems = new List<orders__DeliveryLineItem__c>();
        for (Integer i = 0; i < orderLineItems.size(); i++) {
            deliveryLineItems.add(new orders__DeliveryLineItem__c(
                orders__DeliveryId__c = testDelivery.Id,
                orders__OrderLineItemId__c = orderLineItems[i].Id,
                orders__Quantity__c = 1,
                orders__ListPrice__c = 100,
                orders__TotalPrice__c = 100
            ));
        }
        insert deliveryLineItems;

        testData.put('salesOrg', salesOrg);
        testData.put('testOrder', testOrder);
        testData.put('products', products);
        testData.put('pricebookEntries', pricebookLineItems);
        testData.put('orderLineItems', orderLineItems);
        testData.put('deliveryLineItems', deliveryLineItems);

        return testData;
    }

    private static List<orders__OMSettings__c> getSettings(Id salesOrgId) {
        List<SObject> settings = new List<SObject>();

        orders__OMSettings__c objectSetting = new orders__OMSettings__c();
        objectSetting.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('ObjectSetting').recordTypeId;
        objectSetting.orders__ProductObject__c = 'Product2';
        objectSetting.orders__ProductComponentObject__c = 'User';
        objectSetting.orders__AddressObject__c = 'Account';
        objectSetting.orders__SKUField__c = 'IsActive';
        settings.add(objectSetting);

        orders__OMSettings__c orderMapping = new orders__OMSettings__c();
        orderMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('OrderMapping').recordTypeId;
        orderMapping.orders__TotalPriceField__c = 'orders__TotalPrice__c';
        orderMapping.orders__TotalDiscountField__c = 'orders__TotalDiscount__c';
        settings.add(orderMapping);

        orders__OMSettings__c orderLineItemMapping = new orders__OMSettings__c();
        orderLineItemMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('OrderLineItemMapping').recordTypeId;
        orderLineItemMapping.orders__ListPriceField__c = 'orders__ListPrice__c';
        orderLineItemMapping.orders__UnitPriceField__c = 'orders__UnitPrice__c';
        orderLineItemMapping.orders__TotalPriceField__c = 'orders__TotalPrice__c';
        orderLineItemMapping.orders__TotalDiscountField__c = 'orders__TotalDiscount__c';
        orderLineItemMapping.orders__QuantityField__c = 'orders__Quantity__c';
        settings.add(orderLineItemMapping);

        orders__OMSettings__c deliveryLineItemMapping = new orders__OMSettings__c();
        deliveryLineItemMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('DeliveryLineItemMapping').recordTypeId;
        deliveryLineItemMapping.orders__UnitPriceField__c    = 'orders__UnitPrice__c';
        deliveryLineItemMapping.orders__ListPriceField__c    = 'orders__ListPrice__c';
        deliveryLineItemMapping.orders__TotalPriceField__c    = 'orders__TotalPrice__c';
        deliveryLineItemMapping.orders__TotalDiscountField__c    = 'orders__TotalDiscount__c';
        deliveryLineItemMapping.orders__QuantityField__c = 'orders__Quantity__c';
        settings.add(deliveryLineItemMapping);

        orders__OMSettings__c deliveryMapping = new orders__OMSettings__c();
        deliveryMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('DeliveryMapping').recordTypeId;
        deliveryMapping.orders__TotalPriceField__c = 'orders__TotalPrice__c';
        deliveryMapping.orders__TotalDiscountField__c = 'orders__TotalDiscount__c';
        settings.add(deliveryMapping);

        orders__OMSettings__c addressMapping = new orders__OMSettings__c();
        addressMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('AddressSetting').recordTypeId;
        addressMapping.orders__SalesOrganizationId__c = salesOrgId;
        addressMapping.orders__AddressField__c = 'Name';
        addressMapping.orders__SOQLFilter__c = 'WHERE Id != NULL';
        settings.add(addressMapping);

        orders__OMSettings__c layoutDelivery = new orders__OMSettings__c();
        layoutDelivery.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('LayoutSetting').recordTypeId;
        layoutDelivery.orders__FieldsToDisplay__c = 'Name';
        layoutDelivery.orders__Object__c = 'orders__Delivery__c';
        settings.add(layoutDelivery);

        orders__OMSettings__c sdkSettings = new orders__OMSettings__c();
        sdkSettings.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('SDKSetting').recordTypeId;
        sdkSettings.orders__Platform__c = 'Salesforce';
        sdkSettings.orders__SDKType__c = 'updateDataOnAfterOrderLineItemUpsert';
        sdkSettings.orders__Version__c = 'v1';
        sdkSettings.orders__Parameters__c = '[{"objectName":"orders__Order__c","fields":["orders__Accountid__c","orders__TotalDiscount__c","orders__TotalPrice__c"]},{"objectName":"orders__Delivery__c","fields":["orders__TotalDiscount__c","orders__TotalPrice__c"]},{"objectName":"orders__OrderLineItem__c","fields":["$.unitPrice","orders__TotalDiscount__c","orders__ListPrice__c","orders__First__c","orders__Last__c","orders__TotalPrice__c"]},{"objectName":"orders__DeliveryLineItem__c","fields":["orders__listprice__c","$.unitPrice","orders__TotalDiscount__c","orders__TotalPrice__c"]}]';
        sdkSettings.orders__Implementation__c = 'SDKCalculateDiscount.setUnitPriceAsListPrice';
        settings.add(sdkSettings);

        orders__OMSettings__c layoutOrderLineItem = new orders__OMSettings__c();
        layoutOrderLineItem.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('LayoutSetting').recordTypeId;
        layoutOrderLineItem.orders__FieldsToDisplay__c = 'orders__ListPrice__c,orders__UnitPrice__c,orders__TotalPrice__c,orders__TotalDiscount__c';
        layoutOrderLineItem.orders__Object__c = 'orders__OrderLineItem__c';
        layoutOrderLineItem.orders__DisplayedFieldWidth__c = '50,30,20,0,15,5';
        settings.add(layoutOrderLineItem);

        return settings;
    }
}
