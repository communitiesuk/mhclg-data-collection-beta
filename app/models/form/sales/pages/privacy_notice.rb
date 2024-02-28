class Form::Sales::Pages::PrivacyNotice < ::Form::Page
  def initialize(id, hsh, subsection, joint_purchase:)
    super(id, hsh, subsection)
    @header = "Department for Levelling Up, Housing and Communities privacy notice"
    @joint_purchase = joint_purchase
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::PrivacyNotice.new(nil, nil, self, joint_purchase: @joint_purchase),
    ]
  end

  def depends_on
    if @joint_purchase
      [{ "joint_purchase?" => true }]
    else
      [{ "not_joint_purchase?" => true }]
    end
  end
end
