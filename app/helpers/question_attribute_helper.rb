module QuestionAttributeHelper
  def stimulus_html_attributes(question)
    attribs = [
      numeric_question_html_attributes(question),
      conditional_html_attributes(question),
    ]
    merge_controller_attributes(*attribs)
  end

private

  def numeric_question_html_attributes(question)
    return { "style": "background-color: #f3f2f1;" } if question.read_only?
    return {} if question.fields_to_add.blank? || question.result_field.blank?

    {
      "data-controller": "numeric-question",
      "data-action": "numeric-question#calculateFields",
      "data-target": "case-log-#{question.result_field.to_s.dasherize}-field",
      "data-calculated": question.fields_to_add.to_json,
    }
  end

  def conditional_html_attributes(question)
    return {} if question.conditional_for.blank?

    {
      "data-controller": "conditional-question",
      "data-action": "conditional-question#displayConditional",
      "data-info": question.conditional_for.to_json,
    }
  end
end

def merge_controller_attributes(*args)
  args.flat_map(&:keys).uniq.each_with_object({}) do |key, hsh|
    hsh[key] = args.map { |a| a.fetch(key, "") }.join(" ").strip
    hsh
  end
end
