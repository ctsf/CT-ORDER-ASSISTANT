@IsTest
public class Test_OpportunityStageAnalysis {

    @TestSetup
    static void setup() {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 1; i <= 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30)
            );
            opportunities.add(opp);
        }
        insert opportunities;

        for (Opportunity opp : [SELECT Id FROM Opportunity]) {
            opp.StageName = 'Qualification Updated'; 
        }
        update opportunities;

        for (Opportunity opp : [SELECT Id, LastModifiedDate FROM Opportunity]) {
            opp.StageName = 'Qualification'; 
            System.debug('Opp is ' + opp.LastModifiedDate);
        }
        update opportunities;

    }

    @IsTest
    static void testAnalyzeOpportunities_InvalidRequest() {
        OpportunityStageAnalysis.StageAnalysisRequest request = new OpportunityStageAnalysis.StageAnalysisRequest();
        request.StageName = null;
        request.MinDaysInStage = -1;

        List<OpportunityStageAnalysis.StageAnalysisRequest> requests = new List<OpportunityStageAnalysis.StageAnalysisRequest>{request};

        Test.startTest();
        try {
            OpportunityStageAnalysis.analyzeOpportunities(requests);
            System.assert(false, 'Expected IllegalArgumentException to be thrown');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'IllegalArgumentException was correctly thrown');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAnalyzeOpportunities_NoOpportunitiesFound() {
        OpportunityStageAnalysis.StageAnalysisRequest request = new OpportunityStageAnalysis.StageAnalysisRequest();
        request.StageName = 'Nonexistent Stage';
        request.MinDaysInStage = 10;

        List<OpportunityStageAnalysis.StageAnalysisRequest> requests = new List<OpportunityStageAnalysis.StageAnalysisRequest>{request};

        Test.startTest();
        List<OpportunityStageAnalysis.StageAnalysisResponse> responses = OpportunityStageAnalysis.analyzeOpportunities(requests);
        Test.stopTest();

        System.assertEquals(0, responses.size(), 'Expected no opportunities for a non-matching stage');
    }

    @IsTest
    static void testAnalyzeOpportunities_EmptyRequest() {
        List<OpportunityStageAnalysis.StageAnalysisRequest> requests = new List<OpportunityStageAnalysis.StageAnalysisRequest>();

        Test.startTest();
        try {
            OpportunityStageAnalysis.analyzeOpportunities(requests);
            System.assert(false, 'Expected IllegalArgumentException to be thrown for empty request');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Requests cannot be null or empty.', e.getMessage(), 'Correct exception message expected');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAnalyzeOpportunities_ResponsesPopulated() {
        OpportunityStageAnalysis.StageAnalysisRequest request = new OpportunityStageAnalysis.StageAnalysisRequest();
        request.StageName = 'Qualification';
        request.MinDaysInStage = 0;

        List<OpportunityStageAnalysis.StageAnalysisRequest> requests = new List<OpportunityStageAnalysis.StageAnalysisRequest>{request};

        Test.startTest();
        List<OpportunityStageAnalysis.StageAnalysisResponse> responses = OpportunityStageAnalysis.analyzeOpportunities(requests);
        Test.stopTest();

        System.assertEquals(5, responses.size(), 'Expected 5 responses matching the criteria');
        for (OpportunityStageAnalysis.StageAnalysisResponse response : responses) {
            System.assertNotEquals(null, response.OpportunityId, 'OpportunityId should not be null');
            System.assertNotEquals(null, response.OpportunityName, 'OpportunityName should not be null');
            System.assertNotEquals(null, response.StageName, 'StageName should not be null');
            System.assertNotEquals(null, response.LastModifiedDate, 'LastModifiedDate should not be null');
        }
    }
}
