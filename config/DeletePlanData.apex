/**
 * Deletion script for custom objects
 * Deletes objects in the specified order: bottom to top.
 */

List<Database.DeleteResult> results;

// 1. Delete Promotion Assignments
try {
  List<orders__PromotionAssignment__c> promoAssignments = [
    SELECT Id
    FROM orders__PromotionAssignment__c
  ];
  if (!promoAssignments.isEmpty()) {
    results = Database.delete(promoAssignments, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Promotion Assignments: ' + e.getMessage());
}

// 2. Delete Promotion Line Items
try {
  List<orders__PromotionLineItem__c> promoLineItems = [
    SELECT Id
    FROM orders__PromotionLineItem__c
  ];
  if (!promoLineItems.isEmpty()) {
    results = Database.delete(promoLineItems, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Promotion Line Items: ' + e.getMessage());
}

// 3. Delete Promotions
try {
  List<orders__Promotion__c> promotions = [SELECT Id FROM orders__Promotion__c];
  if (!promotions.isEmpty()) {
    results = Database.delete(promotions, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Promotions: ' + e.getMessage());
}

// 4. Delete Catalog Assignments
try {
  List<orders__CatalogAssignment__c> catalogAssignments = [
    SELECT Id
    FROM orders__CatalogAssignment__c
  ];
  if (!catalogAssignments.isEmpty()) {
    results = Database.delete(catalogAssignments, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Catalog Assignments: ' + e.getMessage());
}

// 5. Delete Catalog Line Items
try {
  List<orders__CatalogLineItem__c> catalogLineItems = [
    SELECT Id
    FROM orders__CatalogLineItem__c
  ];
  if (!catalogLineItems.isEmpty()) {
    results = Database.delete(catalogLineItems, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Catalog Line Items: ' + e.getMessage());
}

// 6. Delete Catalogs
try {
  List<orders__Catalog__c> catalogs = [SELECT Id FROM orders__Catalog__c];
  if (!catalogs.isEmpty()) {
    results = Database.delete(catalogs, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Catalogs: ' + e.getMessage());
}

// 7. Delete Price Book Line Items
try {
  List<orders__PriceBookLineItem__c> priceBookLineItems = [
    SELECT Id
    FROM orders__PriceBookLineItem__c
  ];
  if (!priceBookLineItems.isEmpty()) {
    results = Database.delete(priceBookLineItems, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Price Book Line Items: ' + e.getMessage());
}

// 8. Delete Price Books
try {
  List<orders__PriceBook__c> priceBooks = [SELECT Id FROM orders__PriceBook__c];
  if (!priceBooks.isEmpty()) {
    results = Database.delete(priceBooks, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Price Books: ' + e.getMessage());
}

// 9. Delete Products
try {
  List<Product2> products = [SELECT Id FROM Product2];
  if (!products.isEmpty()) {
    results = Database.delete(products, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Products: ' + e.getMessage());
}

// 10. Delete Accounts
try {
  List<Account> accounts = [SELECT Id FROM Account];
  if (!accounts.isEmpty()) {
    results = Database.delete(accounts, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Accounts: ' + e.getMessage());
}

// 11. Delete Sales Organizations
try {
  List<orders__SalesOrganization__c> salesOrganizations = [
    SELECT Id
    FROM orders__SalesOrganization__c
  ];
  if (!salesOrganizations.isEmpty()) {
    results = Database.delete(salesOrganizations, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Sales Organizations: ' + e.getMessage());
}

// 12. Delete Pricing Procedure
try {
  List<orders__PricingProcedure__c> pricingProcedure = [
    SELECT Id
    FROM orders__PricingProcedure__c
  ];
  if (!pricingProcedure.isEmpty()) {
    results = Database.delete(pricingProcedure, false);
  }
} catch (Exception e) {
  System.debug('Error deleting Pricing Procedure: ' + e.getMessage());
}

System.debug('Deletion process completed.');
