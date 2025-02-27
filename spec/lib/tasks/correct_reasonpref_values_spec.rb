require "rails_helper"
require "rake"

RSpec.describe "correct_reasonpref_values" do
  describe ":correct_reasonpref_values", type: :task do
    subject(:task) { Rake::Task["correct_reasonpref_values"] }

    let(:organisation) { create(:organisation, rent_periods: [2]) }
    let(:user) { create(:user, organisation:) }

    before do
      Rake.application.rake_require("tasks/correct_reasonpref_values")
      Rake::Task.define_task(:environment)
      task.reenable
    end

    context "when the rake task is run" do
      context "and any of the reasonable_preference_reason options are not 1, 0 or nil" do
        let(:bulk_upload) { create(:bulk_upload, :lettings, year: 2024, rent_type_fix_status: BulkUpload.rent_type_fix_statuses[:not_applied]) }

        it "sets the options to 0" do
          log = build(:lettings_log, :completed, reasonpref: 1, rp_homeless: -2, rp_hardship: 2, rp_medwel: 3, rp_insan_unsat: 4, rp_dontknow: 1,
                                                 bulk_upload:, assigned_to: user)
          log.save!(validate: false)
          initial_updated_at = log.updated_at

          task.invoke
          log.reload

          expect(log.updated_at).not_to eq(initial_updated_at)
          expect(log.status).to eq("completed")
          expect(log.rp_homeless).to be(0)
          expect(log.rp_hardship).to be(0)
          expect(log.rp_medwel).to be(0)
          expect(log.rp_insan_unsat).to be(0)
          expect(log.rp_dontknow).to be(1)
        end

        it "updates the reasonable preference reason values on a pending log" do
          log = build(:lettings_log, :completed, status: "pending", reasonpref: 1, rp_homeless: -2, rp_hardship: 1, rp_medwel: 3, rp_insan_unsat: 4, rp_dontknow: 2, bulk_upload:, assigned_to: user)
          log.save!(validate: false)
          initial_updated_at = log.updated_at
          expect(log.status).to eq("pending")

          task.invoke
          log.reload
          expect(log.rp_homeless).to be(0)
          expect(log.rp_hardship).to be(1)
          expect(log.rp_medwel).to be(0)
          expect(log.rp_insan_unsat).to be(0)
          expect(log.rp_dontknow).to be(0)
          expect(log.status).to eq("pending")
          expect(log.updated_at).not_to eq(initial_updated_at)
        end

        it "does not update logs with valid values" do
          log = build(:lettings_log, :completed, reasonpref: 1, rp_homeless: 0, rp_hardship: 1, rp_medwel: 0, rp_insan_unsat: 0, rp_dontknow: 0, bulk_upload:, assigned_to: user)
          log.save!(validate: false)
          initial_updated_at = log.updated_at
          expect(log.status).to eq("completed")

          task.invoke
          log.reload

          expect(log.status).to eq("completed")
          expect(log.updated_at).to eq(initial_updated_at)
        end

        it "updates the reasonable preference reason values if some of the checkbox values are valid" do
          log = build(:lettings_log, :completed, status: "pending", reasonpref: 1, rp_homeless: 0, rp_hardship: 2, rp_medwel: 1, rp_insan_unsat: 0, rp_dontknow: 0, bulk_upload:, assigned_to: user)
          log.save!(validate: false)
          initial_updated_at = log.updated_at
          expect(log.status).to eq("pending")

          task.invoke
          log.reload
          expect(log.rp_homeless).to be(0)
          expect(log.rp_hardship).to be(0)
          expect(log.rp_medwel).to be(1)
          expect(log.rp_insan_unsat).to be(0)
          expect(log.rp_dontknow).to be(0)
          expect(log.status).to eq("pending")
          expect(log.updated_at).not_to eq(initial_updated_at)
        end

        it "updates the reasonable preference reason values on a 2023 log" do
          log = build(:lettings_log, :completed, startdate: Time.zone.local(2023, 6, 6), reasonpref: 1, rp_homeless: 0, rp_hardship: 2, rp_medwel: 1, rp_insan_unsat: 0, rp_dontknow: 0, bulk_upload:, assigned_to: user)
          log.save!(validate: false)
          initial_updated_at = log.updated_at

          task.invoke
          log.reload

          expect(log.updated_at).to eq(initial_updated_at)
          expect(log.rp_hardship).to eq(0)
        end

        it "does not update and logs error if a validation triggers" do
          log = build(:lettings_log, :completed, postcode_full: "0", reasonpref: 1, rp_homeless: 0, rp_hardship: 2, rp_medwel: 1, rp_insan_unsat: 0, rp_dontknow: 0, bulk_upload:, assigned_to: user)
          log.save!(validate: false)
          initial_updated_at = log.updated_at

          task.invoke
          log.reload

          expect(log.updated_at).to eq(initial_updated_at)
        end
      end
    end
  end
end
