FactoryBot.define do
  factory :lettings_log do
    assigned_to { association :user }
    created_by { assigned_to }
    owning_organisation { assigned_to.organisation }
    managing_organisation { assigned_to.organisation }
    created_at { Time.zone.today }
    updated_at { Time.zone.today }
    manual_address_entry_selected { true }

    before(:create) do |log, _evaluator|
      if log.period && !log.managing_organisation.organisation_rent_periods.exists?(rent_period: log.period)
        log.managing_organisation.organisation_rent_periods << build(:organisation_rent_period, rent_period: log.period)
      end
    end

    trait :setup_completed do
      startdate_today
      renewal { 0 }
      needstype { 1 }
      rent_type { 1 }
      declaration { 1 }
    end
    trait :in_progress do
      setup_completed
      status { 1 }
      tenancycode { Faker::Name.initials(number: 10) }
      postcode_full { Faker::Address.postcode }
      ppostcode_full { Faker::Address.postcode }
      hhmemb { 2 }
      age1 { 17 }
      age2 { 19 }
    end
    trait :duplicate do
      setup_completed
      status { 1 }
      tenancycode { "same tenancy code" }
      postcode_full { "A1 1AA" }
      uprn_known { 0 }
      declaration { 1 }
      age1_known { 0 }
      age1 { 18 }
      sex1 { "M" }
      hhmemb { 1 }
      ecstat1 { 0 }
      period { 2 }
      brent { 200 }
      scharge { 50 }
      pscharge { 40 }
      supcharg { 35 }
      tcharge { 325 }
      propcode { "same property code" }
      startdate { Time.zone.today }
    end
    trait :completed do
      startdate { Time.zone.today }
      status { 2 }
      tenancycode { Faker::Name.initials(number: 10) }
      age1_known { 0 }
      age1 { Faker::Number.within(range: 25..45) }
      sex1 { %w[F M X R].sample }
      ethnic_group { 0 }
      ethnic { 2 }
      national { 13 }
      prevten { 6 }
      ecstat1 { 0 }
      hhmemb { 2 }
      relat2 { "P" }
      age2_known { 0 }
      details_known_2 { 0 }
      age2 { Faker::Number.within(range: 25..45) }
      sex2 { %w[F M X R].sample }
      ecstat2 { 6 }
      homeless { 1 }
      underoccupation_benefitcap { 0 }
      leftreg { 4 }
      reservist { 1 }
      illness { 1 }
      preg_occ { 2 }
      startertenancy { 1 }
      tenancylength { 2 }
      tenancy { 4 }
      ppostcode_full { Faker::Address.postcode }
      rsnvac { 6 }
      unittype_gn { 7 }
      beds { 3 }
      voiddate { startdate - 2.days }
      offered { 2 }
      wchair { 1 }
      earnings { 268 }
      incfreq { 1 }
      benefits { 1 }
      period { 2 }
      brent { 200 }
      scharge { 50 }
      pscharge { 40 }
      supcharg { 35 }
      tcharge { 325 }
      layear { 2 }
      waityear { 7 }
      postcode_known { 1 }
      postcode_full { "SW1A 1AA" }
      reasonpref { 1 }
      cbl { 0 }
      chr { 1 }
      cap { 0 }
      accessible_register { 0 }
      reasonother { nil }
      housingneeds { 1 }
      housingneeds_type { 0 }
      housingneeds_other { 0 }
      housingneeds_a { 1 }
      housingneeds_b { 0 }
      housingneeds_c { 0 }
      housingneeds_f { 0 }
      housingneeds_g { 0 }
      housingneeds_h { 0 }
      illness_type_1 { 0 }
      illness_type_2 { 1 }
      illness_type_3 { 0 }
      illness_type_4 { 0 }
      illness_type_8 { 0 }
      illness_type_5 { 0 }
      illness_type_6 { 0 }
      illness_type_7 { 0 }
      illness_type_9 { 0 }
      illness_type_10 { 0 }
      rp_homeless { 0 }
      rp_insan_unsat { 1 }
      rp_medwel { 0 }
      rp_hardship { 0 }
      rp_dontknow { 0 }
      tenancyother { nil }
      net_income_value_check { nil }
      void_date_value_check { 1 }
      major_repairs_date_value_check { 1 }
      net_income_known { 0 }
      previous_la_known { 1 }
      property_owner_organisation { "Test" }
      property_manager_organisation { "Test" }
      renewal { 0 }
      rent_type { 1 }
      needstype { 1 }
      purchaser_code { 798_794 }
      reason { 4 }
      propcode { Faker::Name.initials(number: 10) }
      majorrepairs { 1 }
      la { "E09000003" }
      prevloc { "E07000105" }
      hb { 6 }
      hbrentshortfall { 1 }
      tshortfall { 12 }
      property_relet { 0 }
      mrcdate { startdate - 1.day }
      incref { 0 }
      armedforces { 1 }
      builtype { 1 }
      unitletas { 2 }
      has_benefits { 1 }
      is_carehome { 0 }
      declaration { 1 }
      first_time_property_let_as_social_housing { 0 }
      referral { 2 }
      uprn_known { 0 }
      joint { 3 }
      address_line1 { "Address line 1" }
      town_or_city { Faker::Address.city }
      ppcodenk { 1 }
      tshortfall_known { 1 }
      after(:build) do |log, evaluator|
        if log.startdate >= Time.zone.local(2024, 4, 1)
          log.nationality_all_group = 826
          log.uprn = evaluator.uprn || "10033558653"
          log.uprn_selection = evaluator.uprn_selection || "10033558653"
        end
      end
    end
    trait :export do
      tenancycode { "987654" }
      ppostcode_full { "LE5 1QP" }
      propcode { "MYPROP" }
      tenancylength { nil }
    end
    trait :sh do
      needstype { 2 }
      sheltered { 3 }
      household_charge { 0 }
    end
    trait :sheltered_housing do
      needstype { 2 }
    end
    trait :startdate_today do
      startdate { Time.zone.today }
    end
    trait :deleted do
      status { 4 }
      discarded_at { Time.zone.now }
    end
    trait :imported do
      old_id { Random.hex }
    end
    trait :with_illness_without_type do
      illness { 1 }
      illness_type_1 { false }
      illness_type_2 { false }
      illness_type_3 { false }
      illness_type_4 { false }
      illness_type_5 { false }
      illness_type_6 { false }
      illness_type_7 { false }
      illness_type_8 { false }
      illness_type_9 { false }
      illness_type_10 { false }
    end
    trait :ignore_validation_errors do
      to_create do |instance|
        instance.valid?
        instance.errors.clear
        instance.save!(validate: false)
      end
    end
  end
end
