class BulkUpload
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Conversion

  SPREADSHEET_CONTENT_TYPES = %w[
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  FIRST_DATA_ROW = 7

  def initialize(file, content_type)
    @file = file
    @content_type = content_type
  end

  def process
    return unless valid_content_type?

    xlsx = Roo::Spreadsheet.open(@file, extension: :xlsx)
    sheet = xlsx.sheet(0)
    last_row = sheet.last_row
    if last_row < FIRST_DATA_ROW
      errors.add(:case_log_bulk_upload, "No data found")
    else
      data_range = FIRST_DATA_ROW..last_row
      data_range.map do |row_num|
        case_log = CaseLog.create!
        map_row(sheet.row(row_num)).each do |attr_key, attr_val|
          update = case_log.update(attr_key => attr_val)
          unless update
            # TODO: determine what to do when a bulk upload contains field values that don't pass validations
          end
        rescue ArgumentError
          # TODO: determine what we want to do when bulk upload contains totally invalid data for a field.
        end
      end
    end
  end

  def valid_content_type?
    if SPREADSHEET_CONTENT_TYPES.include?(@content_type)
      true
    else
      errors.add(:case_log_bulk_upload, "Invalid file type")
      false
    end
  end

  def map_row(row)
    {
      lettype: row[1],
      landlord: row[2],
      # reg_num_la_core_code: row[3],
      # managementgroup: row[4],
      # schemecode: row[5],
      # firstletting: row[6],
      tenant_code: row[7],
      startertenancy: row[8],
      tenancy: row[9],
      tenancyother: row[10],
      # tenancyduration: row[11],
      other_hhmemb: other_hhmemb(row),
      hhmemb: other_hhmemb(row) + 1,
      age1: row[12],
      age2: row[13],
      age3: row[14],
      age4: row[15],
      age5: row[16],
      age6: row[17],
      age7: row[18],
      age8: row[19],
      sex1: row[20],
      sex2: row[21],
      sex3: row[22],
      sex4: row[23],
      sex5: row[24],
      sex6: row[25],
      sex7: row[26],
      sex8: row[27],
      relat2: row[28],
      relat3: row[29],
      relat4: row[30],
      relat5: row[31],
      relat6: row[32],
      relat7: row[33],
      relat8: row[34],
      ecstat1: row[35],
      ecstat2: row[36],
      ecstat3: row[37],
      ecstat4: row[38],
      ecstat5: row[39],
      ecstat6: row[40],
      ecstat7: row[41],
      ecstat8: row[42],
      ethnic: row[43],
      national: row[44],
      armedforces: row[45],
      reservist: row[46],
      preg_occ: row[47],
      hb: row[48],
      benefits: row[49],
      net_income_known: row[50].present? ? 1 : nil,
      earnings: row[50],
      # increfused: row[51],
      reason: row[52],
      other_reason_for_leaving_last_settled_home: row[53],
      underoccupation_benefitcap: row[54],
      housingneeds_a: row[55],
      housingneeds_b: row[56],
      housingneeds_c: row[57],
      housingneeds_f: row[58],
      housingneeds_g: row[59],
      housingneeds_h: row[60],
      prevten: row[61],
      prevloc: row[62],
      # ppostc1: row[63],
      # ppostc2: row[64],
      # prevpco_unknown: row[65],
      layear: row[66],
      lawaitlist: row[67],
      homeless: row[68],
      reasonpref: row[69],
      rp_homeless: row[70],
      rp_insan_unsat: row[71],
      rp_medwel: row[72],
      rp_hardship: row[73],
      rp_dontknow: row[74],
      cbl: row[75],
      chr: row[76],
      cap: row[77],
      # referral_source: row[78],
      period: row[79],
      brent: row[80],
      scharge: row[81],
      pscharge: row[82],
      supcharg: row[83],
      tcharge: row[84],
      # tcharge_care_homes: row[85],
      # no_rent_or_charge: row[86],
      hbrentshortfall: row[87],
      tshortfall: row[88],
      property_void_date: row[89].to_s + row[90].to_s + row[91].to_s,
      # property_void_date_day: row[89],
      # property_void_date_month: row[90],
      # property_void_date_year: row[91],
      majorrepairs: row[92].present? ? "1" : nil,
      mrcdate: row[92].to_s + row[93].to_s + row[94].to_s,
      mrcday: row[92],
      mrcmonth: row[93],
      mrcyear: row[94],
      # supported_scheme: row[95],
      startdate: row[96].to_s + row[97].to_s + row[98].to_s,
      # startdate_day: row[96],
      # startdate_month: row[97],
      # startdate_year: row[98],
      offered: row[99],
      # property_reference: row[100],
      beds: row[101],
      unittype_gn: row[102],
      builtype: row[103],
      wchair: row[104],
      property_relet: row[105],
      rsnvac: row[106],
      la: row[107],
      # postcode: row[108],
      # postcod2: row[109],
      # row[110] removed
      property_owner_organisation: row[111],
      # username: row[112],
      property_manager_organisation: row[113],
      leftreg: row[114],
      # uprn: row[115],
      incfreq: row[116],
      # sheltered_accom: row[117],
      illness: row[118],
      illness_type_1: row[119],
      illness_type_2: row[120],
      illness_type_3: row[121],
      illness_type_4: row[122],
      illness_type_8: row[123],
      illness_type_5: row[124],
      illness_type_6: row[125],
      illness_type_7: row[126],
      illness_type_9: row[127],
      illness_type_10: row[128],
      # london_affordable: row[129],
      rent_type: row[130],
      intermediate_rent_product_name: row[131],
      # data_protection: row[132],
      sale_or_letting: "letting",
      gdpr_acceptance: 1,
      gdpr_declined: 0,
    }
  end

  def other_hhmemb(row)
    [13, 14, 15, 16, 17, 18, 19].count { |idx| row[idx].present? }
  end
end
