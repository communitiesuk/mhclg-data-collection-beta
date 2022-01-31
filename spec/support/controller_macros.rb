module ControllerMacros
  def login_user
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = FactoryBot.create(:user)
      sign_in user
    end
  end

  def login_admin_user
    before do
      @request.env["devise.mapping"] = Devise.mappings[:admin_user]
      admin_user = FactoryBot.create(:admin_user)
      sign_in admin_user
    end
  end
end
