public with sharing class MassDeleteRecords {

    @InvocableMethod(label='Mass Delete Records' description='Deletes records by their IDs')
    public static void deleteRecords(List<RecordDeleteRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        RecordDeleteRequest req = requests[0];

        if (req.RecordIds == null || req.RecordIds.isEmpty()) {
            throw new IllegalArgumentException('RecordIds cannot be null or empty.');
        }

        Id sampleId = req.RecordIds[0];
        Schema.SObjectType sObjType = sampleId.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = sObjType.getDescribe();

        if (!objDescribe.isDeletable()) {
            throw new Metadata.NoAccessException('You do not have permission to delete these records.');
        }

        String objectName = objDescribe.getName();

        List<Id> recordIds = req.RecordIds; 

        String query = 'SELECT Id FROM ' + objectName + ' WHERE Id IN :recordIds';
        List<SObject> recordsToDelete = Database.query(query);

        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }

    public class RecordDeleteRequest {
        @InvocableVariable(required=true description='List of record IDs to delete')
        public List<Id> RecordIds;
    }
}