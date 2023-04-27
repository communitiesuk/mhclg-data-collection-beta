class Form::Sales::Pages::GrantValueCheck < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "grant_value_check"
    @depends_on = [
      {
        "grant_outside_common_range?" => true,
      },
    ]
    @title_text = { "translation" => "soft_validations.grant.title_text" }
    @informative_text = {}
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::GrantValueCheck.new(nil, nil, self),
    ]
  end

  def interruption_screen_question_ids
    %w[grant]
  end
end
