public with sharing class LeadCityGrouper {

    @InvocableMethod(label='Group Leads by City' description='Returns a summary of how many leads exist per city')
    public static List<List<LeadCityResponse>> groupByCity(List<LeadCityRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        LeadCityRequest req = requests[0];

        if (!Schema.sObjectType.Lead.isAccessible() || 
            !Schema.sObjectType.Lead.fields.City.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access Lead City field.');
        }

        List<Lead> leads = [
            SELECT City
            FROM Lead
            WHERE City != null
        ];

        Map<String, Integer> cityCountMap = new Map<String, Integer>();

        for (Lead l : leads) {
            String city = l.City.toLowerCase();
            if (cityCountMap.containsKey(city)) {
                cityCountMap.put(city, cityCountMap.get(city) + 1);
            } else {
                cityCountMap.put(city, 1);
            }
        }

        List<LeadCityResponse> responses = new List<LeadCityResponse>();
        for (String city : cityCountMap.keySet()) {
            responses.add(new LeadCityResponse(city, cityCountMap.get(city)));
        }

        return new List<List<LeadCityResponse>>{responses};
    }

    public class LeadCityRequest {
        @InvocableVariable(description='Placeholder if needed')
        public String Placeholder;
    }

    public class LeadCityResponse {
        @InvocableVariable(description='City name')
        public String City;
        @InvocableVariable(description='Number of leads in this city')
        public Integer Count;

        public LeadCityResponse(String city, Integer count) {
            this.City = city;
            this.Count = count;
        }
    }
}