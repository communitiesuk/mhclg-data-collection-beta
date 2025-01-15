class Form::Question
  include FormattingHelper

  attr_accessor :id, :description, :questions, :disable_clearing_if_not_routed_or_dynamic_answer_options,
                :type, :min, :max, :step, :width, :fields_to_add, :result_field,
                :conditional_for, :readonly, :answer_options, :page,
                :inferred_answers, :hidden_in_check_answers, :inferred_check_answers_value,
                :top_guidance_partial, :bottom_guidance_partial, :prefix, :suffix,
                :requires_js, :fields_added, :derived, :check_answers_card_number,
                :unresolved_hint_text, :question_number, :hide_question_number_on_page,
                :plain_label, :error_label

  def initialize(id, hsh, page)
    @id = id
    @page = page
    if hsh
      @check_answer_label = hsh["check_answer_label"]
      @check_answer_prompt = hsh["check_answer_prompt"]
      @header = hsh["header"]
      @top_guidance_partial = hsh["top_guidance_partial"]
      @bottom_guidance_partial = hsh["bottom_guidance_partial"]
      @hint_text = hsh["hint_text"]
      @type = hsh["type"]
      @min = hsh["min"]
      @max = hsh["max"]
      @step = hsh["step"]
      @width = hsh["width"]
      @fields_to_add = hsh["fields-to-add"]
      @result_field = hsh["result-field"]
      @readonly = hsh["readonly"]
      @answer_options = hsh["answer_options"]
      @conditional_for = hsh["conditional_for"]
      @inferred_answers = hsh["inferred_answers"]
      @inferred_check_answers_value = hsh["inferred_check_answers_value"]
      @hidden_in_check_answers = hsh["hidden_in_check_answers"]
      @derived = hsh["derived"]
      @prefix = hsh["prefix"]
      @suffix = hsh["suffix"]
      @requires_js = hsh["requires_js"]
      @fields_added = hsh["fields_added"]
      @check_answers_card_number = hsh["check_answers_card_number"] || 0
      @unresolved_hint_text = hsh["unresolved_hint_text"]
      @question_number = hsh["question_number"]
      @hide_question_number_on_page = hsh["hide_question_number_on_page"] || false
      @plain_label = hsh["plain_label"]
      @error_label = hsh["error_label"]
      @disable_clearing_if_not_routed_or_dynamic_answer_options = hsh["disable_clearing_if_not_routed_or_dynamic_answer_options"]
    end
  end

  delegate :subsection, to: :page
  delegate :form, to: :subsection

  def copy_key
    @copy_key ||= "#{form.type}.#{subsection.copy_key}.#{id}"
  end

  def check_answer_label
    @check_answer_label ||= I18n.t("forms.#{form.start_date.year}.#{copy_key}.check_answer_label", default: "")
  end

  def check_answer_prompt
    @check_answer_prompt || I18n.t("forms.#{form.start_date.year}.#{copy_key}.check_answer_prompt", default: nil).presence || generate_check_answer_prompt
  end

  def header
    @header ||= I18n.t("forms.#{form.start_date.year}.#{copy_key}.question_text", default: "")
  end

  def hint_text
    @hint_text ||= I18n.t("forms.#{form.start_date.year}.#{copy_key}.hint_text", default: "")
  end

  def answer_label(log, user = nil)
    return checkbox_answer_label(log) if type == "checkbox"
    return log[id]&.to_formatted_s(:govuk_date).to_s if type == "date"

    answer = label_from_value(log[id], log, user) if log[id].present?
    answer_label = [prefix, format_value(answer), suffix_label(log)].join("") if answer

    inferred_answer_value(log) || answer_label
  end

  def notification_banner(_log = nil); end

  def input_playback(_log = nil); end

  def get_inferred_answers(log)
    return [] unless inferred_answers

    enabled_inferred_answers(inferred_answers, log).keys.map do |question_id|
      question = form.get_question(question_id, log)
      if question.present?
        question.label_from_value(log[question_id])
      else
        Array(question_id.to_s.split(".")).inject(log) { |l, method| l.present? ? l.public_send(*method) : "" }
      end
    end
  end

  def get_extra_check_answer_value(_log)
    nil
  end

  def read_only?
    !!readonly
  end

  def enabled?(log)
    return true if conditional_on.blank?

    conditional_on.all? { |condition| evaluate_condition(condition, log) }
  end

  def hidden_in_check_answers?(log, current_user = nil)
    if hidden_in_check_answers.is_a?(Hash)
      form.depends_on_met(hidden_in_check_answers["depends_on"], log)
    else
      hidden_in_check_answers || !page.routed_to?(log, current_user)
    end
  end

  def displayed_to_user?(log)
    page.routed_to?(log, nil) && enabled?(log)
  end

  def derived?(_log)
    !!derived
  end

  def displayed_answer_options(log, _current_user = nil)
    answer_options.select do |_key, val|
      !val.is_a?(Hash) || !val["depends_on"] || form.depends_on_met(val["depends_on"], log)
    end
  end

  def action_text(log, correcting_hard_validation: false)
    return "" unless displayed_as_answered?(log)

    correcting_hard_validation ? "Clear" : "Change"
  end

  def displayed_as_answered?(log)
    if is_derived_or_has_inferred_check_answers_value?(log)
      true
    elsif type == "checkbox"
      answer_options.keys.any? { |key| value_is_yes?(log[key]) }
    else
      log[id].present?
    end
  end

  def unanswered?(log)
    return answer_options.keys.none? { |key| value_is_yes?(log[key]) } if type == "checkbox"

    log[id].blank?
  end

  def completed?(log)
    return answer_options.keys.any? { |key| value_is_yes?(log[key]) } if type == "checkbox"

    log[id].present? || !log.respond_to?(id.to_sym) || has_inferred_display_value?(log)
  end

  def value_from_label(label)
    return unless label

    case type
    when "radio"
      answer_options.find { |opt| opt.second["value"] == label.to_s }.first
    when "select"
      answer_options.find { |opt| opt.second == label.to_s }.first
    else
      label
    end
  end

  def label_from_value(value, _log = nil, _user = nil)
    return unless value

    label = case type
            when "radio"
              labels = answer_options[value.to_s]
              labels["value"] if labels
            when "select"
              if answer_options[value.to_s].respond_to?(:service_name)
                answer_options[value.to_s].service_name
              elsif answer_options[value.to_s].is_a?(Location)
                answer_options[value.to_s].postcode
              else
                answer_options[value.to_s]
              end
            else
              value.to_s
            end
    label || value.to_s
  end

  def value_is_yes?(value)
    case type
    when "checkbox"
      value == 1
    when "radio"
      RADIO_YES_VALUE[id.to_sym]&.include?(value)
    else
      %w[yes].include?(value.downcase)
    end
  end

  def value_is_no?(value)
    case type
    when "checkbox"
      value && value.zero?
    when "radio"
      is_lettings ? RADIO_NO_VALUE_LETTINGS[id.to_sym]&.include?(value) : RADIO_NO_VALUE_SALES[id.to_sym]&.include?(value)
    else
      %w[no].include?(value.downcase)
    end
  end

  def value_is_dont_know?(value)
    type == "radio" && RADIO_DONT_KNOW_VALUE[id.to_sym]&.include?(value)
  end

  def value_is_refused?(value)
    type == "radio" && RADIO_REFUSED_VALUE[id.to_sym]&.include?(value)
  end

  def error_display_label
    label = if error_label.present?
              error_label
            elsif check_answer_label.present?
              check_answer_label
            elsif header.present?
              header
            else
              id.humanize
            end
    format_ending(label)
  end

  def unanswered_error_message
    question_text = error_display_label.presence || "this question."
    I18n.t("validations.not_answered", question: question_text.downcase)
  end

  def generate_check_answer_prompt
    prompt_ending = lowercase_first_letter(error_label.presence || check_answer_label.presence || header.presence || id.humanize) || "this question."
    return "Select #{prompt_ending}" if %w[checkbox radio select].include?(type)
    return "Set #{prompt_ending}" if type == "date"

    "Enter #{prompt_ending}"
  end

  def suffix_label(log)
    return "" unless suffix
    return suffix if suffix.is_a?(String)

    label = ""

    suffix.each do |s|
      condition = s["depends_on"]
      next unless condition

      answer = log.send(condition.keys.first)
      if answer == condition.values.first
        label = s["label"]
      end
    end
    label
  end

  def answer_selected?(log, answer)
    return false unless type == "select"

    log[id].to_s == answer.id.to_s
  end

  def top_guidance?
    @top_guidance_partial.present?
  end

  def bottom_guidance?
    @bottom_guidance_partial.present?
  end

  def is_derived_or_has_inferred_check_answers_value?(log)
    selected_answer_option_is_derived?(log) || has_inferred_check_answers_value?(log)
  end

  def question_number_string(hidden: false)
    if @question_number && !hidden
      "Q#{@question_number}"
    end
  end

  def answer_keys_without_dividers
    answer_options.keys.reject { |x| x.match(/divider/) }
  end

