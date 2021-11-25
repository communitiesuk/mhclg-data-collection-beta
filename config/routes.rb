Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users, controllers: { passwords: "users/passwords" }, skip: [:registrations]
  devise_scope :user do
    get "confirmations/reset", to: "users/passwords#reset_confirmation"
    get "users/edit" => "devise/registrations#edit", :as => "edit_user_registration"
    patch "users" => "users/registrations#update", :as => "user_registration"
    patch "details" => "users/account#update", :as => "account_update"
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  ActiveAdmin.routes(self)
  root to: "test#index"
  get "about", to: "about#index"
  get "/users/account", to: "users/account#index"
  get "/users/account/personal_details", to: "users/account#personal_details"

  form_handler = FormHandler.instance
  form = form_handler.get_form("2021_2022")

  resources :case_logs do
    collection do
      post "/bulk_upload", to: "bulk_upload#bulk_upload"
      get "/bulk_upload", to: "bulk_upload#show"
    end

    member do
      post "/form", to: "case_logs#submit_form"
    end

    form.pages.map do |page|
      get page.id.to_s, to: "case_logs##{page.id}"
      get "#{page.id}/soft_validations", to: "soft_validations#show" if page.has_soft_validations?
    end

    form.subsections.map do |subsection|
      get "#{subsection.id}/check_answers", to: "case_logs#check_answers"
    end
  end
end
