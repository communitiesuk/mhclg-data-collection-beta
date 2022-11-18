module InterruptionScreenHelper
  def display_informative_text(informative_text, lettings_log)
    return "" unless informative_text["arguments"]

    translation_params = {}
    informative_text["arguments"].each do |argument|
      value = if argument["label"]
                question = lettings_log.form.get_question(argument["key"], lettings_log)
                answer = Answer.new(question:, log: lettings_log)
                pre_casing_value = answer.answer_label
                pre_casing_value.downcase
              else
                lettings_log.public_send(argument["key"])
              end
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

  def display_title_text(title_text, lettings_log)
    return "" if title_text.nil?

    translation_params = {}
    arguments = title_text["arguments"] || {}
    arguments.each do |argument|
      value = if argument["label"]
                question = lettings_log.form.get_question(argument["key"], lettings_log)
                answer = Answer.new(question:, log: lettings_log)
                answer.answer_label.downcase
              else
                lettings_log.public_send(argument["key"])
              end
      translation_params[argument["i18n_template"].to_sym] = value
    end
    I18n.t(title_text["translation"], **translation_params).to_s
  end
end
