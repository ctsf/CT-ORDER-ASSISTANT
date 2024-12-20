public with sharing class OpportunityStageSummary {

    @InvocableMethod(label='Generate Opportunity Stage Summary' description='Returns count, total amount, and average amount of opportunities per stage')
    public static List<List<StageSummaryResponse>> generateSummary(List<StageSummaryRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        if (!Schema.sObjectType.Opportunity.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.Amount.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.StageName.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Opportunity fields.');
        }

        List<AggregateResult> results = [
            SELECT StageName stage, COUNT(Id) cnt, SUM(Amount) total
            FROM Opportunity
            GROUP BY StageName
        ];

        List<StageSummaryResponse> responses = new List<StageSummaryResponse>();

        for (AggregateResult ar : results) {
            String stage = (String)ar.get('stage');
            Long count = (Long)ar.get('cnt');
            Decimal total = (Decimal)ar.get('total');

            Decimal avg = (count > 0) ? total.divide(count, 2) : 0;

            responses.add(new StageSummaryResponse(stage, count, total, avg));
        }

        return new List<List<StageSummaryResponse>>{responses};
    }

    public class StageSummaryRequest {
        @InvocableVariable(description='Optional placeholder if needed')
        public String Placeholder;
    }

    public class StageSummaryResponse {
        @InvocableVariable(description='Stage Name')
        public String StageName;
        @InvocableVariable(description='Count of Opportunities in this stage')
        public Long Count;
        @InvocableVariable(description='Total Amount of Opportunities in this stage')
        public Decimal TotalAmount;
        @InvocableVariable(description='Average Amount of Opportunities in this stage')
        public Decimal AverageAmount;

        public StageSummaryResponse(String stageName, Long count, Decimal total, Decimal average) {
            this.StageName = stageName;
            this.Count = count;
            this.TotalAmount = total;
            this.AverageAmount = average;
        }
    }
}