public with sharing class Metadata {
    public with sharing class NoAccessException extends Exception {}
   
    private static final Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    public static Schema.SObjectType getSObjectType(String objectName) {
        if (!globalDescribe.containsKey(objectName)) {
            throw new IllegalArgumentException('Object ' + objectName + ' does not exist in the organization.');
        }
        return globalDescribe.get(objectName);
    }

    public static Schema.DescribeSObjectResult getDescribe(String objectName) {
        return getSObjectType(objectName).getDescribe();
    }
}