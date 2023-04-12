class AddMergeRequestsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :merge_requests do |t|
      t.integer :requesting_organisation_id
      t.integer :merging_organisations, array: true
      t.timestamps
    end
  end
end
