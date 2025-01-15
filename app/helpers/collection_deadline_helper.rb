module CollectionDeadlineHelper
  include CollectionTimeHelper

  QUARTERLY_DEADLINES = {
    2024 => {
      first_quarter_deadline: Time.zone.local(2024, 7, 12),
      second_quarter_deadline: Time.zone.local(2024, 10, 11),
      third_quarter_deadline: Time.zone.local(2025, 1, 10),
      fourth_quarter_deadline: Time.zone.local(2025, 6, 6), # Same as submission deadline
    },
    2025 => {
      first_quarter_deadline: Time.zone.local(2025, 7, 11),
      second_quarter_deadline: Time.zone.local(2025, 10, 10),
      third_quarter_deadline: Time.zone.local(2026, 1, 16),
      fourth_quarter_deadline: Time.zone.local(2026, 6, 5), # Same as submission deadline
    },
  }.freeze

  def quarterly_cutoff_date(quarter, year)
    send("#{quarter}_quarter", year)[:cutoff_date].strftime("%A %-d %B %Y")
  end

  def quarter_deadlines_for_year(year)
    QUARTERLY_DEADLINES[year]
  end

  def first_quarter(year)
    {
      cutoff_date: quarter_deadlines_for_year(year)[:first_quarter_deadline],
      start_date: Time.zone.local(year, 4, 1),
      end_date: Time.zone.local(year, 6, 30),
    }
  end

  def second_quarter(year)
    {
      cutoff_date: quarter_deadlines_for_year(year)[:second_quarter_deadline],
      start_date: Time.zone.local(year, 7, 1),
      end_date: Time.zone.local(year, 9, 30),
    }
  end

  def third_quarter(year)
    {
      cutoff_date: quarter_deadlines_for_year(year)[:third_quarter_deadline],
      start_date: Time.zone.local(year, 10, 1),
      end_date: Time.zone.local(year, 12, 31),
    }
  end

  def fourth_quarter(year)
    {
      cutoff_date: quarter_deadlines_for_year(year)[:fourth_quarter_deadline],
      start_date: Time.zone.local(year + 1, 1, 1),
      end_date: Time.zone.local(year + 1, 3, 31),
    }
  end

  def quarter_dates(year)
    [
      first_quarter(year).merge(quarter: "Q1"),
      second_quarter(year).merge(quarter: "Q2"),
      third_quarter(year).merge(quarter: "Q3"),
    ]
  end

  def quarter_for_date(date: Time.zone.now)
    quarters = quarter_dates(current_collection_start_year)

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
