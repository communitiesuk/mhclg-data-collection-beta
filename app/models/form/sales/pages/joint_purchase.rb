class Form::Sales::Pages::JointPurchase < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "joint_purchase"
    @copy_key = "sales.setup.jointpur"
    @depends_on = [
      { "ownershipsch" => 1 },
      { "ownershipsch" => 2 },
      { "companybuy" => 2 },
    ]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::JointPurchase.new(nil, nil, self),
    ]
  end
end
