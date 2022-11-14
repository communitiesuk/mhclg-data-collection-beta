class Form::Common::Questions::OwningOrganisationId < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "owning_organisation_id"
    @check_answer_label = "Owning organisation"
    @header = "Which organisation owns this log?"
    @hint_text = ""
    @type = "select"
    @page = page
  end

  def answer_options
    answer_opts = { "" => "Select an option" }
    return answer_opts unless ActiveRecord::Base.connected?

    Organisation.select(:id, :name).each_with_object(answer_opts) do |organisation, hsh|
      hsh[organisation.id] = organisation.name
      hsh
    end
  end

  def displayed_answer_options(_log, _user = nil)
    answer_options
  end

  def label_from_value(value)
    return unless value

    answer_options[value]
  end

  def hidden_in_check_answers?(_log, current_user)
    !current_user.support?
  end

  def derived?
    true
  end

private

  def selected_answer_option_is_derived?(_log)
    false
  end
end
