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

ActiveRecord::Schema.define(version: 2021_11_03_090530) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "case_logs", force: :cascade do |t|
    t.integer "status", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "tenant_code"
    t.integer "age1"
    t.string "sex1"
    t.integer "ethnic"
    t.integer "national"
    t.integer "prevten"
    t.string "armed_forces"
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
    t.string "homeless"
    t.string "reason_for_leaving_last_settled_home"
    t.string "underoccupation_benefitcap"
    t.string "leftreg"
    t.string "reservist"
    t.string "armed_forces_partner"
    t.string "illness"
    t.string "preg_occ"
    t.string "accessibility_requirements"
    t.string "condition_effects"
    t.string "tenancy_code"
    t.string "startdate"
    t.string "startertenancy"
    t.string "tenancylength"
    t.string "tenancy"
    t.string "lettype"
    t.string "landlord"
    t.string "property_location"
    t.string "previous_postcode"
    t.string "property_relet"
    t.string "rsnvac"
    t.string "property_reference"
    t.string "unittype_gn"
    t.string "property_building_type"
    t.string "beds"
    t.string "property_void_date"
    t.string "property_major_repairs"
    t.string "property_major_repairs_date"
    t.integer "offered"
    t.string "wchair"
    t.integer "earnings"
    t.string "incfreq"
    t.string "benefits"
    t.string "housing_benefit"
    t.string "period"
    t.string "brent"
    t.string "scharge"
    t.string "pscharge"
    t.string "supcharge"
    t.string "tcharge"
    t.string "outstanding_amount"
    t.string "layear"
    t.string "lawaitlist"
    t.string "previous_la"
    t.string "property_postcode"
    t.string "reasonpref"
    t.string "reasonable_preference_reason"
    t.string "cbl"
    t.string "chr"
    t.string "cap"
    t.string "outstanding_rent_or_charges"
    t.string "other_reason_for_leaving_last_settled_home"
    t.boolean "housingneeds_a"
    t.boolean "housingneeds_b"
    t.boolean "housingneeds_c"
    t.boolean "housingneeds_f"
    t.boolean "housingneeds_g"
    t.boolean "housingneeds_h"
    t.boolean "accessibility_requirements_prefer_not_to_say"
    t.boolean "illness_type_1"
    t.boolean "illness_type_2"
    t.boolean "illness_type_3"
    t.boolean "illness_type_4"
    t.boolean "illness_type_8"
    t.boolean "illness_type_5"
    t.boolean "illness_type_6"
    t.boolean "illness_type_7"
    t.boolean "illness_type_9"
    t.boolean "illness_type_10"
    t.boolean "condition_effects_prefer_not_to_say"
    t.boolean "rp_homeless"
    t.boolean "rp_insan_unsat"
    t.boolean "rp_medwel"
    t.boolean "rp_hardship"
    t.boolean "rp_dontknow"
    t.datetime "discarded_at"
    t.boolean "override_net_income_validation"
    t.string "tenancyother"
    t.string "net_income_known"
    t.index ["discarded_at"], name: "index_case_logs_on_discarded_at"
  end

end
