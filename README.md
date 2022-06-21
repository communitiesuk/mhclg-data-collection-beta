# Submit social housing lettings and sales data (CORE)

[![Production CI/CD Pipeline](https://github.com/communitiesuk/mhclg-data-collection-beta/actions/workflows/production_pipeline.yml/badge.svg)](https://github.com/communitiesuk/mhclg-data-collection-beta/actions/workflows/production_pipeline.yml)
[![Staging CI/CD Pipeline](https://github.com/communitiesuk/mhclg-data-collection-beta/actions/workflows/staging_pipeline.yml/badge.svg)](https://github.com/communitiesuk/mhclg-data-collection-beta/actions/workflows/staging_pipeline.yml)

Codebase for the Ruby on Rails app that handles the submission of lettings and sales of social housing data in England.

## API documentation

API documentation can be found here: <https://communitiesuk.github.io/mhclg-data-collection-beta>. This is driven by [OpenAPI docs](docs/api/DLUHC-CORE-Data.v1.json)

## Required Setup

Pre-requisites:

- Ruby
- Rails
- Postgres

### Quick start

1. Copy the `.env.example` to `.env` and replace the database credentials with your local postgres user credentials.

2. Install the dependencies:\
  `bundle install`

3. Create the database:\
  `rake db:create`

4. Run the database migrations:\
  `rake db:migrate`

5. Seed the database if required:\
`rake db:seed`

6. Seed the database with rent ranges if required (~7000 rows per year):\
`rake "data_import:rent_ranges[<start_year>,<rent_ranges_path>]"`

    For 2021-2022 ranges run:\
    `rake "data_import:rent_ranges[2021,config/rent_range_data/2021.csv]"`

7. Install the frontend depenencies:\
  `yarn install`

8. Start the dev servers using foreman:\
  `./bin/dev`

  Or start them individually:\

  a. Rails:\
    `bundle exec rails s`

  b. JS (for hot reloading):\
    `yarn build --mode=development --watch`

If you're not modifying front end assets you can bundle them as a one off task:\
  `yarn build --mode=development`

Development mode will target the latest versions of Chrome, Firefox and Safari for transpilation while production mode will target older browsers.

The Rails server will start on <http://localhost:3000>.

Running the test suite (front end assets need to be built or server needs to be running):\
  `bundle exec rspec`

### Using Docker

1. Build the image:\
`docker-compose build`

2. Run the database migrations:\
`docker-compose run --rm app /bin/bash -c 'rake db:migrate'`

3. Seed the database if required:\
`docker-compose run --rm app /bin/bash -c 'rake db:seed'`

4. To be able to debug with Pry run the app using:\
`docker-compose run --service-ports app`

If this is not needed you can run `docker-compose up` as normal

The Rails server will start on <http://localhost:8080>.

## Infrastructure

This application is running on [GOV.UK PaaS](https://www.cloud.service.gov.uk/). To deploy you need to:

1. Contact your organisation manager to get an account in `dluhc-core` organization and in the relevant spaces (staging/production).

2. [Install the Cloud Foundry CLI](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)

3. Login:\
`cf login -a api.london.cloud.service.gov.uk -u <your_username>`

4. Set your deployment target (staging/production):\
`cf target -o dluhc-core -s <deploy_environment>`

5. Deploy:\
`cf push dluhc-core --strategy rolling`. This will use the [manifest file](staging_manifest.yml)

Once the app is deployed:

1. Get a Rails console:\
`cf ssh dluhc-core-staging -t -c "/tmp/lifecycle/launcher /home/vcap/app 'rails console' ''"`

2. Check logs:\
`cf logs dluhc-core-staging --recent`

### Troubleshooting deployments

A failed Github deployment action will occasionally leave a Cloud Foundry deployment in a broken state. As a result all subsequent Github deployment actions will also fail with the message `Cannot update this process while a deployment is in flight`.

`
cf cancel-deployment dluhc-core
`

You'd then need to check the logs and fix the issue that caused the initial deployment to fail.

## CI/CD

When a commit is made to `main` the following GitHub action jobs are triggered:

1. **Test**: RSpec runs our test suite
2. **Deploy**: If the Test stage passes, this job will deploy the app to our GOV.UK PaaS account using the Cloud Foundry CLI

When a pull request is opened to `main` only the Test stage runs.

## Frontend

### GOV.UK Design System components

This service follows the guidance and recommendations from the [GOV.UK Design System](https://design-system.service.gov.uk). This is achieved using the following libraries:

- **GOV.UK Frontend** – CSS and JavaScript for all Design System components\
  [Documentation](https://frontend.design-system.service.gov.uk) ·
  [GitHub](https://github.com/alphagov/govuk-frontend)

- **GOV.UK Components** – Rails view components for non-form related Design System components\
  [Documentation](https://govuk-components.netlify.app) ·
  [Github](https://github.com/DFE-Digital/govuk-components) ·
  [RubyDoc](https://www.rubydoc.info/gems/govuk-components)

- **GOV.UK FormBuilder** – Rails form builder for form related Design System components\
  [Documentation](https://govuk-form-builder.netlify.app) ·
  [GitHub](https://github.com/DFE-Digital/govuk-formbuilder) ·
  [RubyDoc](https://www.rubydoc.info/gems/govuk_design_system_formbuilder)

### Service-specific components

Service-specific components are built using the [ViewComponent](https://viewcomponent.org) framework, and can be found in `app/components`.

Components use HTML class names that follow the BEM methodology. We use the `app-*` prefix to prevent collisions with components provided by the Design System (which uses `govuk-*`). See [Extending and modifying components in production](https://design-system.service.gov.uk/get-started/extending-and-modifying-components/).

Stylesheets are written using [Sass](https://sass-lang.com) (and the SCSS syntax), using the mixins and helpers provided by [govuk-frontend](https://frontend.design-system.service.gov.uk/sass-api-reference/).

Separate stylesheets are used for each component, with filenames that match the component’s namespace.

Like the components provided by the Design System, components are progressively enhanced. We use [Stimulus](https://stimulus.hotwired.dev) to add any client-side JavaScript enhancements.

## Single log submission form configuration

The form for this is driven by a JSON file in `/config/forms/{start_year}_{end_year}.json`

The JSON should follow the structure:

```jsonc
{
  "form_type": "lettings" / "sales",
  "start_year": Integer, // i.e. 2020
  "end_year": Integer, // i.e. 2021
  "sections": {
    "[snake_case_section_name_string]": {
      "label": String,
      "description": String,
      "subsections": {
        "[snake_case_subsection_name_string]": {
          "label": String,
          "pages": {
            "[snake_case_page_name_string]": {
              "header": String,
              "description": String,
              "questions": {
                "[snake_case_question_name_string]": {
                  "header": String,
                  "hint_text": String,
                  "check_answer_label": String,
                  "type": "text" / "numeric" / "radio" / "checkbox" / "date",
                  "min": Integer, // numeric only
                  "max": Integer, // numeric only
                  "step": Integer, // numeric only
                  "width": 2 / 3 / 4 / 5 / 10 / 20, // text and numeric only
                  "prefix": String, // numeric only
                  "suffix": String, //numeric only
                  "answer_options": { // checkbox and radio only
                    "0": String,
                    "1": String
                  },
                  "conditional_for": {
                    "[snake_case_question_to_enable_1_name_string]": ["condition-that-enables"],
                    "[snake_case_question_to_enable_2_name_string]": ["condition-that-enables"]
                  },
                  "inferred_answers": { "field_that_gets_inferred_from_current_field": { "is_that_field_inferred": true } },
                  "inferred_check_answers_value": {
                    "condition": { "field_name_for_inferred_check_answers_condition": "field_value_for_inferred_check_answers_condition" },
                    "value": "Inferred value that gets displayed if condition is met"
                  }
                }
              },
              "depends_on": [{ "question_key": "answer_value_required_for_this_page_to_be_shown" }]
            }
          }
        }
      }
    }
  }
}
```

Assumptions made by the format:

- All forms have at least 1 section
- All sections have at least 1 subsection
- All subsections have at least 1 page
- All pages have at least 1 question
- The ActiveRecord case log model has a field for each question name (must match). In the case of checkbox questions it must have one field for every answer option (again names must match).
- Text not required by a page/question such as a header or hint text should be passed as an empty string
- For conditionally shown questions, conditions that have been implemented and can be used are:
  - Radio question answer option selected matches one of conditional e.g. ["answer-options-1-string", "answer-option-3-string"]
  - Numeric question value matches condition e.g. [">2"], ["<7"] or ["== 6"]
- When the top level question is a radio button and the conditional question is a numeric, text or date field then the conditional question is shown inline
- When the conditional question is a radio, checkbox or select field it should be displayed on it's own page and "depends_on" should be used rather than "conditional_for"

  Page routing:

  - Form navigation works by stepping sequentially through every page defined in the JSON form definition for the given subsection. For every page it checks if it has "depends_on" conditions. If it does, it evaluates them to determine whether that page should be show or not.

  - In this way we can build up whole branches by having:

  ```jsonc
  "page_1": { "questions": { "question_1: "answer_options": ["A", "B"] } },
  "page_2": { "questions": { "question_2: "answer_options": ["C", "D"] }, "depends_on": [{ "question_1": "A" }] },
  "page_3": { "questions": { "question_3: "answer_options": ["E", "F"] }, "depends_on": [{ "question_1": "A" }] },
  "page_4": { "questions": { "question_4: "answer_options": ["G", "H"] }, "depends_on": [{ "question_1": "B" }] },
  ```

### JSON form validation against Schema

To validate the form JSON against the schema you can run:\
  `rake form_definition:validate["config/forms/2021_2022.json"]`

n.b. You may have to escape square brackets in zsh\
  `rake form_definition:validate\["config/forms/2021_2022.json"\]`

This will validate the given form definition against the schema in `config/forms/schema/generic.json`.

You can also run:\
  `rake form_definition:validate_all`

This will validate all forms in directories = `["config/forms", "spec/fixtures/forms"]`
