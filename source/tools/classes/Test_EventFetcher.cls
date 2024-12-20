@IsTest
public with sharing class Test_EventFetcher {

    @IsTest
    static void testListEvents_SuccessWithContact() {
        Contact con = new Contact(LastName='Test Contact');
        insert con;

        Event meeting1 = new Event(
            Subject='Meeting with client',
            WhoId=con.Id,
            StartDateTime=DateTime.now().addDays(1),
            DurationInMinutes=30
        );
        Event meeting2 = new Event(
            Subject='Internal review',
            WhoId=con.Id,
            StartDateTime=DateTime.now().addDays(2),
            DurationInMinutes=30
        );
        insert new List<Event>{meeting1, meeting2};

        EventFetcher.EventRequest req = new EventFetcher.EventRequest();
        req.RecordId = con.Id;

        Test.startTest();
        List<EventFetcher.EventResponse> responses = EventFetcher.listEvents(new List<EventFetcher.EventRequest>{req});
        Test.stopTest();

        System.assertEquals(2, responses.size(), 'Should return 2 events');
        Set<String> subjects = new Set<String>();
        for (EventFetcher.EventResponse r : responses) {
            subjects.add(r.Subject);
        }
        System.assert(subjects.contains('Meeting with client'), 'Should contain Meeting with client');
        System.assert(subjects.contains('Internal review'), 'Should contain Internal review');
    }

    @IsTest
    static void testListEvents_SuccessWithOpportunity() {
        Account acc = new Account(Name='Opp Acc');
        insert acc;

        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today().addDays(10), AccountId=acc.Id);
        insert opp;

        Event eventOpp = new Event(
            Subject='Opp Meeting',
            WhatId=opp.Id,
            StartDateTime=DateTime.now().addHours(3),
            DurationInMinutes=30
        );
        insert eventOpp;

        EventFetcher.EventRequest req = new EventFetcher.EventRequest();
        req.RecordId = opp.Id;

        Test.startTest();
        List<EventFetcher.EventResponse> responses = EventFetcher.listEvents(new List<EventFetcher.EventRequest>{req});
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return 1 event');
        System.assertEquals('Opp Meeting', responses[0].Subject, 'Subject should match');
    }

    @IsTest
    static void testListEvents_NoEvents() {
        Contact con = new Contact(LastName='No Events Contact');
        insert con;

        EventFetcher.EventRequest req = new EventFetcher.EventRequest();
        req.RecordId = con.Id;

        Test.startTest();
        List<EventFetcher.EventResponse> responses = EventFetcher.listEvents(new List<EventFetcher.EventRequest>{req});
        Test.stopTest();

        System.assertEquals(0, responses.size(), 'No events means empty list');
    }

    @IsTest
    static void testListEvents_NoRequests() {
        Test.startTest();
        try {
            EventFetcher.listEvents(null);
            System.assert(false, 'Expected exception for null requests');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Requests cannot be null or empty.'), 'Expected exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testListEvents_MissingRecordId() {
        EventFetcher.EventRequest req = new EventFetcher.EventRequest();
        req.RecordId = null;

        Test.startTest();
        try {
            EventFetcher.listEvents(new List<EventFetcher.EventRequest>{req});
            System.assert(false, 'Expected exception for missing RecordId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('RecordId is required.'), 'Expected exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testListEvents_InvalidObject() {
        Account acc = new Account(Name='Invalid Object Acc');
        insert acc;

        EventFetcher.EventRequest req = new EventFetcher.EventRequest();
        req.RecordId = acc.Id;

        Test.startTest();
        try {
            EventFetcher.listEvents(new List<EventFetcher.EventRequest>{req});
            System.assert(false, 'Expected exception for invalid object');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('RecordId must be a Contact or Opportunity.'), 'Expected invalid object exception');
        }
        Test.stopTest();
    }
}