class Form::Lettings::Pages::ReferralJustice < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "referral_justice"
    @depends_on = [{ "referral_type" => 105 }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::ReferralJustice.new(nil, nil, self)]
  end
end
