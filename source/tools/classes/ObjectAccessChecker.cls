public with sharing class ObjectAccessChecker {

    @InvocableMethod(label='Check Object Access' description='Checks if the user has access to perform specified operations on an object')
    public static List<AccessResult> checkObjectAccess(List<ObjectAccessRequest> requests) {
        List<AccessResult> results = new List<AccessResult>();

        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('At least one request must be provided.');
        }

        for (ObjectAccessRequest request : requests) {
            if (request == null || String.isBlank(request.objectName)) {
                throw new IllegalArgumentException('Object name must be provided for each request.');
            }

            AccessResult result = new AccessResult();
            result.objectName = request.objectName;

            try {
                Schema.SObjectType objType = Schema.getGlobalDescribe().get(request.objectName);
                if (objType == null) {
                    result.exists = false;
                    result.message = 'Object does not exist.';
                    results.add(result);
                    continue;
                }

                Schema.DescribeSObjectResult describeResult = objType.getDescribe();

                result.exists = true;
                result.isCreateable = describeResult.isCreateable();
                result.isReadable = describeResult.isAccessible();
                result.isUpdateable = describeResult.isUpdateable();
                result.isDeleteable = describeResult.isDeletable();
                result.message = 'Access check completed.';
            } catch (Exception e) {
                result.exists = false;
                result.message = 'Error: ' + e.getMessage();
            }

            results.add(result);
        }

        return results;
    }

    public class ObjectAccessRequest {
        @InvocableVariable(required=true description='API name of the object to check access for')
        public String objectName;
    }

    public class AccessResult {
        @InvocableVariable(description='API name of the object')
        public String objectName;

        @InvocableVariable(description='Indicates if the object exists in the org')
        public Boolean exists;

        @InvocableVariable(description='Indicates if the user can create records of this object')
        public Boolean isCreateable;

        @InvocableVariable(description='Indicates if the user can read records of this object')
        public Boolean isReadable;

        @InvocableVariable(description='Indicates if the user can update records of this object')
        public Boolean isUpdateable;

        @InvocableVariable(description='Indicates if the user can delete records of this object')
        public Boolean isDeleteable;

        @InvocableVariable(description='Message providing additional information about the access check')
        public String message;
    }
}