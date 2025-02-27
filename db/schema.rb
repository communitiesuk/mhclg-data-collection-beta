# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_02_25_180643) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bulk_upload_errors", force: :cascade do |t|
    t.bigint "bulk_upload_id"
    t.text "cell"
    t.text "row"
    t.text "tenant_code"
    t.text "property_ref"
    t.text "purchaser_code"
    t.text "field"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "col"
    t.text "category"
    t.index ["bulk_upload_id"], name: "index_bulk_upload_errors_on_bulk_upload_id"
  end

  create_table "bulk_uploads", force: :cascade do |t|
    t.bigint "user_id"
    t.text "log_type", null: false
    t.integer "year", null: false
    t.uuid "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "filename"
    t.integer "needstype"
    t.text "choice"
    t.integer "total_logs_count"
    t.string "rent_type_fix_status", default: "not_applied"
    t.integer "organisation_id"
    t.integer "moved_user_id"
    t.string "failure_reason"
    t.boolean "processing"
    t.index ["identifier"], name: "index_bulk_uploads_on_identifier", unique: true
    t.index ["user_id"], name: "index_bulk_uploads_on_user_id"
  end

  create_table "collection_resources", force: :cascade do |t|
    t.string "log_type"
    t.string "resource_type"
    t.string "display_name"
    t.string "short_display_name"
    t.integer "year"
    t.string "download_filename"
    t.boolean "mandatory"
    t.boolean "released_to_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
  end

  create_table "csv_downloads", force: :cascade do |t|
    t.string "download_type"
    t.string "filename"
    t.integer "expiration_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "organisation_id"
    t.index ["organisation_id"], name: "index_csv_downloads_on_organisation_id"
    t.index ["user_id"], name: "index_csv_downloads_on_user_id"
  end

  create_table "csv_variable_definitions", force: :cascade do |t|
    t.string "variable", null: false
    t.string "definition", null: false
    t.string "log_type", null: false
    t.integer "year", null: false
    t.datetime "last_accessed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "log_type::text = ANY (ARRAY['lettings'::character varying, 'sales'::character varying]::text[])", name: "log_type_check"
    t.check_constraint "year >= 2000 AND year <= 2099", name: "year_check"
  end

  create_table "data_protection_confirmations", force: :cascade do |t|
    t.bigint "organisation_id"
    t.bigint "data_protection_officer_id"
    t.boolean "confirmed"
    t.string "old_id"
    t.string "old_org_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "signed_at"
    t.string "organisation_name"
    t.string "organisation_address"
    t.string "organisation_phone_number"
    t.string "data_protection_officer_email"
    t.string "data_protection_officer_name"
    t.index ["data_protection_officer_id"], name: "dpo_user_id"
    t.index ["organisation_id"], name: "index_data_protection_confirmations_on_organisation_id"
  end

  create_table "exports", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "started_at", null: false
    t.integer "base_number", default: 1, null: false
    t.integer "increment_number", default: 1, null: false
    t.boolean "empty_export", default: false, null: false
    t.string "collection"
    t.integer "year"
  end

  create_table "la_rent_ranges", force: :cascade do |t|
    t.integer "ranges_rent_id"
    t.integer "lettype"
    t.string "la"
    t.integer "beds"
    t.decimal "soft_min", precision: 10, scale: 2
    t.decimal "soft_max", precision: 10, scale: 2
    t.decimal "hard_min", precision: 10, scale: 2
    t.decimal "hard_max", precision: 10, scale: 2
    t.integer "start_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_year", "lettype", "beds", "la"], name: "index_la_rent_ranges_on_start_year_and_lettype_and_beds_and_la", unique: true
  end

  create_table "la_sale_ranges", force: :cascade do |t|
    t.string "la"
    t.integer "bedrooms"
    t.decimal "soft_min", precision: 10, scale: 2
    t.decimal "soft_max", precision: 10, scale: 2
    t.integer "start_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_year", "bedrooms", "la"], name: "index_la_sale_ranges_on_start_year_bedrooms_la", unique: true
  end

  create_table "legacy_users", force: :cascade do |t|
    t.string "old_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["old_user_id"], name: "index_legacy_users_on_old_user_id", unique: true
  end

  create_table "lettings_logs", force: :cascade do |t|
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tenancycode"
    t.integer "age1"
    t.string "sex1"
    t.integer "ethnic"
    t.integer "national"
    t.integer "prevten"
    t.integer "ecstat1"
    t.integer "hhmemb"
    t.integer "age2"
    t.string "sex2"
    t.integer "ecstat2"
    t.integer "age3"
    t.string "sex3"
    t.integer "ecstat3"
    t.integer "age4"
    t.string "sex4"
    t.integer "ecstat4"
    t.integer "age5"
    t.string "sex5"
    t.integer "ecstat5"
    t.integer "age6"
    t.string "sex6"
    t.integer "ecstat6"
    t.integer "age7"
    t.string "sex7"
    t.integer "ecstat7"
    t.integer "age8"
    t.string "sex8"
    t.integer "ecstat8"
    t.integer "homeless"
    t.integer "underoccupation_benefitcap"
    t.integer "leftreg"
    t.integer "reservist"
    t.integer "illness"
    t.integer "preg_occ"
    t.integer "startertenancy"
    t.integer "tenancylength"
    t.integer "tenancy"
    t.string "ppostcode_full"
    t.integer "rsnvac"
    t.integer "unittype_gn"
    t.integer "beds"
    t.integer "offered"
    t.integer "wchair"
    t.integer "earnings"
    t.integer "incfreq"
    t.integer "benefits"
    t.integer "period"
    t.integer "layear"
    t.integer "waityear"
    t.string "postcode_full"
    t.integer "reasonpref"
    t.integer "cbl"
    t.integer "chr"
    t.integer "cap"
    t.string "reasonother"
    t.integer "housingneeds_a"
    t.integer "housingneeds_b"
    t.integer "housingneeds_c"
    t.integer "housingneeds_f"
    t.integer "housingneeds_g"
    t.integer "housingneeds_h"
    t.integer "illness_type_1"
    t.integer "illness_type_2"
    t.integer "illness_type_3"
    t.integer "illness_type_4"
    t.integer "illness_type_8"
    t.integer "illness_type_5"
    t.integer "illness_type_6"
    t.integer "illness_type_7"
    t.integer "illness_type_9"
    t.integer "illness_type_10"
    t.integer "rp_homeless"
    t.integer "rp_insan_unsat"
    t.integer "rp_medwel"
    t.integer "rp_hardship"
    t.integer "rp_dontknow"
    t.string "tenancyother"
    t.integer "net_income_value_check"
    t.string "property_owner_organisation"
    t.string "property_manager_organisation"
    t.string "irproduct_other"
    t.string "purchaser_code"
    t.integer "reason"
    t.string "propcode"
    t.integer "majorrepairs"
    t.string "la"
    t.string "prevloc"
    t.integer "hb"
    t.integer "hbrentshortfall"
    t.integer "property_relet"
    t.datetime "mrcdate", precision: nil
    t.integer "incref"
    t.datetime "startdate", precision: nil
    t.integer "armedforces"
    t.integer "first_time_property_let_as_social_housing"
    t.integer "unitletas"
    t.integer "builtype"
    t.datetime "voiddate", precision: nil
    t.bigint "owning_organisation_id"
    t.bigint "managing_organisation_id"
    t.integer "renttype"
    t.integer "needstype"
    t.integer "lettype"
    t.integer "postcode_known"
    t.boolean "is_la_inferred"
    t.integer "totchild"
    t.integer "totelder"
    t.integer "totadult"
    t.integer "net_income_known"
    t.integer "nocharge"
    t.integer "is_carehome"
    t.integer "household_charge"
    t.integer "referral"
    t.decimal "brent", precision: 10, scale: 2
    t.decimal "scharge", precision: 10, scale: 2
    t.decimal "pscharge", precision: 10, scale: 2
    t.decimal "supcharg", precision: 10, scale: 2
    t.decimal "tcharge", precision: 10, scale: 2
    t.decimal "tshortfall", precision: 10, scale: 2
    t.decimal "chcharge", precision: 10, scale: 2
    t.integer "declaration"
    t.integer "ppcodenk"
    t.integer "previous_la_known"
    t.boolean "is_previous_la_inferred"
    t.integer "age1_known"
    t.integer "age2_known"
    t.integer "age3_known"
    t.integer "age4_known"
    t.integer "age5_known"
    t.integer "age6_known"
    t.integer "age7_known"
    t.integer "age8_known"
    t.integer "ethnic_group"
    t.integer "letting_allocation_unknown"
    t.integer "details_known_2"
    t.integer "details_known_3"
    t.integer "details_known_4"
    t.integer "details_known_5"
    t.integer "details_known_6"
    t.integer "details_known_7"
    t.integer "details_known_8"
    t.integer "rent_type"
    t.integer "has_benefits"
    t.integer "renewal"
    t.decimal "wrent", precision: 10, scale: 2
    t.decimal "wscharge", precision: 10, scale: 2
    t.decimal "wpschrge", precision: 10, scale: 2
    t.decimal "wsupchrg", precision: 10, scale: 2
    t.decimal "wtcharge", precision: 10, scale: 2
    t.decimal "wtshortfall", precision: 10, scale: 2
    t.integer "refused"
    t.integer "housingneeds"
    t.decimal "wchchrg", precision: 10, scale: 2
    t.integer "newprop"
    t.string "relat2"
    t.string "relat3"
    t.string "relat4"
    t.string "relat5"
    t.string "relat6"
    t.string "relat7"
    t.string "relat8"
    t.integer "rent_value_check"
    t.integer "old_form_id"
    t.integer "lar"
    t.integer "irproduct"
    t.string "old_id"
    t.integer "joint"
    t.bigint "assigned_to_id"
    t.integer "retirement_value_check"
    t.integer "tshortfall_known"
    t.integer "sheltered"
    t.integer "pregnancy_value_check"
    t.integer "hhtype"
    t.integer "new_old"
    t.integer "vacdays"
    t.bigint "scheme_id"
    t.bigint "location_id"
    t.integer "major_repairs_date_value_check"
    t.integer "void_date_value_check"
    t.integer "housingneeds_type"
    t.integer "housingneeds_other"
    t.boolean "unresolved"
    t.bigint "updated_by_id"
    t.bigint "bulk_upload_id"
    t.string "uprn"
    t.integer "uprn_known"
    t.integer "uprn_confirmed"
    t.string "address_line1"
    t.string "address_line2"
    t.string "town_or_city"
    t.string "county"
    t.integer "carehome_charges_value_check"
    t.integer "status_cache", default: 0, null: false
    t.datetime "discarded_at"
    t.integer "creation_method", default: 1
    t.datetime "values_updated_at"
    t.integer "referral_value_check"
    t.integer "supcharg_value_check"
    t.integer "scharge_value_check"
    t.integer "pscharge_value_check"
    t.integer "duplicate_set_id"
    t.integer "accessible_register"
    t.integer "nationality_all"
    t.integer "nationality_all_group"
    t.integer "reasonother_value_check"
    t.string "address_line1_input"
    t.string "postcode_full_input"
    t.integer "address_search_value_check"
    t.string "uprn_selection"
    t.string "address_line1_as_entered"
    t.string "address_line2_as_entered"
    t.string "town_or_city_as_entered"
    t.string "county_as_entered"
    t.string "postcode_full_as_entered"
    t.string "la_as_entered"
    t.integer "partner_under_16_value_check"
    t.integer "multiple_partners_value_check"
    t.bigint "created_by_id"
    t.integer "referral_type"
    t.index ["assigned_to_id"], name: "index_lettings_logs_on_assigned_to_id"
    t.index ["bulk_upload_id"], name: "index_lettings_logs_on_bulk_upload_id"
    t.index ["created_by_id"], name: "index_lettings_logs_on_created_by_id"
    t.index ["location_id"], name: "index_lettings_logs_on_location_id"
    t.index ["managing_organisation_id"], name: "index_lettings_logs_on_managing_organisation_id"
    t.index ["old_id"], name: "index_lettings_logs_on_old_id", unique: true
    t.index ["owning_organisation_id"], name: "index_lettings_logs_on_owning_organisation_id"
    t.index ["scheme_id"], name: "index_lettings_logs_on_scheme_id"
    t.index ["updated_by_id"], name: "index_lettings_logs_on_updated_by_id"
  end

  create_table "local_authorities", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_local_authority_code", unique: true
  end

  create_table "local_authority_links", force: :cascade do |t|
    t.bigint "local_authority_id"
    t.bigint "linked_local_authority_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linked_local_authority_id"], name: "index_local_authority_links_on_linked_local_authority_id"
    t.index ["local_authority_id"], name: "index_local_authority_links_on_local_authority_id"
  end

  create_table "location_deactivation_periods", force: :cascade do |t|
    t.datetime "deactivation_date"
    t.datetime "reactivation_date"
    t.bigint "location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_location_deactivation_periods_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "location_code"
    t.string "postcode"
    t.bigint "scheme_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "units"
    t.integer "type_of_unit"
    t.string "old_id"
    t.string "old_visible_id"
    t.string "mobility_type"
    t.datetime "startdate"
    t.string "location_admin_district"
    t.boolean "confirmed"
    t.boolean "is_la_inferred"
    t.datetime "discarded_at"
    t.index ["old_id"], name: "index_locations_on_old_id", unique: true
    t.index ["scheme_id"], name: "index_locations_on_scheme_id"
  end

  create_table "log_validations", force: :cascade do |t|
    t.string "log_type"
    t.string "section"
    t.string "validation_name"
    t.string "description"
    t.string "case"
    t.string "field"
    t.string "error_message"
    t.datetime "from"
    t.datetime "to"
    t.string "validation_type"
    t.string "hard_soft"
    t.boolean "bulk_upload_specific", default: false
    t.string "other_validated_models"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "checked"
    t.string "collection_year"
  end

  create_table "merge_request_organisations", force: :cascade do |t|
    t.integer "merge_request_id"
    t.integer "merging_organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "merge_requests", force: :cascade do |t|
    t.integer "requesting_organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "absorbing_organisation_id"
    t.datetime "merge_date"
    t.integer "requester_id"
    t.string "helpdesk_ticket"
    t.integer "total_users"
    t.integer "total_schemes"
    t.integer "total_lettings_logs"
    t.integer "total_sales_logs"
    t.integer "total_stock_owners"
    t.integer "total_managing_agents"
    t.boolean "signed_dsa", default: false
    t.datetime "discarded_at"
    t.datetime "last_failed_attempt"
    t.boolean "request_merged"
    t.boolean "processing"
    t.boolean "existing_absorbing_organisation"
    t.boolean "has_helpdesk_ticket"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "title"
    t.string "link_text"
    t.string "page_content"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean "show_on_unauthenticated_pages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_additional_page"
  end

  create_table "organisation_relationships", force: :cascade do |t|
    t.integer "child_organisation_id"
    t.integer "parent_organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_organisation_id"], name: "index_organisation_relationships_on_child_organisation_id"
    t.index ["parent_organisation_id", "child_organisation_id"], name: "index_org_rel_parent_child_uniq", unique: true
    t.index ["parent_organisation_id"], name: "index_organisation_relationships_on_parent_organisation_id"
  end

  create_table "organisation_rent_periods", force: :cascade do |t|
    t.bigint "organisation_id"
    t.integer "rent_period"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_organisation_rent_periods_on_organisation_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.integer "provider_type"
    t.string "address_line1"
    t.string "address_line2"
    t.string "postcode"
    t.boolean "holds_own_stock"
    t.string "other_stock_owners"
    t.string "managing_agents_label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.integer "old_association_type"
    t.string "software_supplier_id"
    t.string "housing_management_system"
    t.boolean "choice_based_lettings"
    t.boolean "common_housing_register"
    t.boolean "choice_allocation_policy"
    t.integer "cbl_proportion_percentage"
    t.boolean "enter_affordable_logs"
    t.boolean "owns_affordable_logs"
    t.string "housing_registration_no"
    t.integer "general_needs_units"
    t.integer "supported_housing_units"
    t.integer "unspecified_units"
    t.string "old_org_id"
    t.string "old_visible_id"
    t.datetime "merge_date"
    t.bigint "absorbing_organisation_id"
    t.datetime "available_from"
    t.datetime "discarded_at"
    t.datetime "schemes_deduplicated_at"
    t.index ["absorbing_organisation_id"], name: "index_organisations_on_absorbing_organisation_id"
    t.index ["name"], name: "index_organisations_on_name", unique: true
    t.index ["old_visible_id"], name: "index_organisations_on_old_visible_id", unique: true
  end

  create_table "read_marks", force: :cascade do |t|
    t.string "readable_type", null: false
    t.bigint "readable_id"
    t.string "reader_type", null: false
    t.bigint "reader_id"
    t.datetime "timestamp", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["readable_type", "readable_id"], name: "index_read_marks_on_readable_type_and_readable_id"
    t.index ["reader_id", "reader_type", "readable_type", "readable_id"], name: "read_marks_reader_readable_index", unique: true
    t.index ["reader_type", "reader_id"], name: "index_read_marks_on_reader_type_and_reader_id"
  end

  create_table "sales_logs", force: :cascade do |t|
    t.integer "status", default: 0
    t.datetime "saledate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "owning_organisation_id"
    t.bigint "assigned_to_id"
    t.string "purchid"
    t.integer "type"
    t.integer "ownershipsch"
    t.string "othtype"
    t.integer "jointmore"
    t.integer "jointpur"
    t.integer "beds"
    t.integer "companybuy"
    t.integer "age1"
    t.integer "age1_known"
    t.string "sex1"
    t.integer "national"
    t.integer "ethnic"
    t.integer "ethnic_group"
    t.integer "buy1livein"
    t.integer "buylivein"
    t.integer "builtype"
    t.integer "proptype"
    t.integer "age2"
    t.integer "age2_known"
    t.string "relat2"
    t.string "sex2"
    t.integer "noint"
    t.integer "buy2livein"
    t.integer "ecstat2"
    t.integer "privacynotice"
    t.integer "ecstat1"
    t.integer "wheel"
    t.integer "hholdcount"
    t.integer "age3"
    t.integer "age3_known"
    t.string "la"
    t.integer "la_known"
    t.integer "income1"
    t.integer "income1nk"
    t.integer "details_known_2"
    t.integer "details_known_3"
    t.integer "details_known_4"
    t.integer "age4"
    t.integer "age4_known"
    t.integer "age5"
    t.integer "age5_known"
    t.integer "age6"
    t.integer "age6_known"
    t.integer "inc1mort"
    t.integer "income2"
    t.integer "income2nk"
    t.integer "savingsnk"
    t.integer "savings"
    t.integer "prevown"
    t.string "sex3"
    t.bigint "updated_by_id"
    t.integer "income1_value_check"
    t.decimal "mortgage", precision: 10, scale: 2
    t.integer "inc2mort"
    t.integer "mortgage_value_check"
    t.integer "ecstat3"
    t.integer "ecstat4"
    t.integer "ecstat5"
    t.integer "ecstat6"
    t.string "relat3"
    t.string "relat4"
    t.string "relat5"
    t.string "relat6"
    t.integer "hb"
    t.string "sex4"
    t.string "sex5"
    t.string "sex6"
    t.integer "savings_value_check"
    t.integer "deposit_value_check"
    t.integer "frombeds"
    t.integer "staircase"
    t.decimal "stairbought"
    t.decimal "stairowned"
    t.decimal "mrent", precision: 10, scale: 2
    t.datetime "exdate"
    t.integer "exday"
    t.integer "exmonth"
    t.integer "exyear"
    t.integer "resale"
    t.decimal "deposit", precision: 10, scale: 2
    t.decimal "cashdis", precision: 10, scale: 2
    t.integer "disabled"
    t.integer "lanomagr"
    t.integer "wheel_value_check"
    t.integer "soctenant"
    t.decimal "value", precision: 10, scale: 2
    t.decimal "equity", precision: 10, scale: 2
    t.decimal "discount", precision: 10, scale: 2
    t.decimal "grant", precision: 10, scale: 2
    t.integer "pregyrha"
    t.integer "pregla"
    t.integer "pregghb"
    t.integer "pregother"
    t.string "ppostcode_full"
    t.boolean "is_previous_la_inferred"
    t.integer "ppcodenk"
    t.string "ppostc1"
    t.string "ppostc2"
    t.string "prevloc"
    t.integer "previous_la_known"
    t.integer "hhregres"
    t.integer "hhregresstill"
    t.integer "proplen"
    t.integer "has_mscharge"
    t.decimal "mscharge", precision: 10, scale: 2
    t.integer "prevten"
    t.integer "mortgageused"
    t.integer "wchair"
    t.integer "income2_value_check"
    t.integer "armedforcesspouse"
    t.datetime "hodate"
    t.integer "hoday"
    t.integer "homonth"
    t.integer "hoyear"
    t.integer "fromprop"
    t.integer "socprevten"
    t.integer "mortgagelender"
    t.string "mortgagelenderother"
    t.integer "mortlen"
    t.integer "extrabor"
    t.integer "hhmemb"
    t.integer "totadult"
    t.integer "totchild"
    t.integer "hhtype"
    t.string "pcode1"
    t.string "pcode2"
    t.integer "pcodenk"
    t.string "postcode_full"
    t.boolean "is_la_inferred"
    t.bigint "bulk_upload_id"
    t.integer "retirement_value_check"
    t.integer "hodate_check"
    t.integer "extrabor_value_check"
    t.integer "deposit_and_mortgage_value_check"
    t.integer "shared_ownership_deposit_value_check"
    t.integer "grant_value_check"
    t.integer "value_value_check"
    t.integer "old_persons_shared_ownership_value_check"
    t.integer "staircase_bought_value_check"
    t.integer "monthly_charges_value_check"
    t.integer "details_known_5"
    t.integer "details_known_6"
    t.integer "saledate_check"
    t.integer "prevshared"
    t.integer "staircasesale"
    t.integer "ethnic_group2"
    t.integer "ethnicbuy2"
    t.integer "proplen_asked"
    t.string "old_id"
    t.integer "buy2living"
    t.integer "prevtenbuy2"
    t.integer "pregblank"
    t.string "uprn"
    t.integer "uprn_known"
    t.integer "uprn_confirmed"
    t.string "address_line1"
    t.string "address_line2"
    t.string "town_or_city"
    t.string "county"
    t.integer "nationalbuy2"
    t.integer "discounted_sale_value_check"
    t.integer "student_not_child_value_check"
    t.integer "percentage_discount_value_check"
    t.integer "combined_income_value_check"
    t.integer "buyer_livein_value_check"
    t.integer "status_cache", default: 0, null: false
    t.datetime "discarded_at"
    t.integer "stairowned_value_check"
    t.integer "creation_method", default: 1
    t.integer "old_form_id"
    t.datetime "values_updated_at"
    t.bigint "managing_organisation_id"
    t.integer "duplicate_set_id"
    t.integer "nationality_all"
    t.integer "nationality_all_group"
    t.integer "nationality_all_buyer2"
    t.integer "nationality_all_buyer2_group"
    t.string "address_line1_input"
    t.string "postcode_full_input"
    t.integer "address_search_value_check"
    t.string "uprn_selection"
    t.string "address_line1_as_entered"
    t.string "address_line2_as_entered"
    t.string "town_or_city_as_entered"
    t.string "county_as_entered"
    t.string "postcode_full_as_entered"
    t.string "la_as_entered"
    t.integer "partner_under_16_value_check"
    t.integer "multiple_partners_value_check"
    t.bigint "created_by_id"
    t.integer "has_management_fee"
    t.decimal "management_fee", precision: 10, scale: 2
    t.integer "firststair"
    t.integer "numstair"
    t.decimal "mrentprestaircasing", precision: 10, scale: 2
    t.datetime "lasttransaction"
    t.datetime "initialpurchase"
    t.index ["assigned_to_id"], name: "index_sales_logs_on_assigned_to_id"
    t.index ["bulk_upload_id"], name: "index_sales_logs_on_bulk_upload_id"
    t.index ["created_by_id"], name: "index_sales_logs_on_created_by_id"
    t.index ["managing_organisation_id"], name: "index_sales_logs_on_managing_organisation_id"
    t.index ["old_id"], name: "index_sales_logs_on_old_id", unique: true
    t.index ["owning_organisation_id"], name: "index_sales_logs_on_owning_organisation_id"
    t.index ["updated_by_id"], name: "index_sales_logs_on_updated_by_id"
  end

  create_table "scheme_deactivation_periods", force: :cascade do |t|
    t.datetime "deactivation_date"
    t.datetime "reactivation_date"
    t.bigint "scheme_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheme_id"], name: "index_scheme_deactivation_periods_on_scheme_id"
  end

  create_table "schemes", force: :cascade do |t|
    t.string "service_name"
    t.bigint "owning_organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "primary_client_group"
    t.string "secondary_client_group"
    t.integer "sensitive"
    t.integer "scheme_type"
    t.integer "registered_under_care_act"
    t.integer "support_type"
    t.string "intended_stay"
    t.datetime "end_date"
    t.integer "has_other_client_group"
    t.string "arrangement_type"
    t.string "old_id"
    t.string "old_visible_id"
    t.integer "total_units"
    t.boolean "confirmed"
    t.datetime "startdate"
    t.datetime "discarded_at"
    t.index ["owning_organisation_id"], name: "index_schemes_on_owning_organisation_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.bigint "organisation_id"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "role"
    t.string "old_user_id"
    t.string "phone"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "is_dpo", default: false
    t.boolean "is_key_contact", default: false
    t.integer "second_factor_attempts_count", default: 0
    t.string "encrypted_otp_secret_key"
    t.string "encrypted_otp_secret_key_iv"
    t.string "encrypted_otp_secret_key_salt"
    t.string "direct_otp"
    t.datetime "direct_otp_sent_at"
    t.datetime "totp_timestamp", precision: nil
    t.boolean "active", default: true
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "initial_confirmation_sent"
    t.boolean "reactivate_with_organisation"
    t.datetime "discarded_at"
    t.string "phone_extension"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_otp_secret_key"], name: "index_users_on_encrypted_otp_secret_key", unique: true
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", limit: 191, null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "lettings_logs", "locations"
  add_foreign_key "lettings_logs", "organisations", column: "owning_organisation_id", on_delete: :cascade
  add_foreign_key "lettings_logs", "schemes"
  add_foreign_key "local_authority_links", "local_authorities"
  add_foreign_key "local_authority_links", "local_authorities", column: "linked_local_authority_id"
  add_foreign_key "locations", "schemes"
  add_foreign_key "organisation_relationships", "organisations", column: "child_organisation_id"
  add_foreign_key "organisation_relationships", "organisations", column: "parent_organisation_id"
  add_foreign_key "organisations", "organisations", column: "absorbing_organisation_id"
  add_foreign_key "sales_logs", "organisations", column: "owning_organisation_id", on_delete: :cascade
  add_foreign_key "schemes", "organisations", column: "owning_organisation_id", on_delete: :cascade
  add_foreign_key "users", "organisations", on_delete: :cascade
end
