module FormattingHelper
  def format_ending(text)
    return text if text.blank?

    first_word = text.split.first
    modified_text = first_word == first_word.upcase ? text : lowercase_first_letter(text)
    ensure_sentence_ending(modified_text)
  end

  def ensure_sentence_ending(text)
    return text if text.blank?

    ends_with_any_punctuation = text.match?(/[[:punct:]]\z/)
    ends_with_special_char = text.match?(/[%(){}\[\]]\z/)

    ends_with_any_punctuation && !ends_with_special_char ? text : "#{text}."
  end

  def lowercase_first_letter(text)
    return text if text.blank?

    text[0].downcase + text[1..]
  end
end
