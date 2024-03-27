module Exports::LettingsLogExportConstants
  MAX_XML_RECORDS = 10_000
  LOG_ID_OFFSET = 300_000_000_000

  EXPORT_MODE = {
    xml: 1,
    csv: 2,
  }.freeze

  EXPORT_FIELDS = Set[
    "armedforces",
    "beds",
    "benefits",
    "brent",
    "builtype",
    "cap",
    "cbl",
    "chcharge",
    "chr",
    "cligrp1",
    "cligrp2",
    "createddate", # New metadata coming from our system
    "creation_method",
    "confidential",
    "discarded_at",
    "earnings",
    "ethnic",
    "formid",
    "has_benefits",
    "hb",
    "hbrentshortfall",
    "hcnum",
    "hhmemb",
    "hhtype",
    "homeless",
    "housingneeds",
    "illness",
    "incfreq",
    "income",
    "incref",
    "intstay",
    "irproduct",
    "irproduct_other",
    "joint",
    "la",
    "lar",
    "layear",
    "leftreg",
    "lettype",
    "manhcnum",
    "maningorgid",
    "maningorgname",
    "mantype",
    "mobstand",
    "mrcdate",
    "national",
    "needstype",
    "new_old",
    "newprop",
    "nocharge",
    "offered",
    "owningorgid",
    "owningorgname",
    "period",
    "uprn",
    "uprn_known",
    "uprn_confirmed",
    "address_line1",
    "address_line2",
    "town_or_city",
    "county",
    "postcode_full",
    "ppcodenk",
    "ppostcode_full",
    "preg_occ",
    "prevloc",
    "prevten",
    "propcode",
    "providertype",
    "pscharge",
    "reason",
    "reasonother",
    "reasonpref",
    "referral",
    "refused",
    "reghome",
    "renttype",
    "renttype_detail",
    "renewal",
    "reservist",
    "rp_dontknow",
    "rp_hardship",
    "rp_homeless",
    "rp_insan_unsat",
    "rp_medwel",
    "rsnvac",
    "scharge",
    "scheme",
    "schtype",
    "sheltered",
    "startdate",
    "startertenancy",
    "supcharg",
    "support",
    "status", # New metadata coming from our system
    "tcharge",
    "tshortfall",
    "tenancy",
    "tenancycode",
    "tenancylength",
    "tenancyother",
    "totadult",
    "totchild",
    "totelder",
    "underoccupation_benefitcap",
    "unitletas",
    "units",
    "units_scheme",
    "unittype_gn",
    "unittype_sh",
    "uploaddate",
    "username",
    "vacdays",
    "voiddate",
    "waityear",
    "wchair",
    "wchchrg",
    "wpschrge",
    "wrent",
    "wscharge",
    "wsupchrg",
    "wtcharge",
    "wtshortfall",
    "location_code",
    "scheme_old",
    "log_id",
    "scheme_status",
    "location_status",
    "created_by",
    "amended_by",
    "duplicate_set_id",
    "accessible_register",
    "nationality_all",
    "bulk_upload_id",
    "address_line1_as_entered",
    "address_line2_as_entered",
    "town_or_city_as_entered",
    "county_as_entered",
    "postcode_full_as_entered",
    "la_as_entered",
    "net_income_value_check",
    "rent_value_check",
    "scharge_value_check",
    "pscharge_value_check",
    "supcharg_value_check",
    "carehome_charges_value_check",
    "assigned_to",
  ]

  (1..8).each do |index|
    EXPORT_FIELDS << "age#{index}"
    EXPORT_FIELDS << "ecstat#{index}"
    EXPORT_FIELDS << "sex#{index}"
  end
  (2..8).each do |index|
    EXPORT_FIELDS << "relat#{index}"
  end
  (1..10).each do |index|
    EXPORT_FIELDS << "illness_type_#{index}"
  end
  %w[a b c d e f g h].each do |letter|
    EXPORT_FIELDS << "housingneeds_#{letter}"
  end

  POST_2024_EXPORT_FIELDS = Set[
    "accessible_register",
    "nationality_all",
    "bulk_upload_id",
    "address_line1_as_entered",
    "address_line2_as_entered",
    "town_or_city_as_entered",
    "county_as_entered",
    "postcode_full_as_entered",
    "la_as_entered",
    "net_income_value_check",
    "rent_value_check",
    "scharge_value_check",
    "pscharge_value_check",
    "supcharg_value_check",
    "carehome_charges_value_check",
    "assigned_to",
  ]

  PRE_2024_EXPORT_FIELDS = Set[
    "national",
    "offered"
  ]
end
