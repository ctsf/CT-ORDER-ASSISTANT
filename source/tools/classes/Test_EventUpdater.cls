@IsTest
public class Test_EventUpdater {

    @TestSetup
    static void setup() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
        insert testContact;

        List<Event> events = new List<Event>();
        for (Integer i = 1; i <= 3; i++) {
            events.add(new Event(
                Subject = 'Test Event ' + i,
                StartDateTime = DateTime.newInstance(2024, 12, 20 + i, 10, 0, 0),
                WhoId = testContact.Id,
                DurationInMinutes = 30
            ));
        }
        insert events;
    }

    @IsTest
    static void testUpdateEventDates_Success() {
        List<Event> events = [SELECT Id, StartDateTime FROM Event LIMIT 3];
        System.assert(events.size() == 3, 'Test setup should have created 3 events.');

        List<EventUpdater.EventUpdateRequest> requests = new List<EventUpdater.EventUpdateRequest>();
        for (Event event : events) {
            EventUpdater.EventUpdateRequest req = new EventUpdater.EventUpdateRequest();
            req.EventId = event.Id;
            req.NewStartDateTime = DateTime.newInstance(2024, 12, 25, 10, 0, 0);
            requests.add(req);
        }

        Test.startTest();
        List<EventUpdater.EventUpdateResponse> responses = EventUpdater.updateEventDates(requests);
        Test.stopTest();

        System.assertEquals(3, responses.size(), 'Expected responses for 3 events.');
        for (EventUpdater.EventUpdateResponse response : responses) {
            System.assertEquals('Success', response.Result, 'Each event update should succeed.');
            System.assert(response.ErrorMessage == null, 'ErrorMessage should be null for successful updates.');
        }

        List<Event> updatedEvents = [SELECT Id, StartDateTime FROM Event WHERE Id IN :events];
        for (Event event : updatedEvents) {
            System.assertEquals(DateTime.newInstance(2024, 12, 25, 10, 0, 0), event.StartDateTime, 'Event StartDateTime should be updated.');
        }
    }

    @IsTest
    static void testUpdateEventDates_MissingEventId() {
        EventUpdater.EventUpdateRequest req = new EventUpdater.EventUpdateRequest();
        req.EventId = null;
        req.NewStartDateTime = DateTime.newInstance(2024, 12, 25, 10, 0, 0);

        List<EventUpdater.EventUpdateRequest> requests = new List<EventUpdater.EventUpdateRequest>{req};

        Test.startTest();
        try {
            EventUpdater.updateEventDates(requests);
            System.assert(false, 'Expected IllegalArgumentException for missing EventId.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Both EventId and NewStartDateTime are required.', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateEventDate_nullRequest() {
        Test.startTest();
        try {
            EventUpdater.updateEventDates(null);
            System.Assert(false, 'Expected IllegalArgumentException for null request.');
        } catch (IllegalArgumentException e) {
            System.AssertEquals('Requests cannot be null or empty.', e.getMessage());
        }
        Test.stopTest();
    }
}