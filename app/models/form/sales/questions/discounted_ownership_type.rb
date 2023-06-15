class Form::Sales::Questions::DiscountedOwnershipType < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "type"
    @check_answer_label = "Type of discounted ownership sale"
    @header = "What is the type of discounted ownership sale?"
    @type = "radio"
    @guidance_partial = "discounted_ownership_type_definitions"
    @guidance_position = GuidancePosition::TOP
    @answer_options = ANSWER_OPTIONS
    @question_number = 5
  end

  ANSWER_OPTIONS = {
    "8" => { "value" => "Right to Acquire (RTA)" },
    "14" => { "value" => "Preserved Right to Buy (PRTB)" },
    "27" => { "value" => "Voluntary Right to Buy (VRTB)" },
    "9" => { "value" => "Right to Buy (RTB)" },
    "29" => { "value" => "Rent to Buy - Full Ownership" },
    "21" => { "value" => "Social HomeBuy for outright purchase" },
    "22" => { "value" => "Any other equity loan scheme" },
  }.freeze
end
