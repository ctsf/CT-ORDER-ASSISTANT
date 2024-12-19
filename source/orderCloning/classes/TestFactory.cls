@IsTest
public with sharing class TestFactory {

    private static final Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();

    public static Map<String, Object> createTestData() {
        Map<String, Object> testData = new Map<String, Object>();

        String salesOrgObjectName = 'orders__SalesOrganization__c';
        SObject salesOrg = GLOBAL_DESCRIBE.get(salesOrgObjectName).newSObject(null, true);
        salesOrg.put('orders__SalesPoint__c', 'Account');
        insert salesOrg;

        List<SObject> settings = getSettings((Id)salesOrg.get('Id'));
        insert settings;

        String accountObjectName = 'Account';
        SObject testAccount = GLOBAL_DESCRIBE.get(accountObjectName).newSObject(null, true);
        testAccount.put('Name', 'Test Account');
        insert testAccount;

        String priceBookObjectName = 'orders__PriceBook__c';
        SObject priceBook = GLOBAL_DESCRIBE.get(priceBookObjectName).newSObject(null, true);
        priceBook.put('Name', 'Custom Price Book');
        priceBook.put('orders__IsActive__c', true);
        insert priceBook;

        List<SObject> products = new List<SObject>();
        List<SObject> pricebookLineItems = new List<SObject>();
        String productObjectName = 'Product2';
        String priceBookLineItemObjectName = 'orders__PriceBookLineItem__c';

        for (Integer i = 1; i <= 3; i++) {
            SObject product = GLOBAL_DESCRIBE.get(productObjectName).newSObject(null, true);
            product.put('Name', 'Test Product ' + i);
            product.put('IsActive', true);
            products.add(product);
        }
        insert products;

        for (SObject product : products) {
            SObject pricebookLineItem = GLOBAL_DESCRIBE.get(priceBookLineItemObjectName).newSObject(null, true);
            pricebookLineItem.put('orders__PriceBookId__c', priceBook.get('Id'));
            pricebookLineItem.put('orders__Product2Id__c', product.get('Id'));
            pricebookLineItem.put('orders__ListPrice__c', 100);
            pricebookLineItem.put('orders__IsActive__c', true);
            pricebookLineItems.add(pricebookLineItem);
        }
        insert pricebookLineItems;

        String orderObjectName = 'orders__Order__c';
        SObject testOrder = GLOBAL_DESCRIBE.get(orderObjectName).newSObject(null, true);
        testOrder.put('orders__OrderType__c', 'Order');
        testOrder.put('orders__SalesOrganizationId__c', salesOrg.get('Id'));
        testOrder.put('orders__AccountId__c', testAccount.get('Id'));
        testOrder.put('orders__PriceBookId__c', priceBook.get('Id'));
        insert testOrder;

        String orderLineItemObjectName = 'orders__OrderLineItem__c';
        List<SObject> orderLineItems = new List<SObject>();
        for (Integer i = 0; i < products.size(); i++) {
            SObject orderLineItem = GLOBAL_DESCRIBE.get(orderLineItemObjectName).newSObject(null, true);
            orderLineItem.put('orders__OrderId__c', testOrder.get('Id'));
            orderLineItem.put('orders__Product2Id__c', products[i].get('Id'));
            orderLineItem.put('orders__PriceBookLineItemId__c', pricebookLineItems[i].get('Id'));
            orderLineItem.put('orders__Quantity__c', 1);
            orderLineItems.add(orderLineItem);
        }
        insert orderLineItems;

        String deliveryObjectName = 'orders__Delivery__c';
        SObject testDelivery = GLOBAL_DESCRIBE.get(deliveryObjectName).newSObject(null, true);
        testDelivery.put('orders__OrderId__c', testOrder.get('Id'));
        testDelivery.put('orders__DeliveryDate__c', Date.today());
        insert testDelivery;

        String deliveryLineItemObjectName = 'orders__DeliveryLineItem__c';
        List<SObject> deliveryLineItems = new List<SObject>();
        for (Integer i = 0; i < orderLineItems.size(); i++) {
            SObject deliveryLineItem = GLOBAL_DESCRIBE.get(deliveryLineItemObjectName).newSObject(null, true);
            deliveryLineItem.put('orders__DeliveryId__c', testDelivery.get('Id'));
            deliveryLineItem.put('orders__OrderLineItemId__c', orderLineItems[i].get('Id'));
            deliveryLineItem.put('orders__Quantity__c', 1);
            deliveryLineItem.put('orders__ListPrice__c', 100);
            deliveryLineItem.put('orders__TotalPrice__c', 100);
            deliveryLineItems.add(deliveryLineItem);
        }
        insert deliveryLineItems;

        testData.put('testAccount', testAccount);
        testData.put('testOrder', testOrder);

        return testData;
    }

    public static List<SObject> getSettings(Id salesOrgId) {
        List<SObject> settings = new List<SObject>();
        String omSettingsObjectName = 'orders__OMSettings__c';
    
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Metadata.getDescribe(omSettingsObjectName).getRecordTypeInfosByDeveloperName();
    
        SObject objectSetting = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        objectSetting.put('RecordTypeId', recordTypeInfoMap.get('ObjectSetting').getRecordTypeId());
        objectSetting.put('orders__ProductObject__c', 'Product2');
        objectSetting.put('orders__ProductComponentObject__c', 'User');
        objectSetting.put('orders__AddressObject__c', 'Account');
        objectSetting.put('orders__SKUField__c', 'IsActive');
        settings.add(objectSetting);
    
        SObject orderMapping = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        orderMapping.put('RecordTypeId', recordTypeInfoMap.get('OrderMapping').getRecordTypeId());
        orderMapping.put('orders__TotalPriceField__c', 'orders__TotalPrice__c');
        orderMapping.put('orders__TotalDiscountField__c', 'orders__TotalDiscount__c');
        settings.add(orderMapping);
    
        SObject orderLineItemMapping = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        orderLineItemMapping.put('RecordTypeId', recordTypeInfoMap.get('OrderLineItemMapping').getRecordTypeId());
        orderLineItemMapping.put('orders__ListPriceField__c', 'orders__ListPrice__c');
        orderLineItemMapping.put('orders__UnitPriceField__c', 'orders__UnitPrice__c');
        orderLineItemMapping.put('orders__TotalPriceField__c', 'orders__TotalPrice__c');
        orderLineItemMapping.put('orders__TotalDiscountField__c', 'orders__TotalDiscount__c');
        orderLineItemMapping.put('orders__QuantityField__c', 'orders__Quantity__c');
        settings.add(orderLineItemMapping);
    
        SObject deliveryLineItemMapping = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        deliveryLineItemMapping.put('RecordTypeId', recordTypeInfoMap.get('DeliveryLineItemMapping').getRecordTypeId());
        deliveryLineItemMapping.put('orders__UnitPriceField__c', 'orders__UnitPrice__c');
        deliveryLineItemMapping.put('orders__ListPriceField__c', 'orders__ListPrice__c');
        deliveryLineItemMapping.put('orders__TotalPriceField__c', 'orders__TotalPrice__c');
        deliveryLineItemMapping.put('orders__TotalDiscountField__c', 'orders__TotalDiscount__c');
        deliveryLineItemMapping.put('orders__QuantityField__c', 'orders__Quantity__c');
        settings.add(deliveryLineItemMapping);
    
        SObject deliveryMapping = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        deliveryMapping.put('RecordTypeId', recordTypeInfoMap.get('DeliveryMapping').getRecordTypeId());
        deliveryMapping.put('orders__TotalPriceField__c', 'orders__TotalPrice__c');
        deliveryMapping.put('orders__TotalDiscountField__c', 'orders__TotalDiscount__c');
        settings.add(deliveryMapping);
    
        SObject addressMapping = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        addressMapping.put('RecordTypeId', recordTypeInfoMap.get('AddressSetting').getRecordTypeId());
        addressMapping.put('orders__SalesOrganizationId__c', salesOrgId);
        addressMapping.put('orders__AddressField__c', 'Name');
        addressMapping.put('orders__SOQLFilter__c', 'WHERE Id != NULL');
        settings.add(addressMapping);
    
        SObject layoutDelivery = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        layoutDelivery.put('RecordTypeId', recordTypeInfoMap.get('LayoutSetting').getRecordTypeId());
        layoutDelivery.put('orders__FieldsToDisplay__c', 'Name');
        layoutDelivery.put('orders__Object__c', 'orders__Delivery__c');
        settings.add(layoutDelivery);
    
        SObject layoutOrderLineItem = GLOBAL_DESCRIBE.get(omSettingsObjectName).newSObject(null, true);
        layoutOrderLineItem.put('RecordTypeId', recordTypeInfoMap.get('LayoutSetting').getRecordTypeId());
        layoutOrderLineItem.put('orders__Object__c', 'orders__OrderLineItem__c');
        layoutOrderLineItem.put('orders__FieldsToDisplay__c', 'orders__ListPrice__c,orders__UnitPrice__c,orders__TotalPrice__c,orders__TotalDiscount__c');
        layoutOrderLineItem.put('orders__DisplayedFieldWidth__c', '50,30,20,0,15,5');
        settings.add(layoutOrderLineItem);
    
        return settings;
    }
    
}