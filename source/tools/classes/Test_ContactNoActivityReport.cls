@IsTest
public with sharing class Test_ContactNoActivityReport {

    @IsTest
    static void testContactsWithoutActivity_NoActivities() {
        Contact c = new Contact(FirstName='John', LastName='Doe', Email='john@example.com');
        insert c;

        ContactNoActivityReport.ContactActivityRequest req = new ContactNoActivityReport.ContactActivityRequest();
        req.MinDaysWithoutActivity = 1;

        Test.startTest();
        List<ContactNoActivityReport.ContactActivityResponse> responses = ContactNoActivityReport.getContactsWithoutActivity(new List<ContactNoActivityReport.ContactActivityRequest>{req});
        Test.stopTest();

        Boolean found = false;
        for (ContactNoActivityReport.ContactActivityResponse resp : responses) {
            if (resp.ContactId == c.Id) {
                found = true;
                break;
            }
        }

        System.assert(found, 'Contact with no activity should appear in the report.');
    }

    @IsTest
    static void testContactsWithoutActivity_WithActivity() {
        Contact c = new Contact(FirstName='Active', LastName='Contact', Email='active@example.com');
        insert c;

        Task t = new Task(WhoId = c.Id, Subject = 'Follow up', ActivityDate=Date.today());
        insert t;

        ContactNoActivityReport.ContactActivityRequest req = new ContactNoActivityReport.ContactActivityRequest();
        req.MinDaysWithoutActivity = 1;

        Test.startTest();
        List<ContactNoActivityReport.ContactActivityResponse> responses = ContactNoActivityReport.getContactsWithoutActivity(new List<ContactNoActivityReport.ContactActivityRequest>{req});
        Test.stopTest();

        Boolean found = false;
        for (ContactNoActivityReport.ContactActivityResponse resp : responses) {
            if (resp.ContactId == c.Id) {
                found = true;
                break;
            }
        }

        System.assert(!found, 'Contact with recent activity should NOT appear in the report.');
    }
}