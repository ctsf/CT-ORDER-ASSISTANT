@IsTest
public with sharing class TestFactory {
    public static Map<String, Object> createTestData() {
        Map<String, Object> testData = new Map<String, Object>();

        // Sales Organization
        orders__SalesOrganization__c salesOrg = new orders__SalesOrganization__c(orders__SalesPoint__c = 'Account');
        insert salesOrg;

        List<orders__OMSettings__c> settings = getSettings(salesOrg.Id);
        insert settings;

        // Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Price Book
        orders__PriceBook__c priceBook = new orders__PriceBook__c(
            Name = 'Custom Price Book',
            orders__IsActive__c = true
        );
        insert priceBook;

        // Products and Price Book Line Items
        List<Product2> products = new List<Product2>();
        List<orders__PriceBookLineItem__c> pricebookLineItems = new List<orders__PriceBookLineItem__c>();

        for (Integer i = 1; i <= 3; i++) {
            Product2 product = new Product2(Name = 'Test Product ' + i, IsActive = true);
            products.add(product);
        }
        insert products;

        for (Product2 product : products) {
            pricebookLineItems.add(new orders__PriceBookLineItem__c(
                orders__PriceBookId__c = priceBook.Id,
                orders__Product2Id__c = product.Id,
                orders__ListPrice__c = 100,
                orders__IsActive__c = true
            ));
        }
        insert pricebookLineItems;

        // Order
        orders__Order__c testOrder = new orders__Order__c(
            orders__OrderType__c = 'Order',
            orders__SalesOrganizationId__c = salesOrg.Id,
            orders__AccountId__c = testAccount.Id,
            orders__PriceBookId__c = priceBook.Id
        );
        insert testOrder;

        // Order Line Items
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

        // Deliveries
        orders__Delivery__c testDelivery = new orders__Delivery__c(
            orders__OrderId__c = testOrder.Id,
            orders__DeliveryDate__c = Date.today()
        );
        insert testDelivery;

        // Delivery Line Items
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

        testData.put('testAccount', testAccount);
        testData.put('testOrder', testOrder);

        return testData;
    }

    public static List<orders__OMSettings__c> getSettings(Id salesOrgId) {
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

        orders__OMSettings__c layoutOrderLineItem = new orders__OMSettings__c();
        layoutOrderLineItem.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('LayoutSetting').recordTypeId;
        layoutOrderLineItem.orders__FieldsToDisplay__c = 'orders__ListPrice__c,orders__UnitPrice__c,orders__TotalPrice__c,orders__TotalDiscount__c';
        layoutOrderLineItem.orders__Object__c = 'orders__OrderLineItem__c';
        layoutOrderLineItem.orders__DisplayedFieldWidth__c = '50,30,20,0,15,5';
        settings.add(layoutOrderLineItem);

        return settings;
    }
}