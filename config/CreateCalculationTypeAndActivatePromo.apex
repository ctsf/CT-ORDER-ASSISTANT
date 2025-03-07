// Step 1: Retrieve the RecordType ID for 'Condition'
Id conditionRecordTypeId = [SELECT Id 
                            FROM RecordType 
                            WHERE DeveloperName = 'Condition' 
                              AND SObjectType = 'orders__CalculationType__c'
                            LIMIT 1].Id;

// Step 2: Create the Calculation Type record
orders__CalculationType__c calculationType = new orders__CalculationType__c(
    RecordTypeId = conditionRecordTypeId,
    Name = 'Default Discount',
    orders__ExternalId__c = 'Discount_Default',
    orders__CalculationMethod__c = 'Decrease',
    orders__UnitOfMeasure__c = 'Percent',
    orders__ConditionFieldsUpdateType__c = 'RealTime',
    orders__ApplyConditionType__c = 'First',
    orders__LevelBasedOn__c = 'OrderLineItems'
);

try {
    insert calculationType;
    System.debug('Calculation Type record created with Id: ' + calculationType.Id);
} catch (Exception e) {
    System.debug('Error inserting Calculation Type: ' + e.getMessage());
}

// Step 3: Update all Promotions
try {
    // Fetch all promotions
    List<orders__Promotion__c> promotions = [
        SELECT Id, 
               orders__CalculationTypeId__c, 
               orders__OrderStartDate__c, 
               orders__OrderEndDate__c, 
               orders__DeliveryStartDate__c, 
               orders__DeliveryEndDate__c, 
               orders__Status__c, 
               orders__IsActive__c 
        FROM orders__Promotion__c
    ];

    if (promotions.isEmpty()) {
        System.debug('No promotions found to update.');
    } else {
        for (orders__Promotion__c promo : promotions) {
            // Link the Calculation Type to each promotion
            promo.orders__CalculationTypeId__c = calculationType.Id;

            // Shift dates to make them current (e.g., start today and end in 1 year)
            promo.orders__OrderStartDate__c = Date.today();
            promo.orders__OrderEndDate__c = Date.today().addYears(1);
            promo.orders__DeliveryStartDate__c = Date.today();
            promo.orders__DeliveryEndDate__c = Date.today().addYears(1);

            // Set status to Active
            promo.orders__Status__c = 'Active';
            promo.orders__IsActive__c = true;
        }

        // Update all promotions
        update promotions;
        System.debug(promotions.size() + ' promotions updated successfully.');
    }
} catch (Exception e) {
    System.debug('Error updating promotions: ' + e.getMessage());
}

System.debug('Process completed.');