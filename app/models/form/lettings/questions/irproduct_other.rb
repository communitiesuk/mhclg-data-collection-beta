class Form::Lettings::Questions::IrproductOther < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "irproduct_other"
    @check_answer_label = "Product name"
    @header = "Name of rent product"
    @type = "text"
    @question_number = 6
  end
end
