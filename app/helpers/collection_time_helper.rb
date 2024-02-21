module CollectionTimeHelper
  def collection_start_year_for_date(date)
    window_end_date = Time.zone.local(date.year, 4, 1)
    date < window_end_date ? date.year - 1 : date.year
  end

  def current_collection_start_year
    collection_start_year_for_date(Time.zone.now)
  end

  def collection_start_date(date)
    Time.zone.local(collection_start_year_for_date(date), 4, 1)
  end

  def date_mid_collection_year_formatted(date)
    relevant_year = date.nil? ? current_collection_start_year : collection_start_year_for_date(date)
    example_date = Date.new(relevant_year, 9, 13)
    example_date.to_formatted_s(:govuk_date_number_month)
  end

  def current_collection_start_date
    Time.zone.local(current_collection_start_year, 4, 1)
  end

  def collection_end_date(date)
    Time.zone.local(collection_start_year_for_date(date) + 1, 3, 31).end_of_day
  end

  def current_collection_end_date
    Time.zone.local(current_collection_start_year + 1, 3, 31).end_of_day
  end

  def previous_collection_end_date
    current_collection_end_date - 1.year
  end

  def next_collection_start_year
    current_collection_start_year + 1
  end

  def previous_collection_start_year
    current_collection_start_year - 1
  end

  def previous_collection_start_date
    current_collection_start_date - 1.year
  end

  def archived_collection_start_year
    current_collection_start_year - 2
  end

  def quarter_for_date(date: Time.zone.now)
    quarters = [
      { quarter: "Q3", cutoff_date: Time.zone.local(2024, 1, 12), start_date: Time.zone.local(2023, 10, 1), end_date: Time.zone.local(2023, 12, 31) },
      { quarter: "Q1", cutoff_date: Time.zone.local(2024, 7, 12), start_date: Time.zone.local(2024, 4, 1), end_date: Time.zone.local(2024, 6, 30) },
      { quarter: "Q2", cutoff_date: Time.zone.local(2024, 10, 11), start_date: Time.zone.local(2024, 7, 1), end_date: Time.zone.local(2024, 9, 30) },
      { quarter: "Q3", cutoff_date: Time.zone.local(2025, 1, 10), start_date: Time.zone.local(2024, 10, 1), end_date: Time.zone.local(2024, 12, 31) },
    ]

    quarter = quarters.find { |q| date.between?(q[:start_date], q[:cutoff_date] + 1.day) }

    return unless quarter

    OpenStruct.new(
      quarter: quarter[:quarter],
      cutoff_date: quarter[:cutoff_date],
      quarter_start_date: quarter[:start_date],
      quarter_end_date: quarter[:end_date],
    )
  end
end
