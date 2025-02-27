require "rails_helper"

RSpec.describe BulkUpload, type: :model do
  let(:bulk_upload) { create(:bulk_upload, log_type: "lettings") }

  describe "def bulk_upload.completed?" do
    context "when there are incomplete logs" do
      it "returns false" do
        create(:lettings_log, :in_progress, bulk_upload:)
        expect(bulk_upload.completed?).to equal(false)
      end
    end

    context "when there are no incomplete logs" do
      it "returns true" do
        create(:lettings_log, :completed, :startdate_today, bulk_upload:)
        expect(bulk_upload.completed?).to equal(true)
      end
    end
  end

  describe "value check clearing" do
    context "with a lettings log bulk upload" do
      let(:log) { build(:lettings_log, startdate: Time.zone.local(2025, 4, 2), bulk_upload:) }

      it "has the correct number of value checks to be set as confirmed" do
        expect(bulk_upload.fields_to_confirm(log)).to match_array %w[rent_value_check void_date_value_check major_repairs_date_value_check pregnancy_value_check retirement_value_check referral_value_check net_income_value_check scharge_value_check pscharge_value_check supcharg_value_check multiple_partners_value_check partner_under_16_value_check reasonother_value_check]
      end
    end

    context "with a sales log bulk upload" do
      let(:log) { build(:sales_log, :saledate_today, bulk_upload:) }

      it "has the correct number of value checks to be set as confirmed" do
        expect(bulk_upload.fields_to_confirm(log)).to match_array %w[value_value_check monthly_charges_value_check percentage_discount_value_check income1_value_check income2_value_check combined_income_value_check retirement_value_check old_persons_shared_ownership_value_check buyer_livein_value_check student_not_child_value_check wheel_value_check mortgage_value_check savings_value_check deposit_value_check staircase_bought_value_check stairowned_value_check hodate_check shared_ownership_deposit_value_check extrabor_value_check grant_value_check discounted_sale_value_check deposit_and_mortgage_value_check multiple_partners_value_check partner_under_16_value_check]
      end
    end
  end

  describe "year_combo" do
    [
      { year: 2023, expected_value: "2023 to 2024" },
      { year: 2024, expected_value: "2024 to 2025" },
      { year: 2025, expected_value: "2025 to 2026" },
    ].each do |test_case|
      context "when the bulk upload year is #{test_case[:year]}" do
        let(:bulk_upload) { build(:bulk_upload, year: test_case[:year]) }

        it "returns the expected year combination string" do
          expect(bulk_upload.year_combo).to eq(test_case[:expected_value])
        end
      end
    end
  end

  describe "scopes" do
    let!(:lettings_bulk_upload_1) { create(:bulk_upload, log_type: "lettings") }
    let!(:lettings_bulk_upload_2) { create(:bulk_upload, log_type: "lettings") }
    let!(:sales_bulk_upload_1) { create(:bulk_upload, log_type: "sales") }
    let!(:sales_bulk_upload_2) { create(:bulk_upload, log_type: "sales") }

    describe ".lettings" do
      it "returns only lettings bulk uploads" do
        expect(described_class.lettings).to match_array([lettings_bulk_upload_1, lettings_bulk_upload_2])
      end
    end

    describe ".sales" do
      it "returns only sales bulk uploads" do
        expect(described_class.sales).to match_array([sales_bulk_upload_1, sales_bulk_upload_2])
      end
    end

    describe ".search_by_filename" do
      it "returns the correct bulk upload" do
        expect(described_class.search_by_filename(lettings_bulk_upload_1.filename).first).to eq(lettings_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.search_by_filename(lettings_bulk_upload_1.filename).first).not_to eq(lettings_bulk_upload_2)
      end
    end

    describe ".search_by_user_name" do
      it "returns the correct bulk upload" do
        expect(described_class.search_by_user_name(lettings_bulk_upload_1.user.name).first).to eq(lettings_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.search_by_user_name(lettings_bulk_upload_1.user.name).first).not_to eq(lettings_bulk_upload_2)
      end
    end

    describe ".search_by_user_email" do
      it "returns the correct bulk upload" do
        expect(described_class.search_by_user_email(sales_bulk_upload_1.user.email).first).to eq(sales_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.search_by_user_email(sales_bulk_upload_1.user.email).first).not_to eq(sales_bulk_upload_2)
      end
    end

    describe ".search_by_organisation_name" do
      it "returns the correct bulk upload" do
        expect(described_class.search_by_organisation_name(lettings_bulk_upload_1.user.organisation.name).first).to eq(lettings_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.search_by_organisation_name(lettings_bulk_upload_1.user.organisation.name).first).not_to eq(lettings_bulk_upload_2)
      end
    end

    describe ".filter_by_id" do
      it "returns the correct bulk upload" do
        expect(described_class.filter_by_id(lettings_bulk_upload_1.id).first).to eq(lettings_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.filter_by_id(lettings_bulk_upload_1.id).first).not_to eq(lettings_bulk_upload_2)
      end
    end

    describe ".filter_by_years" do
      it "returns the correct bulk upload" do
        expect(described_class.filter_by_years([lettings_bulk_upload_1.year]).first).to eq(lettings_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.filter_by_years([lettings_bulk_upload_1.year]).first).not_to eq(lettings_bulk_upload_2)
      end
    end

    describe ".filter_by_uploaded_by" do
      it "returns the correct bulk upload" do
        expect(described_class.filter_by_uploaded_by(sales_bulk_upload_1.user.id).first).to eq(sales_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.filter_by_uploaded_by(sales_bulk_upload_1.user.id).first).not_to eq(sales_bulk_upload_2)
      end
    end

    describe ".filter_by_user_text_search" do
      it "returns the correct bulk upload" do
        expect(described_class.filter_by_user_text_search(lettings_bulk_upload_1.user.name).first).to eq(lettings_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.filter_by_user_text_search(lettings_bulk_upload_1.user.name).first).not_to eq(lettings_bulk_upload_2)
      end
    end

    describe ".filter_by_user" do
      it "returns the correct bulk upload" do
        expect(described_class.filter_by_user(sales_bulk_upload_1.user.id).first).to eq(sales_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.filter_by_user(sales_bulk_upload_1.user.id).first).not_to eq(sales_bulk_upload_2)
      end
    end

    describe ".filter_by_uploading_organisation" do
      it "returns the correct bulk upload" do
        expect(described_class.filter_by_uploading_organisation(lettings_bulk_upload_1.user.organisation.id).first).to eq(lettings_bulk_upload_1)
      end

      it "does not return the incorrect bulk upload" do
        expect(described_class.filter_by_uploading_organisation(lettings_bulk_upload_1.user.organisation.id).first).not_to eq(lettings_bulk_upload_2)
      end
    end
  end

  describe "#status" do
    context "when the bulk upload was uploaded with a blank template" do
      let(:bulk_upload) { create(:bulk_upload, failure_reason: "blank_template") }

      it "returns the correct status" do
        expect(bulk_upload.status).to eq(:blank_template)
      end
    end

    context "when the bulk upload was uploaded with the wrong template" do
      let(:bulk_upload) { create(:bulk_upload, failure_reason: "wrong_template") }

      it "returns the correct status" do
        expect(bulk_upload.status).to eq(:wrong_template)
      end
    end

    context "when the bulk upload is processing" do
      let(:bulk_upload) { create(:bulk_upload, processing: true) }

      it "returns the correct status" do
        expect(bulk_upload.status).to eq(:processing)
      end
    end

    context "when the bulk upload has potential errors" do
      let(:bulk_upload_errors) { create_list(:bulk_upload_error, 2, category: "soft_validation") }
      let(:bulk_upload) { create(:bulk_upload, bulk_upload_errors:) }

      it "returns the correct status" do
        expect(bulk_upload.status).to eq(:potential_errors)
      end
    end

    context "when the bulk upload has critical errors" do
      let(:bulk_upload_errors) { create_list(:bulk_upload_error, 2, category: nil) }
      let(:bulk_upload) { create(:bulk_upload, bulk_upload_errors:) }

      it "returns the correct status" do
        expect(bulk_upload.status).to eq(:critical_errors)
      end
    end

    context "when the bulk upload has important errors" do
      let(:bulk_upload_errors) { create_list(:bulk_upload_error, 2, category: "setup") }
      let(:bulk_upload) { create(:bulk_upload, bulk_upload_errors:) }

      it "returns the correct status" do
        expect(bulk_upload.status).to eq(:important_errors)
      end
    end

    context "when the bulk upload has no errors" do
      let(:bulk_upload) { create(:bulk_upload) }

      it "returns the correct status" do
        expect(bulk_upload.status).to eq(:logs_uploaded_no_errors)
      end
    end

    context "when the bulk upload has visible logs, errors and is not complete" do
      let(:bulk_upload_errors) { create_list(:bulk_upload_error, 2, category: "soft_validation") }
      let(:bulk_upload) { create(:bulk_upload, :lettings, bulk_upload_errors:) }

      before do
        create(:lettings_log, :in_progress, bulk_upload:)
      end

      it "returns logs_uploaded_with_errors" do
        expect(bulk_upload.status).to eq(:logs_uploaded_with_errors)
      end
    end

    context "when the bulk upload has visible logs, errors and is complete" do
      let(:bulk_upload_errors) { create_list(:bulk_upload_error, 2, category: "soft_validation") }
      let(:bulk_upload) { create(:bulk_upload, :lettings, bulk_upload_errors:) }

      before do
        create(:lettings_log, :completed, bulk_upload:)
      end

      it "returns errors_fixed_in_service" do
        expect(bulk_upload.status).to eq(:errors_fixed_in_service)
      end
    end
  end

  describe "#unpend_and_confirm_soft_validations" do
    let(:bulk_upload) { create(:bulk_upload, :lettings) }
    let(:log) { create(:lettings_log, :completed, bulk_upload:, status: "pending", status_cache: "in_progress", supcharg: 183.24) }

    it "resets the fields to confirm and updates the status to status_cache" do
      expect(log.status).to eq("pending")

      bulk_upload.unpend_and_confirm_soft_validations

      log.reload
      expect(log.status).to eq("completed")
    end
  end
end
