class Form::Setup::Questions::SchemeId < ::Form::Question
  def initialize(_id, hsh, page)
    super("scheme_id", hsh, page)
    @check_answer_label = "Scheme name"
    @header = "What scheme is this log for?"
    @hint_text = "Enter scheme name or postcode"
    @type = "select"
    @answer_options = answer_options
    @derived = true unless FeatureToggle.supported_housing_schemes_enabled?
  end

  def answer_options
    answer_opts = {}
    return answer_opts unless ActiveRecord::Base.connected?

    Scheme.select(:id, :service_name).each_with_object(answer_opts) do |scheme, hsh|
      hsh[scheme.id.to_s] = scheme.service_name
      hsh
    end
  end

  def displayed_answer_options(case_log)
    return {} unless case_log.created_by

    user_org_scheme_ids = Scheme.select(:id).where(organisation_id: case_log.created_by.organisation_id).map(&:id)
    answer_options.select do |k, _v|
      user_org_scheme_ids.include?(k.to_i)
    end
  end

  def hidden_in_check_answers?(case_log, _current_user = nil)
    !supported_housing_selected?(case_log)
  end

private

  def supported_housing_selected?(case_log)
    case_log.needstype == 2
  end
end
