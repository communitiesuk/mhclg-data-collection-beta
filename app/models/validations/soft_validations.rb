module Validations::SoftValidations
  ALLOWED_INCOME_RANGES = {
    1 => OpenStruct.new(soft_min: 143, soft_max: 730, hard_min: 90, hard_max: 1230),
    2 => OpenStruct.new(soft_min: 67, soft_max: 620, hard_min: 50, hard_max: 950),
    3 => OpenStruct.new(soft_min: 80, soft_max: 480, hard_min: 40, hard_max: 990),
    4 => OpenStruct.new(soft_min: 50, soft_max: 370, hard_min: 10, hard_max: 450),
    5 => OpenStruct.new(soft_min: 50, soft_max: 380, hard_min: 10, hard_max: 690),
    6 => OpenStruct.new(soft_min: 53, soft_max: 540, hard_min: 10, hard_max: 890),
    7 => OpenStruct.new(soft_min: 47, soft_max: 460, hard_min: 10, hard_max: 1300),
    8 => OpenStruct.new(soft_min: 54, soft_max: 460, hard_min: 10, hard_max: 820),
    9 => OpenStruct.new(soft_min: 50, soft_max: 450, hard_min: 10, hard_max: 750),
    0 => OpenStruct.new(soft_min: 50, soft_max: 580, hard_min: 10, hard_max: 1040),
    10 => OpenStruct.new(soft_min: 47, soft_max: 730, hard_min: 10, hard_max: 1300),
  }.freeze

  def net_income_in_soft_max_range?
    return unless weekly_net_income && ecstat1

    weekly_net_income.between?(applicable_income_range.soft_max, applicable_income_range.hard_max)
  end

  def net_income_in_soft_min_range?
    return unless weekly_net_income && ecstat1

    weekly_net_income.between?(applicable_income_range.hard_min, applicable_income_range.soft_min)
  end

  def rent_in_soft_min_range?
    return unless brent && weekly_value(brent) && startdate

    rent_range = LaRentRange.find_by(start_year: collection_start_year, la:, beds:, lettype:)
    rent_range.present? && weekly_value(brent).between?(rent_range.hard_min, rent_range.soft_min)
  end

  def rent_in_soft_max_range?
    return unless brent && weekly_value(brent) && startdate

    rent_range = LaRentRange.find_by(start_year: collection_start_year, la:, beds:, lettype:)
    rent_range.present? && weekly_value(brent).between?(rent_range.soft_max, rent_range.hard_max)
  end
end
