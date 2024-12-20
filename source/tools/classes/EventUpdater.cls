public with sharing class EventUpdater {

    @InvocableMethod(label='Update Event Date' description='Updates the Start Date/Time of a given Event')
    public static List<EventUpdateResponse> updateEventDates(List<EventUpdateRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Requests cannot be null or empty.');
        }

        List<EventUpdateResponse> responses = new List<EventUpdateResponse>();

        if (!Schema.sObjectType.Event.isAccessible() ||
            !Schema.sObjectType.Event.fields.StartDateTime.isUpdateable()) {
            throw new Metadata.NoAccessException('You do not have permission to update Event StartDateTime.');
        }

        for (EventUpdateRequest req : requests) {
            if (req.EventId == null || req.NewStartDateTime == null) {
                throw new IllegalArgumentException('Both EventId and NewStartDateTime are required.');
            }

            Event eventToUpdate = [SELECT Id, StartDateTime FROM Event WHERE Id = :req.EventId LIMIT 1];

            if (eventToUpdate != null) {
                eventToUpdate.StartDateTime = req.NewStartDateTime;

                try {
                    update eventToUpdate;
                    responses.add(new EventUpdateResponse(eventToUpdate.Id, 'Success', null));
                } catch (DmlException e) {
                    responses.add(new EventUpdateResponse(req.EventId, 'Error', e.getMessage()));
                }
            } else {
                responses.add(new EventUpdateResponse(req.EventId, 'Error', 'Event not found.'));
            }
        }

        return responses;
    }

    public class EventUpdateRequest {
        @InvocableVariable(required=true description='ID of the Event to update')
        public Id EventId;

        @InvocableVariable(required=true description='New Start Date/Time for the Event')
        public DateTime NewStartDateTime;
    }

    public class EventUpdateResponse {
        @InvocableVariable(description='ID of the updated Event')
        public Id EventId;

        @InvocableVariable(description='Result of the update (Success/Error)')
        public String Result;

        @InvocableVariable(description='Error message if the update failed')
        public String ErrorMessage;

        public EventUpdateResponse(Id eventId, String result, String errorMessage) {
            this.EventId = eventId;
            this.Result = result;
            this.ErrorMessage = errorMessage;
        }
    }
}
