module Imports
  class UserImportService < ImportService
    def create_users(folder)
      import_from(folder, :create_user)
    end

  private

    PROVIDER_TYPE = {
      "Data Provider" => User.roles[:data_provider],
    }.freeze

    def create_user(xml_document)
      organisation = Organisation.find_by(old_org_id: user_field_value(xml_document, "institution"))
      old_user_id = user_field_value(xml_document, "id")
      email = user_field_value(xml_document, "email").downcase.strip
      name = user_field_value(xml_document, "full-name") || email
      deleted = user_field_value(xml_document, "deleted")

      if LegacyUser.find_by(old_user_id:)
        @logger.warn("User #{name} with old user id #{old_user_id} is already present, skipping.")
      elsif deleted == "true"
        @logger.warn("User #{name} with old user id #{old_user_id} is deleted, skipping.")
      elsif (user = User.find_by(email:, organisation:))
        is_dpo = user.is_data_protection_officer? || is_dpo?(user_field_value(xml_document, "user-type"))
        role = highest_role(user.role, role(user_field_value(xml_document, "user-type")))
        user.update!(role:, is_dpo:)
        user.legacy_users.create!(old_user_id:)
      else
        user = User.new
        user.email = email
        user.name = name
        user.password = Devise.friendly_token
        user.phone = user_field_value(xml_document, "telephone-no")
        user.organisation = organisation
        user.role = role(user_field_value(xml_document, "user-type"))
        user.is_dpo = is_dpo?(user_field_value(xml_document, "user-type"))
        user.is_key_contact = is_key_contact?(user_field_value(xml_document, "contact-priority-id"))
        user.active = user_field_value(xml_document, "active")

        user.skip_confirmation_notification!

        begin
          user.save!
          user.legacy_users.create!(old_user_id:)
          user
        rescue ActiveRecord::RecordInvalid => e
          @logger.error(e.message)
          @logger.error("Could not save user with email: #{email}")
        end
      end
    end

    def user_field_value(xml_document, field)
      field_value(xml_document, "user", field, { "user" => "dclg:user" })
    end

    def role(field_value)
      return unless field_value

      {
        "co-ordinator" => "data_coordinator",
        "data provider" => "data_provider",
        "private data downloader" => "data_accessor",
      }[field_value.downcase.strip]
    end

    def highest_role(role_a, role_b)
      return unless role_a || role_b
      return role_a unless role_b
      return role_b unless role_a

      [role_a, role_b].map(&:to_sym).sort! { |a, b| User::ROLES[b] <=> User::ROLES[a] }.first
    end

    def is_dpo?(field_value)
      return false if field_value.blank?

      field_value.downcase.strip == "data protection officer"
    end

    def is_key_contact?(field_value)
      return false if field_value.blank?

      ["ecore contact", "key performance contact"].include?(field_value.downcase.strip)
    end
  end
end
