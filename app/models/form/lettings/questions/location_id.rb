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
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max] if form.start_date.present?
    @disable_clearing_if_not_routed_or_dynamic_answer_options = true
    @top_guidance_partial = "finding_location"
  end

  def answer_options
    answer_opts = {}
    return answer_opts unless ActiveRecord::Base.connected?

    Location.visible.started_in_2_weeks.select(:id, :postcode, :name).each_with_object(answer_opts) do |location, hsh|
      hsh[location.id.to_s] = { "value" => location.postcode, "hint" => location.name }
      hsh
    end
  end

  def displayed_answer_options(lettings_log, _user = nil)
    return {} unless lettings_log.scheme

    scheme_location_ids = lettings_log.scheme.locations.visible.confirmed.pluck(:id)
    answer_options.select { |k, _v| scheme_location_ids.include?(k.to_i) }
                  .sort_by { |_, v|
                    name = v["hint"].match(/[a-zA-Z].*/).to_s
                    number = v["hint"].match(/\d+/).to_s.to_i
                    [name, number]
                  }.to_h
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

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 10, 2024 => 5 }.freeze
end
