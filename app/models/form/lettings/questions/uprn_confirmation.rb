class Form::Lettings::Questions::UprnConfirmation < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "uprn_confirmed"
    @header = "Is this the property address?"
    @type = "radio"
    @check_answer_label = "Is this the right address?"
  end

  def answer_options
    if form.start_year_after_2024?
      {
        "1" => { "value" => "Yes" },
        "0" => { "value" => "No, I want to search for the address instead" },
      }.freeze
    else
      {
        "1" => { "value" => "Yes" },
        "0" => { "value" => "No, I want to enter the address manually" },
      }.freeze
    end
  end

  def notification_banner(log = nil)
    return unless log&.uprn

    {
      title: "UPRN: #{log.uprn}",
      heading: [
        log.address_line1,
        log.address_line2,
        log.postcode_full,
        log.town_or_city,
        log.county,
      ].select(&:present?).join("\n"),
    }
  end

  def hidden_in_check_answers?(log, _current_user = nil)
    log.uprn_known != 1 || log.uprn_confirmed.present?
  end
end
