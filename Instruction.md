Step 1: Define the Order to Clone  
1. Identify the Order Context:  
   - If you are on the Record Page of an orders__Order__c record, use the record’s clickable object (e.g., the Order Name) directly from the page instead of displaying or asking for its ID.  
   - Otherwise, determine the order based on user-friendly input (never ask the user to manually enter a record ID, as this is not UX friendly).  
2. Ask the User for Order Identification Method:  
   - Ask if the user wants to:  
     - Provide an Account to search for associated orders, or  
     - Provide an Order Number to locate the order directly.

Step 2.a: Find Order by Account  
1. Retrieve Accounts:  
   - Use the Retrieve Accounts action to display a list of accounts to the user.  
   - Present each account using its name (or clickable record object) instead of its ID.  
   - Ask the user to select an account from the list.  
2. Ensure Selection:  
   - If no account is selected, repeat the question until the user makes a valid selection.  
   - Once selected, retrieve the account’s details (using the name/link for display) for subsequent steps.  
3. Retrieve Orders:  
   - Use the Retrieve Orders action to fetch orders associated with the selected account.  
   - Present the list of retrieved orders to the user using friendly details (such as order name, number, and other key information) rather than IDs, and ask them to select the order to clone.  
4. Ensure Order Selection:  
   - If no order is selected, repeat the question until a valid order is chosen.  
   - Once a valid order is selected, display its details (e.g., order number, account name, total amount, date created) in a user-friendly manner (using names and clickable objects) and ask the user to confirm if they want to proceed with cloning this order.

Step 2.b: Find Order by Number  
1. Prompt for Order Number:  
   - Ask the user to provide the order number of the order they wish to clone (avoid asking for record IDs).  
2. Retrieve Order:  
   - Use the Retrieve Orders action to locate orders based on the provided order number.  
3. Ensure Valid Number:  
   - If the provided number does not match any existing order, prompt the user again for a valid order number.  
   - Once a valid order is identified, display its details (using names or clickable record objects) and ask for confirmation before proceeding.

Step 3: Ask About Account Replacement  
1. Prompt for Replacement:  
   - Ask the user if they want to replace the account associated with the selected order.  
2. If Yes:  
   - Use the Retrieve Accounts action again to present a list of accounts (displayed using names or clickable records).  
   - Ask the user to select a new account.  
   - Ensure a valid account is chosen—if not, repeat the prompt until a valid selection is made.  
   - Replace the account on the cloned order using the friendly account details.  
3. If No:  
   - Proceed without replacing the account.

Step 4: Ask About Cloning Deliveries  
1. Prompt for Delivery Cloning:  
   - Ask the user if they want to clone the deliveries associated with the order.  
2. Response Handling:  
   - If the user answers yes, proceed to Step 5.  
   - If the user answers no, skip to Step 7.

Step 5: Ask About Cloning Quantities  
1. Prompt for Quantity Cloning:  
   - Ask if the user wants to clone the quantities in the deliveries.  
2. Response Handling:  
   - Once an answer is provided, proceed to Step 6.

Step 6: Ask About Shifting Dates  
1. Prompt for Date Shifting:  
   - Ask if the user wants to shift delivery dates based on the original intervals.  
2. Response Handling:  
   - Once an answer is provided, proceed to Step 7.

Step 7: Call the "Clone Order V2" Action  
1. Execute Cloning:  
   - Call the Clone Order V2 action using the gathered parameters:  
     - Selected order (displayed using its name or clickable object).  
     - Optional account replacement.  
     - Delivery cloning preferences.  
     - Quantity cloning preferences.  
     - Date shifting preferences.  
2. Confirm Completion:  
   - Inform the user once the order has been successfully cloned.  
   - Display details of the cloned order (using user-friendly information such as the new order name/number and associated account name rather than IDs).  
   - Return the cloned order details to the chat.  
   - Proceed to Step 8.

Step 8: Check for Available Promotions for the New Account (Must Be Executed After Step 7)  
1. Ensure Immediate Execution:  
   - Once Step 7 is completed, immediately proceed using the cloned order’s account.  
2. Retrieve Promotions:  
   - Use the Retrieve Promotions action to check for promotions associated with the account of the cloned order.  
3. Present Promotions:  
   - If promotions are available:  
     - Display the list of promotions to the user using friendly details (such as promotion names or clickable objects).  
     - Ask if they would like to add any of these promotions to the cloned order.  
   - If no promotions are available, inform the user and proceed.  
4. Assign Promotions:  
   - If the user agrees to add promotions, use the Add Promotions to Order action to attach the selected promotions to the cloned order.  
5. Note:  
   - This step should always be executed after a successful order cloning. Do not skip this step.

Step 9: Check Product Availability for the Cloned Order  
1. Initiate the Product Availability Check:  
   - Call the "Check Product Availability" action. Pass the cloned order’s details (using its name or a clickable object, not its ID) to verify product availability based on current delivery dates and established availability policies.  
2. Display the Check Results:  
   - Show Unavailable Products:  
     - If any products are found to be unavailable, display the list of these products to the user using product names or clickable objects.  
   - Provide Suggested Replacements:  
     - For each unavailable product, present a list of possible replacement options (displayed using friendly product names) as determined by the system.  
3. User Interaction for Replacement:  
   - Ask the User:  
     - Request confirmation from the user on whether they want to replace the unavailable products with any of the suggested options.  
   - Selection Process:  
     - Allow the user to select the appropriate replacement for each unavailable product using friendly, clickable options.  
4. Iterate Through Replacement Results and Perform Change Action:  
   - For each unavailable product, iterate through its list of suggested replacement options and have the user (or the system by default) choose one replacement option.  
   - Once a replacement is selected for a product, perform the “Change Product” action that updates the corresponding order line item with the selected replacement product.  
   - This action should update the order details to reflect the change in product, ensuring that the product name and other friendly details are displayed to the user.  
5. Update the Cloned Order:  
   - After processing all unavailable products, confirm the replacements have been applied and update the cloned order accordingly.  
   - Display the final order details, including updated order line items and the current product availability status, using names and clickable objects rather than IDs.  
6. Final Confirmation:  
   - Notify Completion:  
     - Inform the user that the product availability check and product replacement process is complete and that the order is ready for further processing.  
   - Display Final Order Details:  
     - Show the final details of the cloned order, including its new order name/number, associated account, delivery details, and the status of product availability, all in a user-friendly, clickable format.