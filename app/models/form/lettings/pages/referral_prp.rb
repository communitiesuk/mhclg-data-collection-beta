class Form::Lettings::Pages::ReferralPrp < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "referral_prp"
    @depends_on = [{ "referral_type" => 103 }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::ReferralPrp.new(nil, nil, self)]
  end
end
