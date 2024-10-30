module InterruptionScreenHelper
  def display_informative_text(informative_text, log)
    return informative_text if informative_text.is_a? String
    return "" if informative_text.nil?
    return "" unless informative_text["arguments"]

    translation_params = {}
    informative_text["arguments"].each do |argument|
      value = get_value_from_argument(log, argument)
      translation_params[argument["i18n_template"].to_sym] = value
    end

    begin
      translation = I18n.t(informative_text["translation"], **translation_params)
      translation.to_s.html_safe
    rescue I18n::MissingInterpolationArgument => e
      Rails.logger.error(e.message)
      ""
    end
  end

  def display_title_text(title_text, log)
    return "" if title_text.nil?

    translation_params = {}
    arguments = title_text["arguments"] || {}
    arguments.each do |argument|
      value = get_value_from_argument(log, argument)
      translation_params[argument["i18n_template"].to_sym] = value
    end
    I18n.t(title_text["translation"], **translation_params).to_s
  end

  def soft_validation_affected_questions(question, log)
    question.page.interruption_screen_question_ids.map { |question_id| log.form.get_question(question_id, log) }.compact
  end

private

  def get_value_from_argument(log, argument)
    if argument["label"]
      log.form.get_question(argument["key"], log).answer_label(log).downcase
    elsif argument["arguments_for_key"]
      log.public_send(argument["key"], argument["arguments_for_key"])
    else
      log.public_send(argument["key"])
    end
  end
end
