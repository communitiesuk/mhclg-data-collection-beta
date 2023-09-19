require "rails_helper"

RSpec.describe Imports::ImportReportService do
  subject(:report_service) { described_class.new(storage_service, institutions_csv) }

  let(:storage_service) { instance_double(Storage::S3Service) }

  describe "#generate_missing_data_coordinators_report" do
    context "when all organisations have data coordinators" do
      let!(:organisation) { create(:organisation, old_visible_id: "1", name: "org1") }
      let(:institutions_csv) { CSV.parse("Institution name,Id,Old Completed lettings logs,Old In progress lettings logs,Old Completed sales logs,Old In progress sales logs\norg1,1,2,1,4,3", headers: true) }

      before do
        create(:user, :data_coordinator, organisation:)
      end

      it "writes an empty organisations without a data coordinators report" do
        expect(storage_service).to receive(:write_file).with("OrganisationsWithoutDataCoordinators_report_suffix.csv", "\uFEFFOrganisation ID,Old Organisation ID,Organisation Name\n")

        report_service.generate_missing_data_coordinators_report("report_suffix.csv")
      end
    end

    context "when some organisations have no data coordinators" do
      let!(:organisation) { create(:organisation, old_visible_id: "1", name: "org1") }
      let!(:organisation2) { create(:organisation, old_visible_id: "2", name: "org2") }
      let!(:organisation3) { create(:organisation, old_visible_id: "3", name: "org3") }
      let(:institutions_csv) { CSV.parse("Institution name,Id,Old Completed lettings logs,Old In progress lettings logs,Old Completed sales logs,Old In progress sales logs\norg1,1,2,1,4,3\norg2,2,5,6,5,7\norg3,3,5,6,5,7", headers: true) }

      before do
        create(:user, :data_coordinator, organisation:)
      end

      it "writes an empty organisations without a data coordinators report" do
        expect(storage_service).to receive(:write_file).with("OrganisationsWithoutDataCoordinators_report_suffix.csv", "\uFEFFOrganisation ID,Old Organisation ID,Organisation Name\n#{organisation2.id},2,org2\n#{organisation3.id},3,org3\n")

        report_service.generate_missing_data_coordinators_report("report_suffix.csv")
      end
    end

    context "when organisation has an inactive data coordinator" do
      let!(:organisation) { create(:organisation, old_visible_id: "1", name: "org1") }
      let(:institutions_csv) { CSV.parse("Institution name,Id,Old Completed lettings logs,Old In progress lettings logs,Old Completed sales logs,Old In progress sales logs\norg1,1,2,1,4,3", headers: true) }

      before do
        create(:user, :data_coordinator, organisation:, active: false)
      end

      it "includes that organisation in the data coordinators report" do
        expect(storage_service).to receive(:write_file).with("OrganisationsWithoutDataCoordinators_report_suffix.csv", "\uFEFFOrganisation ID,Old Organisation ID,Organisation Name\n#{organisation.id},1,org1\n")

        report_service.generate_missing_data_coordinators_report("report_suffix.csv")
      end
    end
  end

  describe "#generate_logs_report" do
    let(:institutions_csv) { CSV.parse("Institution name,Id,Old Completed lettings logs,Old In progress lettings logs,Old Completed sales logs,Old In progress sales logs\norg1,1,2,1,4,3\norg2,2,5,6,5,7", headers: true) }

    before do
      create(:organisation, old_visible_id: "1", name: "org1")
      create(:organisation, old_visible_id: "2", name: "org2")
    end

    it "generates a report with imported logs" do
      expect(storage_service).to receive(:write_file).with("MigratedLogsReport_report_suffix.csv", "\uFEFFInstitution name,Id,Old Completed lettings logs,Old In progress lettings logs,Old Completed sales logs,Old In progress sales logs,New Completed lettings logs,New In Progress lettings logs,New Completed sales logs,New In Progress sales logs\norg1,1,2,1,4,3,0,0,0,0\norg2,2,5,6,5,7,0,0,0,0\n")
      report_service.generate_logs_report("report_suffix.csv")
    end
  end

  describe "#generate_unassigned_logs_report" do
    context "when there is no unassigned user (all the logs have ben assigned)" do
      let(:institutions_csv) { CSV.parse("Institution name,Id,Old Completed lettings logs,Old In progress lettings logs,Old Completed sales logs,Old In progress sales logs\norg1,1,2,1,4,3", headers: true) }

      it "writes an empty unassigned logs report" do
        expect(storage_service).to receive(:write_file).with("UnassignedLogsReport_report_suffix.csv", "\uFEFFOwning Organisation ID,Old Owning Organisation ID,Managing Organisation ID,Old Managing Organisation ID,Log ID,Old Log ID,Tenancy code,Purchaser code\n")

        report_service.generate_unassigned_logs_report("report_suffix.csv")
      end
    end

    context "when some logs have been added to Unassigned user" do
      let(:organisation) { create(:organisation, old_org_id: "1", name: "org1") }
      let(:organisation2) { create(:organisation, old_org_id: "2", name: "org2") }
      let(:unassigned_user) { create(:user, name: "Unassigned", organisation:) }
      let(:institutions_csv) { CSV.parse("Institution name,Id,Old Completed lettings logs,Old In progress lettings logs,Old Completed sales logs,Old In progress sales logs\norg1,1,2,1,4,3", headers: true) }
      let!(:lettings_log) { create(:lettings_log, owning_organisation: organisation, managing_organisation: organisation2, created_by: unassigned_user, tenancycode: "tenancycode", old_id: "12") }
      let!(:sales_log) { create(:sales_log, owning_organisation: organisation, created_by: unassigned_user, purchid: "purchid", old_id: "23") }

      before do
        create(:organisation_relationship, parent_organisation: organisation, child_organisation: organisation2)
      end

      it "writes a report with all unassigned logs" do
        expect(storage_service).to receive(:write_file).with("UnassignedLogsReport_report_suffix.csv", "\uFEFFOwning Organisation ID,Old Owning Organisation ID,Managing Organisation ID,Old Managing Organisation ID,Log ID,Old Log ID,Tenancy code,Purchaser code\n#{organisation.id},1,#{organisation2.id},2,#{lettings_log.id},12,tenancycode,\n#{organisation.id},1,,,#{sales_log.id},23,,purchid\n")

        report_service.generate_unassigned_logs_report("report_suffix.csv")
      end
    end
  end

  describe "#generate_missing_answers_report" do
    context "when there are in progress imported lettings logs" do
      let(:institutions_csv) { nil }
      let(:expected_content) { File.read("spec/fixtures/files/imported_lettings_logs_missing_answers_report.csv") }
      let(:expected_answers_examples_content) { File.read("spec/fixtures/files/imported_lettings_logs_missing_answers_examples.csv") }

      before do
        create_list(:lettings_log, 10, :completed, age1_known: nil) do |log, i|
          log.old_form_id = "100#{i}"
          log.old_id = "old_id_age1_known_#{i}"
          log.save!
          expected_answers_examples_content.sub!("{id#{i}}", log.id.to_s)
          expected_answers_examples_content.sub!("{org_id#{i}}", log.owning_organisation_id.to_s)
        end
        create_list(:lettings_log, 4, :completed, beds: nil) do |log, i|
          log.old_form_id = "200#{i}"
          log.old_id = "old_id_beds_#{i}"
          expected_answers_examples_content.sub!("{id2_#{i}}", log.id.to_s)
          expected_answers_examples_content.sub!("{org_id2_#{i}}", log.owning_organisation_id.to_s)
          log.save!
        end
        create(:lettings_log, :completed, age1_known: nil, beds: nil, old_form_id: "300", old_id: "beds_and_age") do |log|
          expected_answers_examples_content.sub!("{id}", log.id.to_s)
          expected_answers_examples_content.sub!("{org_id}", log.owning_organisation_id.to_s)
        end

        create_list(:lettings_log, 2, :completed, age1_known: nil)
      end

      xit "generates a csv with expected missing fields" do
        expect(storage_service).to receive(:write_file).with("MissingAnswersReportLettingsLog_report_suffix.csv", "﻿#{expected_content}")
        expect(storage_service).to receive(:write_file).with("MissingAnswersExamplesLettingsLog_report_suffix.csv", "﻿#{expected_answers_examples_content}")
        expect(storage_service).to receive(:write_file).with("MissingAnswersReportSalesLog_report_suffix.csv", "\uFEFFMissing answers,Total number of affected logs\n")
        expect(storage_service).to receive(:write_file).with("MissingAnswersExamplesSalesLog_report_suffix.csv", "\uFEFFMissing answers,Organisation ID,Log ID,Old Form ID,Old Log ID\n")

        report_service.generate_missing_answers_report("report_suffix")
      end
    end

    context "when there are in progress imported sales logs" do
      let(:institutions_csv) { nil }
      let(:expected_content) { File.read("spec/fixtures/files/imported_lettings_logs_missing_answers_report.csv") }
      let(:expected_answers_examples_content) { File.read("spec/fixtures/files/imported_lettings_logs_missing_answers_examples.csv") }

      before do
        create_list(:sales_log, 10, :completed, age1_known: nil) do |log, i|
          log.old_id = "old_id_age1_known_#{i}"
          log.old_form_id = "100#{i}"
          log.save!
          expected_answers_examples_content.sub!("{id#{i}}", log.id.to_s)
          expected_answers_examples_content.sub!("{org_id#{i}}", log.owning_organisation_id.to_s)
        end
        create_list(:sales_log, 4, :completed, beds: nil) do |log, i|
          log.old_id = "old_id_beds_#{i}"
          log.old_form_id = "200#{i}"
          expected_answers_examples_content.sub!("{id2_#{i}}", log.id.to_s)
          expected_answers_examples_content.sub!("{org_id2_#{i}}", log.owning_organisation_id.to_s)
          log.save!
        end
        create(:sales_log, :completed, age1_known: nil, beds: nil, old_id: "beds_and_age", old_form_id: "300") do |log|
          expected_answers_examples_content.sub!("{id}", log.id.to_s)
          expected_answers_examples_content.sub!("{org_id}", log.owning_organisation_id.to_s)
        end

        create_list(:sales_log, 2, :completed, age1_known: nil)
      end

      xit "generates a csv with expected missing fields" do
        expect(storage_service).to receive(:write_file).with("MissingAnswersReportLettingsLog_report_suffix.csv", "\uFEFFMissing answers,Total number of affected logs\n")
        expect(storage_service).to receive(:write_file).with("MissingAnswersExamplesLettingsLog_report_suffix.csv", "\uFEFFMissing answers,Organisation ID,Log ID,Old Form ID,Old Log ID\n")
        expect(storage_service).to receive(:write_file).with("MissingAnswersReportSalesLog_report_suffix.csv", "﻿#{expected_content}")
        expect(storage_service).to receive(:write_file).with("MissingAnswersExamplesSalesLog_report_suffix.csv", "﻿#{expected_answers_examples_content}")

        report_service.generate_missing_answers_report("report_suffix")
      end
    end
  end
end
