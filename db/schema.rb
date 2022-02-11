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

ActiveRecord::Schema[7.0].define(version: 202202071123100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "second_factor_attempts_count", default: 0
    t.string "encrypted_otp_secret_key"
    t.string "encrypted_otp_secret_key_iv"
    t.string "encrypted_otp_secret_key_salt"
    t.string "direct_otp"
    t.datetime "direct_otp_sent_at", precision: nil
    t.datetime "totp_timestamp", precision: nil
    t.string "phone"
    t.index ["encrypted_otp_secret_key"], name: "index_admin_users_on_encrypted_otp_secret_key", unique: true
  end

  create_table "case_logs", force: :cascade do |t|
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tenant_code"
    t.integer "age1"
    t.string "sex1"
    t.integer "ethnic"
    t.integer "national"
    t.integer "prevten"
    t.integer "ecstat1"
    t.integer "hhmemb"
    t.string "relat2"
    t.integer "age2"
    t.string "sex2"
    t.integer "ecstat2"
    t.string "relat3"
    t.integer "age3"
    t.string "sex3"
    t.integer "ecstat3"
    t.string "relat4"
    t.integer "age4"
    t.string "sex4"
    t.integer "ecstat4"
    t.string "relat5"
    t.integer "age5"
    t.string "sex5"
    t.integer "ecstat5"
    t.string "relat6"
    t.integer "age6"
    t.string "sex6"
    t.integer "ecstat6"
    t.string "relat7"
    t.integer "age7"
    t.string "sex7"
    t.integer "ecstat7"
    t.string "relat8"
    t.integer "age8"
    t.string "sex8"
    t.integer "ecstat8"
    t.integer "homeless"
    t.integer "underoccupation_benefitcap"
    t.integer "leftreg"
    t.integer "reservist"
    t.integer "illness"
    t.integer "preg_occ"
    t.string "tenancy_code"
    t.integer "startertenancy"
    t.integer "tenancylength"
    t.integer "tenancy"
    t.integer "landlord"
    t.string "previous_postcode"
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
    t.integer "lawaitlist"
    t.string "property_postcode"
    t.integer "reasonpref"
    t.integer "cbl"
    t.integer "chr"
    t.integer "cap"
    t.string "other_reason_for_leaving_last_settled_home"
    t.integer "housingneeds_a"
    t.integer "housingneeds_b"
    t.integer "housingneeds_c"
    t.integer "housingneeds_f"
    t.integer "housingneeds_g"
    t.integer "housingneeds_h"
    t.integer "accessibility_requirements_prefer_not_to_say"
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
    t.integer "override_net_income_validation"
    t.string "property_owner_organisation"
    t.string "property_manager_organisation"
    t.string "sale_or_letting"
    t.string "renewal"
    t.string "rent_type"
    t.string "intermediate_rent_product_name"
    t.string "purchaser_code"
    t.integer "reason"
    t.string "propcode"
    t.integer "majorrepairs"
    t.string "la"
    t.string "prevloc"
    t.integer "hb"
    t.integer "hbrentshortfall"
    t.string "postcode"
    t.string "postcod2"
    t.string "ppostc1"
    t.string "ppostc2"
    t.integer "property_relet"
    t.datetime "mrcdate", precision: nil
    t.integer "mrcday"
    t.integer "mrcmonth"
    t.integer "mrcyear"
    t.integer "other_hhmemb"
    t.integer "incref"
    t.datetime "sale_completion_date", precision: nil
    t.datetime "startdate", precision: nil
    t.integer "armedforces"
    t.integer "first_time_property_let_as_social_housing"
    t.integer "unitletas"
    t.integer "builtype"
    t.datetime "property_void_date", precision: nil
    t.bigint "owning_organisation_id"
    t.bigint "managing_organisation_id"
    t.integer "renttype"
    t.integer "needstype"
    t.integer "lettype"
    t.integer "postcode_known"
    t.integer "la_known"
    t.boolean "is_la_inferred"
    t.integer "day"
    t.integer "month"
    t.integer "year"
    t.integer "totchild"
    t.integer "totelder"
    t.integer "totadult"
    t.integer "net_income_known"
    t.string "has_benefits"
    t.integer "nocharge"
    t.integer "is_carehome"
    t.integer "letting_in_sheltered_accommodation"
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
    t.integer "previous_postcode_known"
    t.integer "previous_la_known"
    t.boolean "is_previous_la_inferred"
    t.boolean "letting_allocation_unknown"
    t.index ["managing_organisation_id"], name: "index_case_logs_on_managing_organisation_id"
    t.index ["owning_organisation_id"], name: "index_case_logs_on_owning_organisation_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.integer "provider_type"
    t.string "address_line1"
    t.string "address_line2"
    t.string "postcode"
    t.string "local_authorities"
    t.boolean "holds_own_stock"
    t.string "other_stock_owners"
    t.string "managing_agents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active"
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
    t.integer "old_visible_id"
    t.index ["old_visible_id"], name: "index_organisations_on_old_visible_id", unique: true
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", limit: 191, null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
