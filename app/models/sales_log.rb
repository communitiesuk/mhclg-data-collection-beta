class SalesLogValidator < ActiveModel::Validator
  def validate(record); end
end

class SalesLog < Log
  has_paper_trail

  validates_with SalesLogValidator
  before_save :update_status!

  scope :filter_by_organisation, ->(org, _user = nil) { where(owning_organisation: org).or(where(managing_organisation: org)) }

  STATUS = { "not_started" => 0, "in_progress" => 1, "completed" => 2 }.freeze
  enum status: STATUS

  def self.editable_fields
    attribute_names
  end

  def form_name
    return unless saledate

    "#{collection_start_year}_#{collection_start_year + 1}_sales"
  end

  def collection_start_year
    return @sale_year if @sale_year
    return unless saledate

    window_end_date = Time.zone.local(saledate.year, 4, 1)
    @sale_year = saledate < window_end_date ? saledate.year - 1 : saledate.year
  end

  def form
    FormHandler.instance.get_form(form_name) || FormHandler.instance.get_form("2022_2023_sales")
  end

  def optional_fields
    []
  end

  def not_started?
    status == "not_started"
  end

  def completed?
    status == "completed"
  end
end
