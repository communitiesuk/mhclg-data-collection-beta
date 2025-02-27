require "rails_helper"
require "rake"

RSpec.describe "recalculate_invalid_reasonpref_dontknow" do
  subject(:task) { Rake::Task["recalculate_invalid_rpdontknow"] }

  before do
    Rake.application.rake_require("tasks/recalculate_invalid_reasonpref_dontknow")
    Rake::Task.define_task(:environment)
    task.reenable
  end

  let(:invalid_logs) { create_list(:lettings_log, 5, :completed, reasonpref: 1, rp_dontknow: 1, rp_homeless: 1, rp_insan_unsat: rand(2), rp_medwel: rand(2), rp_hardship: rand(2), updated_at: Time.zone.local(2024, 4, 2, 12, 0, 0)) }
  let(:pre_2024_invalid_logs) do
    create_list(:lettings_log, 5, :completed, reasonpref: 1, rp_dontknow: 1, rp_homeless: 1, rp_insan_unsat: rand(2), rp_medwel: rand(2), rp_hardship: rand(2)).each do |log|
      log.startdate = Time.zone.local(rand(2021..2023), 4, 1)
      log.save!(validate: false)
    end
  end
  let(:valid_logs) { create_list(:lettings_log, 3, :completed, reasonpref: 1, rp_dontknow: 0, rp_homeless: 1, rp_insan_unsat: 1, rp_medwel: rand(2), rp_hardship: rand(2), updated_at: Time.zone.local(2024, 4, 2, 12, 0, 0)) }

  it "updates the logs from 2024/25 with invalid rp_dontknow values" do
    invalid_logs.each do |log|
      expect(log.reasonpref).to eq(1)
      expect(log.rp_dontknow).to eq(1)
      expect(log.rp_homeless).to eq(1)
    end
    task.invoke
    invalid_logs.each do |log|
      log.reload
      expect(log.reasonpref).to eq(1)
      expect(log.rp_dontknow).to eq(0)
      expect(log.rp_homeless).to eq(1)
      expect(log.updated_at).not_to eq(Time.zone.local(2024, 4, 2, 12, 0, 0))
    end
  end

  it "does not update the logs pre 2024 with invalid rp_dontknow values" do
    pre_2024_invalid_logs.each do |log|
      expect(log.reasonpref).to eq(1)
      expect(log.rp_dontknow).to eq(1)
      expect(log.rp_homeless).to eq(1)
    end
    task.invoke
    pre_2024_invalid_logs.each do |log|
      log.reload
      expect(log.reasonpref).to eq(1)
      expect(log.rp_dontknow).to eq(1)
      expect(log.rp_homeless).to eq(1)
    end
  end

  it "does not update the logs with valid rp_dontknow values" do
    valid_logs.each do |log|
      expect(log.reasonpref).to eq(1)
      expect(log.rp_dontknow).to eq(0)
      expect(log.rp_homeless).to eq(1)
      expect(log.rp_insan_unsat).to eq(1)
    end
    task.invoke
    valid_logs.each do |log|
      log.reload
      expect(log.reasonpref).to eq(1)
      expect(log.rp_dontknow).to eq(0)
      expect(log.rp_homeless).to eq(1)
      expect(log.rp_insan_unsat).to eq(1)
      expect(log.updated_at).to eq(Time.zone.local(2024, 4, 2, 12, 0, 0))
    end
  end
end
