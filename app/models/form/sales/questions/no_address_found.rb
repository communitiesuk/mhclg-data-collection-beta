class Form::Sales::Questions::NoAddressFound < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "address_search_value_check"
    @header = "No address found"
    @type = "interruption_screen"
    @hidden_in_check_answers = true
  end
end
