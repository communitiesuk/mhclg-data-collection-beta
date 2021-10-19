### ADR - 006: Saving values to the database

We have opted to save values to the database directly instead of saving keys/numbers that need to be converted with enums in models using active record.

### Saving values to the database

There are a few reasons we have opted to save the values directly, they are as follows

- The data will be easier to consume and analyse for anyone associated with the project who needs to do so but does not necessarily have the technical skills to access it through Rails i.e. A person could get the data directly from the database and it would require no additional work to be usable for reporting purposes

- Currently there is no need to abstract the data as the data should be safe from being accessed by anyone external to the project

- It doesn't require additional dev work to map keys/numbers to values, we can just pull the values out directly and use them in the code, for example on the check answers page



### Drawbacks

- Changing the wording/casing of the answers could result in discrepancies in the database

- There is a small risk that if the database is accessed by someone unauthorised they would have access to personally identifiable information if we were to collect Any. We  will be mitigating this risk by encrypting the production database 

This decision is not too difficult to change and can be revisited in the future if there is sufficient reason to switch to storing keys/numbers and using enums and active record to convert those to the appropriate values.
