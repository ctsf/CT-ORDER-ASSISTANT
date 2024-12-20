public with sharing class ContactCreation {
    @InvocableMethod(label='Create Contact for Account' description='Creates a single Contact and associates it with an Account')
    public static void createContact(List<ContactRequest> requests) {
        if (requests == null || requests.size() != 1) {
            throw new IllegalArgumentException('Exactly one request must be provided.');
        }

        ContactRequest request = requests[0];

        if (request.AccountId == null) {
            throw new IllegalArgumentException('AccountId is required.');
        }
        if (request.LastName == null) {
            throw new IllegalArgumentException('LastName is required.');
        }

        if (!Schema.sObjectType.Contact.isCreateable()) {
            throw new Metadata.NoAccessException('You do not have permission to create Contacts.');
        }

        Contact contact = new Contact();

        if (Schema.sObjectType.Contact.fields.AccountId.isCreateable()) {
            contact.AccountId = request.AccountId;
        } else {
            throw new Metadata.NoAccessException('You do not have permission to set the AccountId field.');
        }

        if (Schema.sObjectType.Contact.fields.FirstName.isCreateable()) {
            contact.FirstName = request.FirstName;
        }

        if (Schema.sObjectType.Contact.fields.LastName.isCreateable()) {
            contact.LastName = request.LastName;
        } else {
            throw new Metadata.NoAccessException('You do not have permission to set the LastName field.');
        }

        if (Schema.sObjectType.Contact.fields.Email.isCreateable()) {
            contact.Email = request.Email;
        }

        if (Schema.sObjectType.Contact.fields.Phone.isCreateable()) {
            contact.Phone = request.Phone;
        }

        try {
            insert contact;
        } catch (Exception e) {
            System.debug('Error in inserting contact: ' + e.getMessage());
            throw e;
        }
    }

    public class ContactRequest {
        @InvocableVariable(required=true description='Account ID to associate the Contact with')
        public Id AccountId;

        @InvocableVariable(description='First Name of the Contact')
        public String FirstName;

        @InvocableVariable(required=true description='Last Name of the Contact')
        public String LastName;

        @InvocableVariable(description='Email of the Contact')
        public String Email;

        @InvocableVariable(description='Phone number of the Contact')
        public String Phone;
    }
}
