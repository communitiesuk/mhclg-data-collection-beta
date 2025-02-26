FactoryBot.define do
  factory :sales_log do
    assigned_to { association :user }
    before(:create) { |log, _evaluator| log.assigned_to ||= create(:user) }

    created_by { assigned_to }
    owning_organisation { assigned_to.organisation }
    managing_organisation { assigned_to.organisation }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    trait :in_progress do
      purchid { "PC123" }
      ownershipsch { 2 }
      type { 8 }
      jointpur { 2 }
      saledate_today
    end
    trait :shared_ownership do
      ownershipsch { 1 }
      type { 30 }
    end
    trait :privacy_notice_seen do
      privacynotice { 1 }
    end
    trait :saledate_today do
      saledate { Time.zone.today }
    end
    trait :shared_ownership_setup_complete do
      saledate_today
      ownershipsch { 1 }
      type { 30 }
      jointpur { 2 }
      noint { 2 }
      privacynotice { 1 }
      purchid { rand(999_999_999).to_s }
      staircase { 1 }
    end
    trait :discounted_ownership_setup_complete do
      saledate_today
      ownershipsch { 2 }
      type { 9 }
      jointpur { 1 }
      jointmore { 1 }
      noint { 2 }
      privacynotice { 1 }
      purchid { rand(999_999_999).to_s }
    end
    trait :outright_sale_setup_complete do
      saledate_today
      ownershipsch { 3 }
      type { 10 }
      companybuy { 2 }
      buylivein { 1 }
      jointpur { 2 }
      noint { 2 }
      privacynotice { 1 }
      purchid { rand(999_999_999).to_s }
    end
    trait :duplicate do
      shared_ownership_setup_complete
      purchid { "PC123" }
      saledate_today
      age1_known { 1 }
      age1 { 20 }
      sex1 { "F" }
      ecstat1 { 1 }
      postcode_full { "A1 1AA" }
      noint { 2 }
      uprn_known { 0 }
      staircase { 1 }
    end
    trait :completed do
      purchid { rand(999_999_999).to_s }
      ownershipsch { 2 }
      type { 8 }
      saledate_today
      jointpur { 1 }
      beds { 2 }
      jointmore { 1 }
      noint { 2 }
      privacynotice { 1 }
      age1_known { 0 }
      age1 { Faker::Number.within(range: 27..45) }
      sex1 { %w[F M X R].sample }
      national { 18 }
      buy1livein { 1 }
      relat2 { "P" }
      proptype { 1 }
      age2_known { 0 }
      age2 { Faker::Number.within(range: 25..45) }
      builtype { 1 }
      ethnic { 3 }
      ethnic_group { 17 }
      sex2 { "X" }
      buy2livein { "1" }
      ecstat1 { "1" }
      ecstat2 { "1" }
      hholdcount { "4" }
      wheel { 1 }
      details_known_3 { 1 }
      age3_known { 0 }
      age3 { 14 }
      details_known_4 { 1 }
      age4_known { 0 }
      age4 { 18 }
      details_known_5 { 1 }
      age5_known { 0 }
      age5 { 40 }
      details_known_6 { 1 }
      age6_known { 0 }
      age6 { 40 }
      income1nk { 0 }
      income1 { 13_400 }
      inc1mort { 1 }
      income2nk { 0 }
      income2 { 13_400 }
      inc2mort { 1 }
      uprn_known { 0 }
      address_line1 { "Address line 1" }
      town_or_city { Faker::Address.city }
      la_known { 1 }
      la { "E09000003" }
      savingsnk { 1 }
      prevown { 1 }
      prevshared { 2 }
      sex3 { %w[F M X R].sample }
      sex4 { %w[F M X R].sample }
      sex5 { %w[F M X R].sample }
      sex6 { %w[F M X R].sample }
      mortgage { 20_000 }
      ecstat3 { 9 }
      ecstat4 { 3 }
      ecstat5 { 2 }
      ecstat6 { 1 }
      disabled { 1 }
      deposit { 80_000 }
      value { 110_000 }
      value_value_check { 0 }
      grant { 10_000 }
      proplen { 10 }
      pregyrha { 1 }
      pregla { 1 }
      pregother { 1 }
      pregghb { 1 }
      hhregres { 7 }
      ppcodenk { 1 }
      prevten { 1 }
      previous_la_known { 0 }
      relat3 { "C" }
      relat4 { "X" }
      relat5 { "R" }
      relat6 { "R" }
      hb { 4 }
      mortgageused { 1 }
      wchair { 1 }
      armedforcesspouse { 5 }
      has_mscharge { 1 }
      mscharge { 100 }
      mortlen { 10 }
      pcodenk { 0 }
      postcode_full { "SW1A 1AA" }
      is_la_inferred { false }
      mortgagelender { 5 }
      extrabor { 1 }
      ethnic_group2 { 17 }
      nationalbuy2 { 13 }
      buy2living { 3 }
      proplen_asked { 1 }
      after(:build) do |log, _evaluator|
        if log.saledate >= Time.zone.local(2024, 4, 1)
          log.address_line1_input = log.address_line1
          log.postcode_full_input = log.postcode_full
          log.nationality_all_group = 826
          log.nationality_all_buyer2_group = 826
          log.uprn = "10033558653"
          log.uprn_selection = 1
        end
        if log.saledate >= Time.zone.local(2025, 4, 1)
          log.relat2 = "X" if log.relat2 == "C"
          log.relat3 = "X" if log.relat3 == "C"
          log.relat4 = "X" if log.relat4 == "C"
          log.relat5 = "X" if log.relat5 == "C"
          log.relat6 = "X" if log.relat6 == "C"
        end
      end
    end
    trait :with_uprn do
      uprn { rand(999_999_999_999).to_s }
      uprn_known { 1 }
    end
    trait :deleted do
      status { 4 }
      discarded_at { Time.zone.now }
    end
    trait :imported do
      old_id { Random.hex }
    end
    trait :ignore_validation_errors do
      to_create do |instance|
        instance.valid?
        instance.errors.clear
        instance.save!(validate: false)
      end
    end
    trait :export do
      purchid { "123" }
      ownershipsch { 2 }
      type { 8 }
      saledate_today
      jointpur { 1 }
      beds { 2 }
      jointmore { 1 }
      noint { 2 }
      privacynotice { 1 }
      age1_known { 0 }
      age1 { 27 }
      sex1 { "F" }
      national { 18 }
      buy1livein { 1 }
      relat2 { "P" }
      proptype { 1 }
      age2_known { 0 }
      age2 { 33 }
      builtype { 1 }
      ethnic { 3 }
      ethnic_group { 17 }
      sex2 { "X" }
      buy2livein { "1" }
      ecstat1 { "1" }
      ecstat2 { "1" }
      hholdcount { "4" }
      wheel { 1 }
      details_known_3 { 1 }
      age3_known { 0 }
      age3 { 14 }
      details_known_4 { 1 }
      age4_known { 0 }
      age4 { 18 }
      details_known_5 { 1 }
      age5_known { 0 }
      age5 { 40 }
      details_known_6 { 1 }
      age6_known { 0 }
      age6 { 40 }
      income1nk { 0 }
      income1 { 10_000 }
      inc1mort { 1 }
      income2nk { 0 }
      income2 { 10_000 }
      inc2mort { 1 }
      uprn_known { 0 }
      address_line1 { "Address line 1" }
      town_or_city { "City" }
      la_known { 1 }
      la { "E09000003" }
      savingsnk { 1 }
      prevown { 1 }
      prevshared { 2 }
      sex3 { "F" }
      sex4 { "X" }
      sex5 { "M" }
      sex6 { "X" }
      mortgage { 20_000 }
      ecstat3 { 9 }
      ecstat4 { 3 }
      ecstat5 { 2 }
      ecstat6 { 1 }
      disabled { 1 }
      deposit { 80_000 }
      value { 110_000 }
      value_value_check { 0 }
      grant { 10_000 }
      proplen { 10 }
      pregyrha { 1 }
      pregla { 1 }
      pregother { 1 }
      pregghb { 1 }
      hhregres { 7 }
      ppcodenk { 1 }
      prevten { 1 }
      previous_la_known { 0 }
      relat3 { "X" }
      relat4 { "X" }
      relat5 { "R" }
      relat6 { "R" }
      hb { 4 }
      mortgageused { 1 }
      wchair { 1 }
      armedforcesspouse { 5 }
      has_mscharge { 1 }
      mscharge { 100 }
      mortlen { 10 }
      pcodenk { 0 }
      postcode_full { "SW1A 1AA" }
      is_la_inferred { false }
      mortgagelender { 5 }
      extrabor { 1 }
      ethnic_group2 { 17 }
      nationalbuy2 { 13 }
      buy2living { 3 }
      proplen_asked { 1 }
      address_line1_input { "Address line 1" }
      postcode_full_input { "SW1A 1AA" }
      nationality_all_group { 826 }
      nationality_all_buyer2_group { 826 }
      uprn { "10033558653" }
      uprn_selection { 1 }
    end
  end
end
