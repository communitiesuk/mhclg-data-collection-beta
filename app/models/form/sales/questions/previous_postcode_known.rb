class Form::Sales::Questions::PreviousPostcodeKnown < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "ppcodenk"
    @check_answer_label = "Buyer 1’s last settled accommodation"
    @header = "Do you know the postcode of buyer 1’s last settled accommodation?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @page = page
    @conditional_for = {
      "ppostcode_full" => [0],
    }
  end

  ANSWER_OPTIONS = {
    "0" => { "value" => "Yes" },
    "1" => { "value" => "No" },
  }.freeze
end
