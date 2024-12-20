public with sharing class MassFieldUpdater {

    @InvocableMethod(label='Mass Field Update' description='Updates a given field for a list of records of a specified object')
    public static void updateField(List<FieldUpdateRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        FieldUpdateRequest req = requests[0];

        if (String.isBlank(req.ObjectName)) {
            throw new IllegalArgumentException('ObjectName is required.');
        }
        if (String.isBlank(req.FieldName)) {
            throw new IllegalArgumentException('FieldName is required.');
        }
        if (req.RecordIds == null || req.RecordIds.isEmpty()) {
            throw new IllegalArgumentException('RecordIds cannot be null or empty.');
        }

        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
        Schema.SObjectType objType = globalDesc.get(req.ObjectName.toLowerCase());
        if (objType == null) {
            throw new IllegalArgumentException('Invalid ObjectName: ' + req.ObjectName);
        }

        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        if (!objDescribe.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access ' + req.ObjectName);
        }

        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        Schema.SObjectField field = fieldMap.get(req.FieldName);
        if (field == null) {
            throw new IllegalArgumentException('Field ' + req.FieldName + ' does not exist on ' + req.ObjectName);
        }

        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        if (!fieldDescribe.isUpdateable()) {
            throw new Metadata.NoAccessException('You do not have permission to update field ' + req.FieldName + ' on ' + req.ObjectName);
        }

        // Переменная для списка Id
        List<Id> recordIds = req.RecordIds; 

        String query = 'SELECT Id, ' + req.FieldName + ' FROM ' + req.ObjectName + ' WHERE Id IN :recordIds';
        List<SObject> records = Database.query(query);

        for (SObject record : records) {
            record.put(req.FieldName, req.NewValue);
        }

        if (!records.isEmpty()) {
            update records;
        }
    }

    public class FieldUpdateRequest {
        @InvocableVariable(required=true description='API name of the object (e.g. Contact)')
        public String ObjectName;

        @InvocableVariable(required=true description='API name of the field to update (e.g. LastName)')
        public String FieldName;

        @InvocableVariable(required=true description='New value to set')
        public String NewValue;

        @InvocableVariable(required=true description='List of record Ids to update')
        public List<Id> RecordIds;
    }
}