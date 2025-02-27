class Form::Lettings::Pages::ReferralHsc < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "referral_hsc"
    @depends_on = [{ "referral_type" => 104 }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::ReferralHsc.new(nil, nil, self)]
  end
end