private

  def selected_answer_option_is_derived?(log)
    selected_option = answer_options&.dig(log[id].to_s.presence)
    selected_option.is_a?(Hash) && selected_option["depends_on"] && form.depends_on_met(selected_option["depends_on"], log)
  end

  def has_inferred_check_answers_value?(log)
    return false unless inferred_check_answers_value

    inferred_check_answers_value&.any? { |inferred_value| log[inferred_value["condition"].keys.first] == inferred_value["condition"].values.first }
  end

  def has_inferred_display_value?(log)
    inferred_check_answers_value.present? && inferred_check_answers_value.any? { |inferred_value| log[inferred_value["condition"].keys.first] == inferred_value["condition"].values.first }
  end

  def checkbox_answer_label(log)
    answer = []
    return "Yes" if id == "declaration" && value_is_yes?(log["declaration"])

    answer_options.each { |key, options| value_is_yes?(log[key]) ? answer << options["value"] : nil }
    answer.join(", ")
  end

  def format_value(answer_label)
    prefix == "£" ? ActionController::Base.helpers.number_to_currency(answer_label, delimiter: ",", format: "%n") : answer_label
  end

  def conditional_on
    @conditional_on ||= form.conditional_question_conditions.select do |condition|
      condition[:to] == id
    end
  end

  def evaluate_condition(condition, log)
    case page.questions.find { |q| q.id == condition[:from] }.type
    when "numeric"
      operator = condition[:cond][/[<>=]+/].to_sym
      operand = condition[:cond][/\d+/].to_i
      log[condition[:from]].present? && log[condition[:from]].send(operator, operand)
    when "text", "radio", "select"
      log[condition[:from]].present? && condition[:cond].include?(log[condition[:from]])
    else
      raise "Not implemented yet"
    end
  end

  def enabled_inferred_answers(inferred_answers, log)
    inferred_answers.filter do |_attribute, condition|
      condition.all? do |condition_key, condition_value|
        log.public_send(condition_key) == condition_value
      end
    end
  end

  def inferred_answer_value(log)
    return unless inferred_check_answers_value

    inferred_answer = inferred_check_answers_value.find { |inferred_value| log[inferred_value["condition"].keys.first] == inferred_value["condition"].values.first }
    inferred_answer["value"] if inferred_answer.present?
  end

  RADIO_YES_VALUE = {
    renewal: [1],
    postcode_known: [1],
    pcodenk: [0],
    previous_la_known: [1],
    first_time_property_let_as_social_housing: [1],
    wchair: [1],
    majorrepairs: [1],
    startertenancy: [0],
    sheltered: [0, 1],
    armedforces: [1, 4, 5],
    leftreg: [6],
    reservist: [1],
    preg_occ: [1],
    illness: [1],
    underoccupation_benefitcap: [4, 5, 6],
    reasonpref: [1],
    net_income_known: [0],
    household_charge: [0],
    is_carehome: [1],
    hbrentshortfall: [1],
    net_income_value_check: [0],
    ppcodenk: [0],
  }.freeze

  RADIO_NO_VALUE = {
    renewal: [0],
    postcode_known: [0],
    pcodenk: [1],
    previous_la_known: [0],
    first_time_property_let_as_social_housing: [0],
    wchair: [0],
    majorrepairs: [0],
    startertenancy: [1],
    sheltered: [2],
    armedforces: [2],
    leftreg: [4],
    reservist: [2],
    preg_occ: [2],
    illness: [2],
    underoccupation_benefitcap: [2],
    reasonpref: [2],
    net_income_known: [1],
    household_charge: [1],
    is_carehome: [0],
    hbrentshortfall: [2],
    net_income_value_check: [1],
    ppcodenk: [1],
  }.freeze

  RADIO_DONT_KNOW_VALUE = {
    sheltered: [3],
    underoccupation_benefitcap: [3],
    reasonpref: [3],
    hbrentshortfall: [3],
    layear: [7],
    reason_for_leaving_last_settled_home: [32],
    hb: [5],
    benefits: [3],
    unitletas: [3],
    illness: [3],
  }.freeze

  RADIO_REFUSED_VALUE = {
    sex1: %w[R],
    sex2: %w[R],
    sex3: %w[R],
    sex4: %w[R],
    sex5: %w[R],
    sex6: %w[R],
    sex7: %w[R],
    sex8: %w[R],
    relat2: [3],
    relat3: [3],
    relat4: [3],
    relat5: [3],
    relat6: [3],
    relat7: [3],
    relat8: [3],
    ecstat1: [10],
    ecstat2: [10],
    ecstat3: [10],
    ecstat4: [10],
    ecstat5: [10],
    ecstat6: [10],
    ecstat7: [10],
    ecstat8: [10],
    sheltered: [3],
    armedforces: [3],
    leftreg: [3],
    reservist: [3],
    preg_occ: [3],
    hb: [6],
  }.freeze
end
