module UserHelper
  def aliased_user_edit(user, current_user)
    current_user == user ? edit_account_path : edit_user_path(user)
  end

  def perspective(user, current_user)
    current_user == user ? "Are you" : "Is this person"
  end

  def can_edit_names?(user, current_user)
    (current_user == user || current_user.data_coordinator? || current_user.support?) && user.active?
  end

  def can_edit_emails?(user, current_user)
    (current_user == user || current_user.data_coordinator? || current_user.support?) && user.active?
  end

  def can_edit_password?(user, current_user)
    current_user == user
  end

  def can_edit_roles?(user, current_user)
    (current_user.data_coordinator? || current_user.support?) && user.active?
  end

  def can_edit_dpo?(user, current_user)
    (current_user.data_coordinator? || current_user.support?) && user.active?
  end

  def can_edit_key_contact?(user, current_user)
    (current_user.data_coordinator? || current_user.support?) && user.active?
  end

  def can_edit_org?(current_user)
    current_user.data_coordinator? || current_user.support?
  end
end
