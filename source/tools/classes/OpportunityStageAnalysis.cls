public with sharing class OpportunityStageAnalysis {

    @InvocableMethod(label='Analyze Opportunities by Stage Duration' description='Finds opportunities that have been in the same stage for a specified number of days or more')
    public static List<StageAnalysisResponse> analyzeOpportunities(List<StageAnalysisRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access the Opportunity object.');
        }

        List<StageAnalysisResponse> responses = new List<StageAnalysisResponse>();

        for (StageAnalysisRequest request : requests) {
            if (String.isBlank(request.StageName) || request.MinDaysInStage == null || request.MinDaysInStage < 0) {
                throw new IllegalArgumentException('StageName and MinDaysInStage must be provided and valid.');
            }

            if (!Schema.sObjectType.Opportunity.fields.StageName.isAccessible() ||
                !Schema.sObjectType.Opportunity.fields.LastModifiedDate.isAccessible()) {
                throw new Metadata.NoAccessException('You do not have permission to access required fields on Opportunity.');
            }

            DateTime dateThreshold = DateTime.newInstance(Date.today().addDays(-request.MinDaysInStage), Time.newInstance(23, 59, 59, 999));

            List<Opportunity> opportunities = [
                SELECT Id, Name, StageName, LastModifiedDate
                FROM Opportunity
                WHERE StageName = :request.StageName
                AND LastModifiedDate <= :dateThreshold
            ];

            for (Opportunity opp : opportunities) {
                StageAnalysisResponse response = new StageAnalysisResponse();
                response.OpportunityId = opp.Id;
                response.OpportunityName = opp.Name;
                response.StageName = opp.StageName;
                response.LastModifiedDate = opp.LastModifiedDate;
                responses.add(response);
            }            
        }

        return responses;
    }

    public class StageAnalysisRequest {
        @InvocableVariable(required=true description='The name of the stage to analyze')
        public String StageName;

        @InvocableVariable(required=true description='The minimum number of days the opportunity has been in the stage')
        public Integer MinDaysInStage;
    }

    public class StageAnalysisResponse {
        @InvocableVariable(description='The ID of the opportunity')
        public Id OpportunityId;

        @InvocableVariable(description='The name of the opportunity')
        public String OpportunityName;

        @InvocableVariable(description='The current stage of the opportunity')
        public String StageName;

        @InvocableVariable(description='The last modified date of the opportunity')
        public DateTime LastModifiedDate;
    }
}