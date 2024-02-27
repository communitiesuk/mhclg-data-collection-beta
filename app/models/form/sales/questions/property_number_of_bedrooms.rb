class Form::Sales::Questions::PropertyNumberOfBedrooms < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "beds"
    @check_answer_label = "Number of bedrooms"
    @header = "How many bedrooms does the property have?"
    @hint_text = "A bedsit has 1 bedroom"
    @type = "numeric"
    @width = 2
    @min = 1
    @max = 9
    @step = 1
    @question_number = 11
  end
end
