### ADR - 003: Form Submission Flow

Turbo Frames (https://github.com/hotwired/turbo-rails) for form pages/questions with data saved (but not necessarily fully validated) to Active Record model on each submit.


#### Impact on Performance

Using Turbo Frames allows us to swap out just the question part of the page without needing full page refreshes as you go through the form and provides a "Single Page Application like" user experience. Each question still gets a unique URL that can be navigated to directly with the Case Log ID and the overall user experience is that form navigation feels faster.

#### Impact on interrupted sessions

We currently have a single Active Record model for Case Logs that contains all the question fields. Every time a question is submitted the answer will be saved in the Active Record model instance before the next frame is rendered. This model will need to be able to handle partial records and partial validation anyway since not all API users will have all the required data. Validation can occur based on the data already saved and/or once the form is finally submitted. Front end validation will still happen additionally as you go through the form to help make sure users don't get a long list of errors at the end. Using session data here and updating the model only once the form is completed would not seem to have any advantages over this approach.

This means that when a user navigates away from the form or closes the tab etc, they can use the URL to navigate directly back to where they left off, or follow the form flow through again, and in both cases their submitted answers will still be there.


#### Impact on API

The API will still expect to take a JSON describing the case log, instantiate the model with the given fields, and run validations as if it had been submitted.
