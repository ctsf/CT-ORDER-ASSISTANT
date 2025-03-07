// Promotion Line Items
List<SObject> products = Database.query(
    'SELECT Id, orders__ExternalId__c FROM orders__Product2__c'
);
List<SObject> promotions = Database.query(
    'SELECT Id, orders__ExternalId__c FROM orders__Promotion__c'
);
List<SObject> promotionLineItems = new List<SObject>();

if (!products.isEmpty() && !promotions.isEmpty()) {
    Integer productCount = products.size();
    Integer promoCount = promotions.size();

    for (Integer i = 0; i < productCount; i++) {
        SObject product = products[i];
        SObject promo = promotions[i % promoCount];

        SObject lineItem = Schema.getGlobalDescribe().get('orders__PromotionLineItem__c').newSObject(null, true);
        lineItem.put('orders__PromotionId__c', promo.get('Id'));
        lineItem.put('orders__Product2Id__c', product.get('Id'));
        lineItem.put('orders__IsActive__c', true);
        lineItem.put('orders__IsExcludeFromDiscount__c', false);
        lineItem.put('orders__IsRequired__c', false);
        lineItem.put('orders__IsUseForDiscount__c', true);
        lineItem.put('orders__RequiredMinForDiscount__c', 10);
        promotionLineItems.add(lineItem);
    }
    Database.insert(promotionLineItems);
}

// Promotion Assignments
List<SObject> accounts = Database.query(
    'SELECT Id, Name FROM Account'
);
List<SObject> promotionAssignments = new List<SObject>();

if (!accounts.isEmpty() && !promotions.isEmpty()) {
    Integer promoCount = promotions.size();
    Integer accountCount = accounts.size();

    for (Integer i = 0; i < promoCount; i++) {
        SObject promo = promotions[i];
        SObject account = accounts[i % accountCount];

        SObject assignment = Schema.getGlobalDescribe().get('orders__PromotionAssignment__c').newSObject(null, true);
        assignment.put('orders__PromotionId__c', promo.get('Id'));
        assignment.put('orders__AccountId__c', account.get('Id'));
        assignment.put('orders__IsActive__c', true);
        promotionAssignments.add(assignment);
    }
    Database.insert(promotionAssignments);
}

// Promotions
for (SObject promo : promotions) {
    promo.put('orders__OrderStartDate__c', Date.today().addDays(-7));
    promo.put('orders__OrderEndDate__c', Date.today().addDays(30));  
    promo.put('orders__DeliveryStartDate__c', Date.today().addDays(-7));
    promo.put('orders__DeliveryEndDate__c', Date.today().addDays(30));
    promo.put('orders__LongTermDiscountStartDate__c', Date.today().addDays(-7));
    promo.put('orders__LongTermDiscountEndDate__c', Date.today().addDays(30));
    promo.put('orders__Status__c', 'Active'); /
    promo.put('orders__IsActive__c', true); 
}
Database.update(promotions);