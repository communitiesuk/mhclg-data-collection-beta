class Form::Lettings::Questions::LocationId < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "location_id"
    @check_answer_label = "Location"
    @header = header_text
    @type = "radio"
    @answer_options = answer_options
    @inferred_answers = {
      "location.name": {
        "needstype": 2,
      },
    }
    @question_number = 10
    @disable_clearing_if_not_routed_or_dynamic_answer_options = true
  end

  def answer_options
    answer_opts = {}
    return answer_opts unless ActiveRecord::Base.connected?

    Location.started_in_2_weeks.select(:id, :postcode, :name).each_with_object(answer_opts) do |location, hsh|
      hsh[location.id.to_s] = { "value" => location.postcode, "hint" => location.name }
      hsh
    end
  end

  def displayed_answer_options(lettings_log, _user = nil)
    return {} unless lettings_log.scheme

    scheme_location_ids = lettings_log.scheme.locations.pluck(:id)
    answer_options.select { |k, _v| scheme_location_ids.include?(k.to_i) }
  end

  def hidden_in_check_answers?(lettings_log, _current_user = nil)
    !supported_housing_selected?(lettings_log)
  end

  def get_extra_check_answer_value(lettings_log)
    lettings_log.form.get_question("la", nil).label_from_value(lettings_log.la)
  end

private

  def supported_housing_selected?(lettings_log)
    lettings_log.needstype == 2
  end

  def selected_answer_option_is_derived?(_lettings_log)
    false
  end

  def header_text
    if form.start_date && form.start_date.year >= 2023
      "Which location is this letting for?"
    else
      "Which location is this log for?"
    end
  end
end
