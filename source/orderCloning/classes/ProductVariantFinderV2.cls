global with sharing class ProductVariantFinderV2 {

    @InvocableMethod(label='Find Replacement Variants V2' 
                       description='Takes a Product ID and returns replacement variant products (those with the same Family) along with a friendly UX message.')
    global static List<ProductVariantResponse> findReplacementVariants(List<ProductVariantRequest> requests) {
        List<ProductVariantResponse> responses = new List<ProductVariantResponse>();
        for (ProductVariantRequest req : requests) {
            responses.add(processSingleRequest(req));
        }
        return responses;
    }
    
    private static ProductVariantResponse processSingleRequest(ProductVariantRequest request) {
        ProductVariantResponse response = new ProductVariantResponse();
        
        // Validate that the Product ID is provided.
        if (String.isBlank(request.productId)) {
            response.status = 'ERROR';
            response.message = 'Product ID must be provided.';
            response.friendlyUX = 'Please provide a valid Product ID to find replacement variants.';
            return response;
        }
        
        Id prodId;
        try {
            prodId = (Id) request.productId;
        } catch(Exception e) {
            response.status = 'ERROR';
            response.message = 'Invalid Product ID format.';
            response.friendlyUX = 'The provided Product ID format is invalid. Please verify and try again.';
            return response;
        }
        
        // Retrieve the product record.
        Product2 prod;
        try {
            prod = [SELECT Id, Name, Family FROM Product2 WHERE Id = :prodId LIMIT 1];
        } catch(Exception e) {
            response.status = 'ERROR';
            response.message = 'Error retrieving product: ' + e.getMessage();
            response.friendlyUX = 'Unable to retrieve the product. Please verify the Product ID and your access permissions.';
            return response;
        }
        
        if(prod == null) {
            response.status = 'ERROR';
            response.message = 'Product not found.';
            response.friendlyUX = 'No product found for the provided Product ID.';
            return response;
        }
        
        // If the product does not have a Family defined, no replacement variants can be determined.
        if(String.isBlank(prod.Family)) {
            response.status = 'SUCCESS';
            response.message = 'Product does not have a Family defined.';
            response.friendlyUX = 'The product "' + prod.Name + '" does not belong to any Family, so replacement variants cannot be determined.';
            response.replacementVariants = new List<Product2>();
            return response;
        }
        
        // Query for replacement variants: all products with the same Family (excluding the current product).
        List<Product2> variants = [
            SELECT Id, Name, Family 
            FROM Product2 
            WHERE Family = :prod.Family AND Id != :prodId AND orders__DefaultAvailabilityType__c = 'Available'
        ];
        
        response.replacementVariants = variants;
        response.status = 'SUCCESS';
        response.message = variants.isEmpty() ? 'No replacement variants found for the product family.' : 'Replacement variants retrieved successfully.';
        response.friendlyUX = 'Found ' + variants.size() + ' replacement variant(s) for product "' + prod.Name + '" in the "' + prod.Family + '" family.';
        return response;
    }

    global class ProductVariantRequest {
        @InvocableVariable(required=true label='Product ID' description='The Product ID to find replacement variants for.')
        global String productId;
    }

    global class ProductVariantResponse {
        @InvocableVariable(label='Status' description='Status of the replacement variant lookup.')
        global String status;
        
        @InvocableVariable(label='Message' description='Details about the lookup result.')
        global String message;
        
        @InvocableVariable(label='Replacement Variants' description='List of replacement variant products with the same Family field.')
        global List<Product2> replacementVariants;
        
        @InvocableVariable(label='Friendly UX Message' description='A user-friendly summary of the replacement variants lookup.')
        global String friendlyUX;
    }
}