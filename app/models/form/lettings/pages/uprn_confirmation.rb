class Form::Lettings::Pages::UprnConfirmation < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "uprn_confirmation"
    @header = "We found an address that might be this property"
  end

  def questions
    @questions ||= [
      Form::Lettings::Questions::UprnConfirmation.new(nil, nil, self),
    ]
  end

  def routed_to?(log, _current_user = nil)
    return false if form.start_year_2024_or_later?

    log.uprn.present? && log.uprn_known == 1
  end
end
