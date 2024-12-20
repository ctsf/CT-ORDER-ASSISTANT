public with sharing class ContactNoActivityReport {

    @InvocableMethod(label='Get Contacts Without Recent Activity' description='Returns contacts that have no tasks or events in the last N days')
    public static List<ContactActivityResponse> getContactsWithoutActivity(List<ContactActivityRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        ContactActivityRequest req = requests[0];
        if (req.MinDaysWithoutActivity == null || req.MinDaysWithoutActivity < 0) {
            throw new IllegalArgumentException('MinDaysWithoutActivity must be a non-negative integer.');
        }

        if (!Schema.sObjectType.Contact.isAccessible() || !Schema.sObjectType.Contact.fields.Name.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access Contact fields.');
        }

        Date cutoffDate = Date.today().addDays(-Integer.valueOf(req.MinDaysWithoutActivity));

        Set<Id> activeContactIds = new Set<Id>();

        if (Schema.sObjectType.Task.isAccessible() && Schema.sObjectType.Task.fields.WhoId.isAccessible() && Schema.sObjectType.Task.fields.ActivityDate.isAccessible()) {
            for (Task t : [
                SELECT WhoId FROM Task
                WHERE WhoId != null AND ActivityDate >= :cutoffDate
            ]) {
                if (t.WhoId.getSobjectType() == Contact.SObjectType) {
                    activeContactIds.add(t.WhoId);
                }
            }
        }

        if (Schema.sObjectType.Event.isAccessible() && Schema.sObjectType.Event.fields.WhoId.isAccessible() && Schema.sObjectType.Event.fields.ActivityDate.isAccessible()) {
            for (Event e : [
                SELECT WhoId FROM Event
                WHERE WhoId != null AND ActivityDate >= :cutoffDate
            ]) {
                if (e.WhoId.getSobjectType() == Contact.SObjectType) {
                    activeContactIds.add(e.WhoId);
                }
            }
        }

        List<Contact> allContacts = [
            SELECT Id, Name, Email FROM Contact
        ];

        List<ContactActivityResponse> responses = new List<ContactActivityResponse>();
        for (Contact c : allContacts) {
            if (!activeContactIds.contains(c.Id)) {
                responses.add(new ContactActivityResponse(c.Id, c.Name, c.Email));
            }
        }

        return responses;
    }

    public class ContactActivityRequest {
        @InvocableVariable(required=true description='Minimum days without activity')
        public Integer MinDaysWithoutActivity;
    }

    public class ContactActivityResponse {
        @InvocableVariable(description='ID of the contact')
        public Id ContactId;
        @InvocableVariable(description='Name of the contact')
        public String ContactName;
        @InvocableVariable(description='Email of the contact')
        public String ContactEmail;

        public ContactActivityResponse(Id contactId, String contactName, String contactEmail) {
            this.ContactId = contactId;
            this.ContactName = contactName;
            this.ContactEmail = contactEmail;
        }
    }
}