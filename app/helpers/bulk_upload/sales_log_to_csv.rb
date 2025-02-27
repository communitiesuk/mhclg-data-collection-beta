class BulkUpload::SalesLogToCsv
  attr_reader :log, :line_ending, :col_offset, :overrides

  def initialize(log:, line_ending: "\n", col_offset: 1, overrides: {})
    # rubocop:disable Rails/HelperInstanceVariable
    @log = log
    @line_ending = line_ending
    @col_offset = col_offset
    @overrides = overrides
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def row_prefix
    [nil] * col_offset
  end

  def to_csv_row(seed: nil)
    year = log.collection_start_year
    case year
    when 2022
      to_2022_csv_row
    when 2023, 2024
      to_year_csv_row(year, seed:)
    else
      raise NotImplementedError "No mapping function implemented for year #{year}"
    end
  end

  def to_row
    year = log.collection_start_year
    send("to_#{year}_row")
  rescue NoMethodError
    raise NotImplementedError "No mapping function implemented for year #{year}"
  end

  def default_field_numbers_row(seed: nil)
    year = log.collection_start_year
    default_field_numbers_row_for_year(year, seed:)
  end

  def default_field_numbers
    year = log.collection_start_year
    default_field_numbers_for_year(year)
  end

  def to_2022_csv_row
    (row_prefix + to_2022_row).flatten.join(",") + line_ending
  end

  def to_year_csv_row(year, seed: nil)
    unshuffled_row = send("to_#{year}_row")
    if seed
      row = unshuffled_row.shuffle(random: Random.new(seed))
      (row_prefix + row).flatten.join(",") + line_ending
    else
      (row_prefix + unshuffled_row).flatten.join(",") + line_ending
    end
  rescue NoMethodError
    raise NotImplementedError "No mapping function implemented for year #{year}"
  end

  def default_field_numbers_for_year(year)
    case year
    when 2022
      (1..125).to_a
    when 2023
      [6, 3, 4, 5, nil, 28, 30, 38, 47, 51, 55, 59, 31, 39, 48, 52, 56, 60, 37, 46, 50, 54, 58, 35, 43, 49, 53, 57, 61, 32, 33, 78, 80, 79, 81, 83, 84, nil, 62, 66, 64, 65, 63, 67, 69, 70, 68, 76, 77, 16, 17, 18, 26, 24, 25, 27, 8, 91, 95, 96, 97, 92, 93, 94, 98, 100, 101, 103, 104, 106, 110, 111, 112, 113, 114, 9, 116, 117, 118, 120, 124, 125, 126, 10, 11, nil, 127, 129, 133, 134, 135, 1, 2, nil, 73, nil, 75, 107, 108, 121, 122, 130, 131, 82, 109, 123, 132, 115, 15, 86, 87, 29, 7, 12, 13, 14, 36, 44, 45, 88, 89, 102, 105, 119, 128, 19, 20, 21, 22, 23, 34, 40, 41, 42, 71, 72, 74, 85, 90, 99]
    when 2024
      (1..131).to_a
    else
      raise NotImplementedError "No mapping function implemented for year #{year}"
    end
  end

  def default_field_numbers_row_for_year(year, seed: nil)
    if seed
      ["Field number"] + default_field_numbers_for_year(year).shuffle(random: Random.new(seed))
    else
      ["Field number"] + default_field_numbers_for_year(year)
    end.flatten.join(",") + line_ending
  end

  def to_2023_row
    to_2022_row + [
      log.uprn,
      log.address_line1,
      log.address_line2,
      log.town_or_city,
      log.county,
      nil, # mistake in template. field is ignored
      log.ethnic_group2,
      log.nationalbuy2,
      nil, # mistake in template. field is ignored
      log.buy2living,
      log.prevtenbuy2,
      log.hhregresstill,
      log.prevshared,
      log.staircasesale,
      log.soctenant,
    ]
  end

  def to_2022_row
    [
      log.purchid, # 1
      log.saledate&.day,
      log.saledate&.month,
      log.saledate&.strftime("%y"),
      nil,
      log.noint,
      log.age1,
      log.age2,
      log.age3,
      log.age4,
      log.age5,
      log.age6,

      log.sex1,
      log.sex2,
      log.sex3,
      log.sex4,
      log.sex5,
      log.sex6,

      log.relat2,
      log.relat3, # 20
      log.relat4,
      log.relat5,
      log.relat6,

      log.ecstat1,
      log.ecstat2,
      log.ecstat3,
      log.ecstat4,
      log.ecstat5,
      log.ecstat6,

      log.ethnic, # 30
      log.national,
      log.income1,
      log.income2,
      log.inc1mort,
      log.inc2mort,
      log.savings,
      log.prevown,
      nil,

      log.prevten,
      log.prevloc, # 40
      ((log.ppostcode_full || "").split(" ") || [""]).first,
      ((log.ppostcode_full || "").split(" ") || [""]).last,
      log.ppcodenk&.zero? ? 1 : nil,

      log.pregyrha,
      log.pregla,
      log.pregghb,
      log.pregother,

      log.disabled,
      log.wheel,
      log.beds, # 50
      log.proptype,
      log.builtype,
      log.la,
      ((log.postcode_full || "").split(" ") || [""]).first,
      ((log.postcode_full || "").split(" ") || [""]).last,
      log.wchair,

      log.type, # shared ownership
      log.resale,
      log.hodate&.day,
      log.hodate&.month, # 60
      log.hodate&.strftime("%y"),
      log.exdate&.day,
      log.exdate&.month,
      log.exdate&.strftime("%y"),
      log.lanomagr,

      log.frombeds,
      log.fromprop,

      log.value,
      log.equity,
      log.mortgage, # 70
      log.extrabor,
      log.deposit,
      log.cashdis,

      log.mrent,
      log.mscharge,

      log.type, # discounted ownership
      log.value,
      log.grant,
      log.discount,
      log.mortgage, # 80
      log.extrabor,
      log.deposit,
      log.mscharge,

      log.type, # outright sale
      log.othtype,
      nil,

      log.value,
      log.mortgage,
      log.extrabor,
      log.deposit, # 90
      log.mscharge,

      overrides[:organisation_id] || log.owning_organisation&.old_visible_id,
      log.assigned_to&.email,
      nil,
      hhregres,
      nil,
      log.armedforcesspouse,
      log.mortgagelender, # shared ownership
      log.mortgagelenderother,
      log.mortgagelender, # discounted ownership 100
      log.mortgagelenderother,
      log.mortgagelender, # outright ownership
      log.mortgagelenderother,

      log.hb,
      log.mortlen, # shared ownership
      log.mortlen, # discounted ownership
      log.mortlen, # outright ownership

      log.proplen, # discounted ownership
      log.jointmore,
      log.proplen, # shared ownership 110
      log.staircase,
      log.privacynotice,
      log.ownershipsch,
      log.companybuy, # outright sale
      log.buylivein,
      log.jointpur,
      log.buy1livein,
      log.buy2livein,
      log.hholdcount,
      log.stairbought, # 120
      log.stairowned,
      log.socprevten,
      log.mortgageused, # shared ownership
      log.mortgageused, # discounted ownership
      log.mortgageused, # outright ownership
    ]
  end

  def to_2024_row
    [
      overrides[:organisation_id] || log.owning_organisation&.old_visible_id,
      overrides[:managing_organisation_id] || log.managing_organisation&.old_visible_id,
      log.assigned_to&.email,
      log.saledate&.day,
      log.saledate&.month,
      log.saledate&.strftime("%y"),
      log.purchid,
      log.ownershipsch,
      log.ownershipsch == 1 ? log.type : "", # field_9: "What is the type of shared ownership sale?",
      log.ownershipsch == 2 ? log.type : "", # field_10: "What is the type of discounted ownership sale?",

      log.ownershipsch == 3 ? log.type : "", # field_11: "What is the type of outright sale?",
      log.othtype,
      log.companybuy,
      log.buylivein,
      log.jointpur,
      log.jointmore,
      log.noint,
      log.privacynotice,
      log.beds,
      log.proptype, # 20

      log.builtype,
      log.uprn,
      log.address_line1&.tr(",", " "),
      log.address_line2&.tr(",", " "),
      log.town_or_city&.tr(",", " "),
      log.county&.tr(",", " "),
      ((log.postcode_full || "").split(" ") || [""]).first,
      ((log.postcode_full || "").split(" ") || [""]).last,
      log.la,
      log.wchair, # 30

      log.age1,
      log.sex1,
      log.ethnic,
      log.nationality_all_group,
      log.ecstat1,
      log.buy1livein,
      log.relat2,
      log.age2,
      log.sex2,
      log.ethnic_group2, # 40

      log.nationality_all_buyer2_group,
      log.ecstat2,
      log.buy2livein,
      log.hholdcount,
      log.relat3,
      log.age3,
      log.sex3,
      log.ecstat3,
      log.relat4,
      log.age4, # 50

      log.sex4,
      log.ecstat4,
      log.relat5,
      log.age5,
      log.sex5,
      log.ecstat5,
      log.relat6,
      log.age6,
      log.sex6,
      log.ecstat6, # 60

      log.prevten,
      log.ppcodenk,
      ((log.ppostcode_full || "").split(" ") || [""]).first,
      ((log.ppostcode_full || "").split(" ") || [""]).last,
      log.prevloc,
      log.pregyrha,
      log.pregother,
      log.pregla,
      log.pregghb,
      log.buy2living, # 70

      log.prevtenbuy2,
      log.hhregres,
      log.hhregresstill,
      log.armedforcesspouse,
      log.disabled,
      log.wheel,
      log.income1,
      log.inc1mort,
      log.income2,
      log.inc2mort, # 80

      log.hb,
      log.savings.present? || "R",
      log.prevown,
      log.prevshared,
      log.proplen,
      log.staircase,
      log.stairbought,
      log.stairowned,
      log.staircasesale,
      log.resale, # 90

      log.exdate&.day,
      log.exdate&.month,
      log.exdate&.strftime("%y"),
      log.hodate&.day,
      log.hodate&.month, # 60
      log.hodate&.strftime("%y"),
      log.lanomagr,
      log.frombeds,
      log.fromprop,
      log.socprevten, # 100

      log.value,
      log.equity,
      log.mortgageused,
      log.mortgage,
      log.mortgagelender,
      log.mortgagelenderother,
      log.mortlen,
      log.extrabor,
      log.deposit,
      log.cashdis, # 110

      log.mrent,
      log.mscharge,
      log.proplen,
      log.value,
      log.grant,
      log.discount || 0,
      log.mortgageused,
      log.mortgage,
      log.mortgagelender,
      log.mortgagelenderother, # 120

      log.mortlen,
      log.extrabor,
      log.deposit,
      log.mscharge,
      log.value,
      log.mortgageused,
      log.mortgage,
      log.mortlen,
      log.extrabor,
      log.deposit, # 130
      log.mscharge,
    ]
  end

  def custom_field_numbers_row(seed: nil, field_numbers: nil)
    if seed
      ["Field number"] + field_numbers.shuffle(random: Random.new(seed))
    else
      ["Field number"] + field_numbers
    end.flatten.join(",") + line_ending
  end

  def to_custom_csv_row(seed: nil, field_values: nil)
    row = seed ? field_values.shuffle(random: Random.new(seed)) : field_values
    (row_prefix + row).flatten.join(",") + line_ending
  end

private

  def hhregres
    if log.hhregres == 1
      log.hhregresstill
    else
      log.hhregres
    end
  end
end
