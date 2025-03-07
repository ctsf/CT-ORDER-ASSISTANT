List<orders__OMSettings__c> SettingsToCreate = new List<orders__OMSettings__c>();

orders__OMSettings__c ObjectSetting = new orders__OMSettings__c();
orders__OMSettings__c OrderMapping = new orders__OMSettings__c();
orders__OMSettings__c DeliveryMapping = new orders__OMSettings__c();
orders__OMSettings__c OrderLineItemMapping = new orders__OMSettings__c();
orders__OMSettings__c DeliveryLineItemMapping = new orders__OMSettings__c();
orders__OMSettings__c AddressSetting = new orders__OMSettings__c();
orders__OMSettings__c OrderLineItemLayout = new orders__OMSettings__c();
orders__OMSettings__c PromotionAssignmentLayout = new orders__OMSettings__c();
orders__OMSettings__c CatalogLineItemLayout = new orders__OMSettings__c();
orders__OMSettings__c PromotionLineItemLayout = new orders__OMSettings__c();
orders__OMSettings__c CatalogAssignmentLayout = new orders__OMSettings__c();


if (Schema.SObjectType.orders__OMSettings__c.fields.orders__AddressField__c.isCreateable()) {
    AddressSetting.orders__AddressField__c = 'ShippingStreet';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__AddressObject__c.isCreateable()) {
    ObjectSetting.orders__AddressObject__c = 'Account';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__FieldsToDisplay__c.isCreateable()) {
    OrderLineItemLayout.orders__FieldsToDisplay__c = 'orders__ListPrice__c,orders__UnitPrice__c,orders__TotalPrice__c';
    PromotionAssignmentLayout.orders__FieldsToDisplay__c = 'orders__AccountId__c';
    CatalogLineItemLayout.orders__FieldsToDisplay__c = 'orders__Product2Id__c';
    PromotionLineItemLayout.orders__FieldsToDisplay__c = 'orders__Product2Id__c,orders__IsUseForDiscount__c,orders__IsExcludeFromDiscount__c';
    CatalogAssignmentLayout.orders__FieldsToDisplay__c = 'orders__AccountId__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__ListPriceField__c.isCreateable()) {
    OrderLineItemMapping.orders__ListPriceField__c = 'orders__ListPrice__c';
    DeliveryLineItemMapping.orders__ListPriceField__c = 'orders__ListPrice__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__Object__c.isCreateable()) {
    OrderLineItemLayout.orders__Object__c = 'orders__OrderLineItem__c';
    PromotionAssignmentLayout.orders__Object__c = 'orders__PromotionAssignment__c';
    CatalogLineItemLayout.orders__Object__c = 'orders__CatalogLineItem__c';
    PromotionLineItemLayout.orders__Object__c = 'orders__PromotionLineItem__c';
    CatalogAssignmentLayout.orders__Object__c = 'orders__CatalogAssignment__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__ParentObject__c.isCreateable()) {
    OrderLineItemLayout.orders__ParentObject__c = 'orders__Order__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__ProductObject__c.isCreateable()) {
    ObjectSetting.orders__ProductObject__c = 'Product2';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__QuantityField__c.isCreateable()) {
    OrderLineItemMapping.orders__QuantityField__c = 'orders__Quantity__c';
    DeliveryLineItemMapping.orders__QuantityField__c = 'orders__Quantity__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__SKUField__c.isCreateable()) {
    ObjectSetting.orders__SKUField__c = 'orders__IsSKU__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__TotalDiscountField__c.isCreateable()) {
    OrderMapping.orders__TotalDiscountField__c = 'orders__TotalDiscount__c';
    DeliveryMapping.orders__TotalDiscountField__c = 'orders__TotalDiscount__c';
    OrderLineItemMapping.orders__TotalDiscountField__c = 'orders__TotalDiscount__c';
    DeliveryLineItemMapping.orders__TotalDiscountField__c = 'orders__TotalDiscount__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__TotalPriceField__c.isCreateable()) {
    OrderMapping.orders__TotalPriceField__c = 'orders__TotalPrice__c';
    DeliveryMapping.orders__TotalPriceField__c = 'orders__TotalPrice__c';
    OrderLineItemMapping.orders__TotalPriceField__c = 'orders__TotalPrice__c';
    DeliveryLineItemMapping.orders__TotalPriceField__c = 'orders__TotalPrice__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.orders__UnitPriceField__c.isCreateable()) {
    OrderLineItemMapping.orders__UnitPriceField__c = 'orders__UnitPrice__c';
    DeliveryLineItemMapping.orders__UnitPriceField__c = 'orders__UnitPrice__c';
}

if (Schema.SObjectType.orders__OMSettings__c.fields.RecordTypeId.isCreateable()) {
    ObjectSetting.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('ObjectSetting')
        .recordTypeId;
    OrderMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('OrderMapping')
        .recordTypeId;
    DeliveryMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'DeliveryMapping'
        )
        .recordTypeId;
    OrderLineItemMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'OrderLineItemMapping'
        )
        .recordTypeId;
    DeliveryLineItemMapping.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'DeliveryLineItemMapping'
        )
        .recordTypeId;
    AddressSetting.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get('AddressSetting')
        .recordTypeId;
    OrderLineItemLayout.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'LayoutSetting'
        )
        .recordTypeId;
    PromotionAssignmentLayout.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'LayoutSetting'
        )
        .recordTypeId;
    CatalogLineItemLayout.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'LayoutSetting'
        )
        .recordTypeId;
    PromotionLineItemLayout.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'LayoutSetting'
        )
        .recordTypeId;
    CatalogAssignmentLayout.RecordTypeId = Schema.SObjectType.orders__OMSettings__c.recordTypeInfosByDeveloperName.get(
            'LayoutSetting'
        )
        .recordTypeId;
}

SettingsToCreate.add(ObjectSetting);
SettingsToCreate.add(OrderMapping);
SettingsToCreate.add(DeliveryMapping);
SettingsToCreate.add(OrderLineItemMapping);
SettingsToCreate.add(DeliveryLineItemMapping);
SettingsToCreate.add(AddressSetting);
SettingsToCreate.add(OrderLineItemLayout);
SettingsToCreate.add(PromotionAssignmentLayout);
SettingsToCreate.add(CatalogLineItemLayout);
SettingsToCreate.add(PromotionLineItemLayout);
SettingsToCreate.add(CatalogAssignmentLayout);

if (Schema.SObjectType.orders__OMSettings__c.isCreateable()) {
    insert SettingsToCreate;
}
