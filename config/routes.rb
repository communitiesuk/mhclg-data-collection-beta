# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  mount_sidekiq = -> { mount Sidekiq::Web => "/sidekiq" }
  authenticate(:user, :support?.to_proc, &mount_sidekiq)

  devise_for :users, {
    path: :account,
    controllers: {
      confirmations: "auth/confirmations",
      passwords: "auth/passwords",
      sessions: "auth/sessions",
      two_factor_authentication: "auth/two_factor_authentication",
    },
    path_names: {
      sign_in: "sign-in",
      sign_out: "sign-out",
      two_factor_authentication: "two-factor-authentication",
      two_factor_authentication_resend_code: "resend-code",
    },
    sign_out_via: %i[get],
  }

  devise_scope :user do
    get "account/password/reset-confirmation", to: "auth/passwords#reset_confirmation"
    get "account/two-factor-authentication/resend", to: "auth/two_factor_authentication#show_resend", as: "user_two_factor_authentication_resend"
    put "account", to: "users#update"
  end

  get "/health", to: ->(_) { [204, {}, [nil]] }
  resource :cookies, only: %i[show update]

  root to: "start#index"
  get "/guidance", to: "start#guidance"

  get "/logs", to: redirect("lettings-logs")
  get "/accessibility-statement", to: "content#accessibility_statement"
  get "/privacy-notice", to: "content#privacy_notice"
  get "/data-sharing-agreement", to: "content#data_sharing_agreement"
  get "/service-moved", to: "maintenance#service_moved"
  get "/service-unavailable", to: "maintenance#service_unavailable"
  get "/address-search", to: "address_search#index"
  get "/address-search/current", to: "address_search#current"
  get "/address-search/manual-input/:log_type/:log_id", to: "address_search#manual_input", as: "address_manual_input"
  get "/address-search/search-input/:log_type/:log_id", to: "address_search#search_input", as: "address_search_input"

  get "collection-resources", to: "collection_resources#index"
  get "/collection-resources/:log_type/:year/:resource_type/download", to: "collection_resources#download_mandatory_collection_resource", as: :download_mandatory_collection_resource
  get "/collection-resources/:log_type/:year/:resource_type/edit", to: "collection_resources#edit_mandatory_collection_resource", as: :edit_mandatory_collection_resource
  patch "/collection-resources", to: "collection_resources#update_mandatory_collection_resource", as: :update_mandatory_collection_resource
  get "/collection-resources/:year/release", to: "collection_resources#confirm_mandatory_collection_resources_release", as: :confirm_mandatory_collection_resources_release
  patch "/collection-resources/:year/release", to: "collection_resources#release_mandatory_collection_resources", as: :release_mandatory_collection_resources

  resources :collection_resources, path: "/collection-resources" do
    get "/download", to: "collection_resources#download_additional_collection_resource"
    get "/edit", to: "collection_resources#edit_additional_collection_resource"
    patch "/update", to: "collection_resources#update_additional_collection_resource"
    get "/delete-confirmation", to: "collection_resources#delete_confirmation"
    delete "/delete", to: "collection_resources#delete"
  end

  get "clear-filters", to: "sessions#clear_filters"

  resource :account, only: %i[show edit], controller: "users" do
    get "edit/password", to: "users#edit_password"
  end

  resources :schemes do
    get "primary-client-group", to: "schemes#primary_client_group"
    get "confirm-secondary-client-group", to: "schemes#confirm_secondary_client_group"
    get "secondary-client-group", to: "schemes#secondary_client_group"
    get "support", to: "schemes#support"
    get "details", to: "schemes#details"
    get "check-answers", to: "schemes#check_answers"
    get "edit-name", to: "schemes#edit_name"
    get "new-deactivation", to: "schemes#new_deactivation"
    get "deactivate-confirm", to: "schemes#deactivate_confirm"
    get "reactivate", to: "schemes#reactivate"
    get "new-reactivation", to: "schemes#new_reactivation"
    patch "new-deactivation", to: "schemes#new_deactivation"
    patch "deactivate", to: "schemes#deactivate"
    patch "reactivate", to: "schemes#reactivate"
    get "delete-confirmation", to: "schemes#delete_confirmation"
    delete "delete", to: "schemes#delete"

    collection do
      get "csv-download", to: "schemes#download_csv"
      post "email-csv", to: "schemes#email_csv"
      get "csv-confirmation", to: "schemes#csv_confirmation"
    end

    resources :locations do
      post "locations", to: "locations#create"
      get "new-deactivation", to: "locations#new_deactivation"
      get "deactivate-confirm", to: "locations#deactivate_confirm"
      get "reactivate", to: "locations#reactivate"
      get "new-reactivation", to: "locations#new_reactivation"
      get "postcode", to: "locations#postcode"
      patch "postcode", to: "locations#update_postcode"
      get "local-authority", to: "locations#local_authority"
      patch "local-authority", to: "locations#update_local_authority"
      get "name", to: "locations#name"
      patch "name", to: "locations#update_name"
      get "units", to: "locations#units"
      patch "units", to: "locations#update_units"
      get "type-of-unit", to: "locations#type_of_unit"
      patch "type-of-unit", to: "locations#update_type_of_unit"
      get "mobility-standards", to: "locations#mobility_standards"
      patch "mobility-standards", to: "locations#update_mobility_standards"
      get "availability", to: "locations#availability"
      patch "availability", to: "locations#update_availability"
      get "check-answers", to: "locations#check_answers"
      patch "confirm", to: "locations#confirm"
      patch "new-deactivation", to: "locations#new_deactivation"
      patch "deactivate", to: "locations#deactivate"
      patch "reactivate", to: "locations#reactivate"
      get "delete-confirmation", to: "locations#delete_confirmation"
      delete "delete", to: "locations#delete"
    end
  end
  get "scheme-changes", to: "schemes#changes"

  resources :duplicate_logs, only: [:index], path: "/duplicate-logs"

  resources :users do
    get "edit-dpo", to: "users#dpo"
    get "edit-key-contact", to: "users#key_contact"
    get "log-reassignment", to: "users#log_reassignment"
    patch "log-reassignment", to: "users#update_log_reassignment"
    get "organisation-change-confirmation", to: "users#organisation_change_confirmation"
    patch "organisation-change-confirmation", to: "users#confirm_organisation_change"

    collection do
      get :search
    end

    member do
      get "deactivate", to: "users#deactivate"
      get "reactivate", to: "users#reactivate"
      post "resend-invite", to: "users#resend_invite"
      get "delete-confirmation", to: "users#delete_confirmation"
      delete "delete", to: "users#delete"
    end
  end

  resources :notifications do
    get "dismiss", to: "notifications#dismiss"
    get "check-answers", to: "notifications#check_answers"
    get "delete-confirmation", to: "notifications#delete_confirmation"
    delete "delete", to: "notifications#delete"
  end

  resources :organisations do
    get "duplicates", to: "duplicate_logs#index"

    member do
      get "details", to: "organisations#details"
      get "data-sharing-agreement", to: "organisations#data_sharing_agreement"
      post "data-sharing-agreement", to: "organisations#confirm_data_sharing_agreement"

      get "users", to: "organisations#users"
      get "lettings-logs", to: "organisations#lettings_logs"
      get "delete-lettings-logs", to: "delete_logs#delete_lettings_logs_for_organisation"
      post "delete-lettings-logs", to: "delete_logs#delete_lettings_logs_for_organisation_with_selected_ids"
      post "delete-lettings-logs-confirmation", to: "delete_logs#delete_lettings_logs_for_organisation_confirmation"
      delete "delete-lettings-logs", to: "delete_logs#discard_lettings_logs_for_organisation"
      get "sales-logs", to: "organisations#sales_logs"
      get "delete-sales-logs", to: "delete_logs#delete_sales_logs_for_organisation"
      post "delete-sales-logs", to: "delete_logs#delete_sales_logs_for_organisation_with_selected_ids"
      post "delete-sales-logs-confirmation", to: "delete_logs#delete_sales_logs_for_organisation_confirmation"
      delete "delete-sales-logs", to: "delete_logs#discard_sales_logs_for_organisation"
      get "lettings-logs/csv-download", to: "organisations#download_lettings_csv"
      post "lettings-logs/email-csv", to: "organisations#email_lettings_csv"
      get "lettings-logs/csv-confirmation", to: "lettings_logs#csv_confirmation"
      get "sales-logs/csv-download", to: "organisations#download_sales_csv"
      post "sales-logs/email-csv", to: "organisations#email_sales_csv"
      get "sales-logs/csv-confirmation", to: "sales_logs#csv_confirmation"
      get "schemes", to: "organisations#schemes"
      get "schemes/csv-download", to: "organisations#download_schemes_csv"
      post "schemes/email-csv", to: "organisations#email_schemes_csv"
      get "schemes/csv-confirmation", to: "schemes#csv_confirmation"
      get "schemes/duplicates", to: "organisations#duplicate_schemes"
      post "schemes/duplicates", to: "organisations#confirm_duplicate_schemes"
      get "stock-owners", to: "organisation_relationships#stock_owners"
      get "stock-owners/add", to: "organisation_relationships#add_stock_owner"
      get "stock-owners/remove", to: "organisation_relationships#remove_stock_owner"
      post "stock-owners", to: "organisation_relationships#create_stock_owner"
      delete "stock-owners", to: "organisation_relationships#delete_stock_owner"
      get "managing-agents", to: "organisation_relationships#managing_agents"
      get "managing-agents/add", to: "organisation_relationships#add_managing_agent"
      get "managing-agents/remove", to: "organisation_relationships#remove_managing_agent"
      post "managing-agents", to: "organisation_relationships#create_managing_agent"
      delete "managing-agents", to: "organisation_relationships#delete_managing_agent"
      get "merge-request", to: "organisations#merge_request"
      get "deactivate", to: "organisations#deactivate"
      get "reactivate", to: "organisations#reactivate"
      %w[years status needstype assigned-to owned-by managed-by].each do |filter|
        get "lettings-logs/filters/#{filter}", to: "lettings_logs_filters#organisation_#{filter.underscore}"
        get "lettings-logs/filters/update-#{filter}", to: "lettings_logs_filters#update_organisation_#{filter.underscore}"
      end
      %w[years status assigned-to owned-by managed-by].each do |filter|
        get "sales-logs/filters/#{filter}", to: "sales_logs_filters#organisation_#{filter.underscore}"
        get "sales-logs/filters/update-#{filter}", to: "sales_logs_filters#update_organisation_#{filter.underscore}"
      end
      get "delete-confirmation", to: "organisations#delete_confirmation"
      delete "delete", to: "organisations#delete"
    end

    collection do
      get :search
    end
  end

  resources :merge_requests, path: "/merge-request" do
    member do
      get "merging-organisations"
      patch "merging-organisations", to: "merge_requests#update_merging_organisations"
      get "merging-organisations/remove", to: "merge_requests#remove_merging_organisation"
      get "absorbing-organisation"
      get "merge-date"
      get "existing-absorbing-organisation"
      get "helpdesk-ticket"
      get "merge-start-confirmation"
      get "user-outcomes"
      get "relationship-outcomes"
      get "scheme-outcomes"
      get "logs-outcomes"
      get "delete-confirmation", to: "merge_requests#delete_confirmation"
      delete "delete", to: "merge_requests#delete"
      patch "start-merge", to: "merge_requests#start_merge"
    end
  end

  resources :lettings_logs, path: "/lettings-logs" do
    get "delete-confirmation", to: "lettings_logs#delete_confirmation"
    get "duplicate-logs", to: "duplicate_logs#show"
    get "delete-duplicates", to: "duplicate_logs#delete_duplicates"
    post "confirm-clear-answer", to: "check_errors#confirm_clear_answer"
    post "confirm-clear-all-answers", to: "check_errors#confirm_clear_all_answers"

    collection do
      get "csv-download", to: "lettings_logs#download_csv"
      post "email-csv", to: "lettings_logs#email_csv"
      get "csv-confirmation", to: "lettings_logs#csv_confirmation"
      get "bulk-uploads", to: "lettings_logs#bulk_uploads"

      get "delete-logs", to: "delete_logs#delete_lettings_logs"
      post "delete-logs", to: "delete_logs#delete_lettings_logs_with_selected_ids"
      post "delete-logs-confirmation", to: "delete_logs#delete_lettings_logs_confirmation"
      delete "delete-logs", to: "delete_logs#discard_lettings_logs"

      %w[years status needstype assigned-to owned-by managed-by].each do |filter|
        get "filters/#{filter}", to: "lettings_logs_filters##{filter.underscore}"
        get "filters/update-#{filter}", to: "lettings_logs_filters#update_#{filter.underscore}"
      end

      resources :bulk_upload_lettings_logs, path: "bulk-upload-logs", only: %i[show update] do
        collection do
          get :start
        end
      end

      resources :bulk_upload_lettings_results, path: "bulk-upload-results", only: [:show] do
        member do
          get :resume
          get :summary
        end
      end

      resources :bulk_upload_lettings_resume, path: "bulk-upload-resume", only: %i[show update] do
        member do
          get :start

          get "*page", to: "bulk_upload_lettings_resume#show", as: "page"
          patch "*page", to: "bulk_upload_lettings_resume#update"
          get "deletion-report"
        end
      end

      resources :bulk_upload_lettings_soft_validations_check, path: "bulk-upload-soft-validations-check", only: %i[show update] do
        member do
          get "*page", to: "bulk_upload_lettings_soft_validations_check#show", as: "page"
          patch "*page", to: "bulk_upload_lettings_soft_validations_check#update"
        end
      end

      resources :bulk_uploads, path: "bulk-uploads", only: [] do
        member do
          get "download", to: "lettings_logs#download_bulk_upload", as: "download_lettings"
        end
      end

      get "update-logs", to: "lettings_logs#update_logs"
    end

    member do
      post "form", to: "form#submit_form"
      get "review", to: "form#review"
    end

    FormHandler.instance.lettings_forms.each do |_key, form|
      form.pages.map do |page|
        get page.id.to_s.dasherize, to: "form#show_page"
        post page.id.to_s.dasherize, to: "form#submit_form"
      end

      form.subsections.map do |subsection|
        get "#{subsection.id.to_s.dasherize}/check-answers", to: "form#check_answers"
      end
    end
  end

  resources :sales_logs, path: "/sales-logs" do
    get "delete-confirmation", to: "sales_logs#delete_confirmation"
    get "duplicate-logs", to: "duplicate_logs#show"
    get "delete-duplicates", to: "duplicate_logs#delete_duplicates"
    post "confirm-clear-answer", to: "check_errors#confirm_clear_answer"
    post "confirm-clear-all-answers", to: "check_errors#confirm_clear_all_answers"

    collection do
      get "csv-download", to: "sales_logs#download_csv"
      post "email-csv", to: "sales_logs#email_csv"
      get "csv-confirmation", to: "sales_logs#csv_confirmation"
      get "bulk-uploads", to: "sales_logs#bulk_uploads"

      get "delete-logs", to: "delete_logs#delete_sales_logs"
      post "delete-logs", to: "delete_logs#delete_sales_logs_with_selected_ids"
      post "delete-logs-confirmation", to: "delete_logs#delete_sales_logs_confirmation"
      delete "delete-logs", to: "delete_logs#discard_sales_logs"

      %w[years status assigned-to owned-by managed-by].each do |filter|
        get "filters/#{filter}", to: "sales_logs_filters##{filter.underscore}"
        get "filters/update-#{filter}", to: "sales_logs_filters#update_#{filter.underscore}"
      end

      resources :bulk_upload_sales_logs, path: "bulk-upload-logs" do
        collection do
          get :start
        end
      end

      resources :bulk_upload_sales_results, path: "bulk-upload-results", only: [:show] do
        member do
          get :resume
          get :summary
        end
      end

      resources :bulk_upload_sales_resume, path: "bulk-upload-resume", only: %i[show update] do
        member do
          get :start

          get "*page", to: "bulk_upload_sales_resume#show", as: "page"
          patch "*page", to: "bulk_upload_sales_resume#update"
          get "deletion-report"
        end
      end

      resources :bulk_upload_sales_soft_validations_check, path: "bulk-upload-soft-validations-check", only: %i[show update] do
        member do
          get "*page", to: "bulk_upload_sales_soft_validations_check#show", as: "page"
          patch "*page", to: "bulk_upload_sales_soft_validations_check#update"
        end
      end

      resources :bulk_uploads, path: "bulk-uploads", only: [] do
        member do
          get "download", to: "sales_logs#download_bulk_upload", as: "download-sales"
        end
      end
    end

    member do
      get "review", to: "form#review"
    end

    FormHandler.instance.sales_forms.each do |_key, form|
      form.pages.map do |page|
        get page.id.to_s.dasherize, to: "form#show_page"
        post page.id.to_s.dasherize, to: "form#submit_form"
      end

      form.subsections.map do |subsection|
        get "#{subsection.id.to_s.dasherize}/check-answers", to: "form#check_answers"
      end
    end
  end

  resources :csv_downloads, path: "csv-downloads" do
    member do
      get "/", to: "csv_downloads#show", as: "show"
      get "download", to: "csv_downloads#download"
    end
  end

  scope via: :all do
    match "/404", to: "errors#not_found"
    match "/429", to: "errors#too_many_requests", status: 429
    match "/422", to: "errors#unprocessable_entity"
    match "/500", to: "errors#internal_server_error"
  end

  if FeatureToggle.create_test_logs_enabled?
    get "create-test-lettings-log", to: "test_data#create_test_lettings_log"
    get "create-setup-test-lettings-log", to: "test_data#create_setup_test_lettings_log"
    get "create-2024-test-lettings-bulk-upload", to: "test_data#create_2024_test_lettings_bulk_upload"
    get "create-2025-test-lettings-bulk-upload", to: "test_data#create_2025_test_lettings_bulk_upload"
    get "create-test-sales-log", to: "test_data#create_test_sales_log"
    get "create-setup-test-sales-log", to: "test_data#create_setup_test_sales_log"
    get "create-2024-test-sales-bulk-upload", to: "test_data#create_2024_test_sales_bulk_upload"
    get "create-2025-test-sales-bulk-upload", to: "test_data#create_2025_test_sales_bulk_upload"
  end
end
