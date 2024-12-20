public with sharing class EventFetcher {

    @InvocableMethod(label='List Events' description='Returns events related to a given Contact or Opportunity')
    public static List<EventResponse> listEvents(List<EventRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        EventRequest req = requests[0];
        if (req.RecordId == null) {
            throw new IllegalArgumentException('RecordId is required.');
        }

        Schema.SObjectType sObjType = req.RecordId.getSObjectType();
        String objName = sObjType.getDescribe().getName();
        if (objName != 'Contact' && objName != 'Opportunity') {
            throw new IllegalArgumentException('RecordId must be a Contact or Opportunity.');
        }

        if (!Schema.sObjectType.Event.isAccessible() ||
            !Schema.sObjectType.Event.fields.Subject.isAccessible() ||
            !Schema.sObjectType.Event.fields.StartDateTime.isAccessible()) {
            throw new Metadata.NoAccessException('You do not have permission to access required Event fields.');
        }

        Id recordId = req.RecordId;

        List<Event> events = [
            SELECT Id, Subject, StartDateTime
            FROM Event
            WHERE (WhoId = :recordId OR WhatId = :recordId)
            ORDER BY StartDateTime ASC
        ];

        List<EventResponse> responses = new List<EventResponse>();
        for (Event e : events) {
            responses.add(new EventResponse(e.Id, e.Subject, e.StartDateTime));
        }

        return responses;
    }

    public class EventRequest {
        @InvocableVariable(required=true description='ID of the Contact or Opportunity')
        public Id RecordId;
    }

    public class EventResponse {
        @InvocableVariable(description='ID of the Event')
        public Id EventId;
        @InvocableVariable(description='Subject of the Event')
        public String Subject;
        @InvocableVariable(description='Start Date/Time of the Event')
        public DateTime StartDateTimeValue;

        public EventResponse(Id eventId, String subject, DateTime startDateTimeValue) {
            this.EventId = eventId;
            this.Subject = subject;
            this.StartDateTimeValue = startDateTimeValue;
        }
    }
}
