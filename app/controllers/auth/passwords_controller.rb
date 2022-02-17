class Auth::PasswordsController < Devise::PasswordsController
  include Helpers::Email

  def reset_confirmation
    self.resource = resource_class.new
    @email = params["email"]
    if @email.empty?
      resource.errors.add :email, "Enter an email address"
      render "devise/passwords/new", status: :unprocessable_entity
    elsif !email_valid?(@email)
      resource.errors.add :email, "Enter an email address in the correct format, like name@example.com"
      render "devise/passwords/new", status: :unprocessable_entity
    else
      render "devise/confirmations/reset"
    end
  end

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
  end

  def edit
    super
    render "devise/passwords/reset_password"
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if Devise.sign_in_after_reset_password
        set_flash_message!(:notice, password_update_flash_message)
        resource.after_database_authentication
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      respond_with resource, status: :unprocessable_entity
    end
  end

protected

  def password_update_flash_message
    resource_class == AdminUser ? :updated_2FA : :updated
  end

  def resource_class_name
    resource_class.name.underscore
  end

  def after_sending_reset_password_instructions_path_for(_resource)
    confirmations_reset_path(email: params.dig(resource_class_name, "email"))
  end

  def after_resetting_password_path_for(resource)
    if Devise.sign_in_after_reset_password
      if resource_class == AdminUser
        resource.send_new_otp
        admin_user_two_factor_authentication_path
      else
        after_sign_in_path_for(resource)
      end
    else
      new_session_path(resource_name)
    end
  end
end
