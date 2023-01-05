class SalesLogValidator < ActiveModel::Validator
  include Validations::Sales::HouseholdValidations
  include Validations::SharedValidations
  include Validations::Sales::FinancialValidations
  include Validations::LocalAuthorityValidations

  def validate(record)
    validation_methods = public_methods.select { |method| method.starts_with?("validate_") }
    validation_methods.each { |meth| public_send(meth, record) }
  end
end

class SalesLog < Log
  include DerivedVariables::SalesLogVariables
  include Validations::Sales::SoftValidations

  self.inheritance_column = :_type_disabled

  has_paper_trail

  validates_with SalesLogValidator
  before_validation :set_derived_fields!
  before_validation :reset_invalidated_dependent_fields!
  before_validation :process_previous_postcode_changes!, if: :ppostcode_full_changed?
  before_validation :reset_previous_location_fields!, unless: :previous_postcode_known?

  scope :filter_by_year, ->(year) { where(saledate: Time.zone.local(year.to_i, 4, 1)...Time.zone.local(year.to_i + 1, 4, 1)) }
  scope :search_by, ->(param) { filter_by_id(param) }

  OPTIONAL_FIELDS = %w[purchid].freeze

  def startdate
    saledate
  end

  def self.editable_fields
    attribute_names
  end

  def form_name
    return unless saledate

    FormHandler.instance.form_name_from_start_year(collection_start_year, "sales")
  end

  def form
    FormHandler.instance.get_form(form_name) || FormHandler.instance.current_sales_form
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

  def setup_completed?
    form.setup_sections.all? { |sections| sections.subsections.all? { |subsection| subsection.status(self) == :completed } }
  end

  def unresolved
    false
  end

  LONDON_BOROUGHS = %w[
    E09000001
    E09000033
    E09000020
    E09000013
    E09000032
    E09000022
    E09000028
    E09000030
    E09000012
    E09000019
    E09000007
    E09000005
    E09000009
    E09000018
    E09000027
    E09000021
    E09000024
    E09000029
    E09000008
    E09000006
    E09000023
    E09000011
    E09000004
    E09000016
    E09000002
    E09000026
    E09000025
    E09000031
    E09000014
    E09000010
    E09000003
    E09000015
    E09000017
  ].freeze

  def london_property?
    la && LONDON_BOROUGHS.include?(la)
  end

  def income1_used_for_mortgage?
    inc1mort == 1
  end

  def income2_used_for_mortgage?
    inc2mort == 1
  end

  def right_to_buy?
    [9, 14, 27].include?(type)
  end

  def is_type_discount?
    type == 18
  end

  def ppostcode_full=(postcode)
    if postcode
      super UKPostcode.parse(postcode).to_s
    else
      super nil
    end
  end

  def previous_postcode_known?
    ppcodenk&.zero?
  end

  def process_postcode(postcode, postcode_known_key, la_inferred_key, la_key)
    return if postcode.blank?

    self[postcode_known_key] = 0
    inferred_la = get_inferred_la(postcode)
    self[la_inferred_key] = inferred_la.present?
    self[la_key] = inferred_la if inferred_la.present?
  end
end
