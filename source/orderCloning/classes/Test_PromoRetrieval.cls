@IsTest
public class Test_PromoRetrieval {
    @IsTest
    static void testRetrieveAssignedPromotions() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test Promotion
        // TODO: fix test
        orders__Promotion__c promotion = new orders__Promotion__c(
            Name = 'Test Promotion',
            orders__ExternalId__c = 'Test_Promo',
            orders__OrderStartDate__c = Date.today().addDays(-10),
            orders__OrderEndDate__c = Date.today().addDays(10),
            orders__DeliveryStartDate__c = Date.today().addDays(-10), 
            orders__DeliveryEndDate__c = Date.today().addDays(10),   
            orders__IsActive__c = true
        );
        insert promotion;

        // Assign the Promotion to the Account
        orders__PromotionAssignment__c promoAssignment = new orders__PromotionAssignment__c(
            orders__AccountId__c = testAccount.Id,
            orders__PromotionId__c = promotion.Id
        );
        insert promoAssignment;

        // Build the Request
        PromoRetrieval.PromotionRetrievalRequest request = new PromoRetrieval.PromotionRetrievalRequest();
        request.accountId = testAccount.Id;

        // Execute the method
        List<PromoRetrieval.PromotionRetrievalResponse> responses = PromoRetrieval.retrievePromotions(new List<PromoRetrieval.PromotionRetrievalRequest>{ request });

        // Verify the results
        System.assertEquals(1, responses.size(), 'Expected exactly one response.');
        PromoRetrieval.PromotionRetrievalResponse response = responses[0];
        System.assertEquals('SUCCESS', response.status, 'Expected the status to be SUCCESS.');
        System.assertEquals('Promotions retrieved successfully.', response.message, 'Expected a success message.');
        System.assertEquals(1, response.promotions.size(), 'Expected exactly one promotion to be retrieved.');
        System.assertEquals(promotion.Id, response.promotions[0].Id, 'Expected the promotion ID to match the assigned promotion.');
    }


    @IsTest
    static void testNoAssignedPromotions() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account 2');
        insert testAccount;

        // Build the Request
        PromoRetrieval.PromotionRetrievalRequest request = new PromoRetrieval.PromotionRetrievalRequest();
        request.accountId = testAccount.Id;

        // Execute the method
        List<PromoRetrieval.PromotionRetrievalResponse> responses = PromoRetrieval.retrievePromotions(new List<PromoRetrieval.PromotionRetrievalRequest>{ request });

        // Verify the results
        System.assertEquals(1, responses.size(), 'Expected exactly one response.');
        PromoRetrieval.PromotionRetrievalResponse response = responses[0];
        System.assertEquals('SUCCESS', response.status, 'Expected the status to be SUCCESS.');
        System.assertEquals('No promotions assigned to the given account.', response.message, 'Expected a message indicating no promotions were found.');
        System.assertEquals(0, response.promotions.size(), 'Expected no promotions to be retrieved.');
    }

    @IsTest
    static void testRetrievePromotionsError() {
        // Build the Request without Account ID
        PromoRetrieval.PromotionRetrievalRequest request = new PromoRetrieval.PromotionRetrievalRequest();
        request.accountId = null;

        // Execute the method
        List<PromoRetrieval.PromotionRetrievalResponse> responses = PromoRetrieval.retrievePromotions(new List<PromoRetrieval.PromotionRetrievalRequest>{ request });

        // Verify the results
        System.assertEquals(1, responses.size(), 'Expected exactly one response.');
        PromoRetrieval.PromotionRetrievalResponse response = responses[0];
        System.assertEquals('ERROR', response.status, 'Expected the status to be ERROR.');
        System.assertEquals('Account ID must be provided.', response.message, 'Expected a message indicating the account ID was missing.');
    }
}