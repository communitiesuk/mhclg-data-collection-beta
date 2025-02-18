class AddUpdatedByToLogs < ActiveRecord::Migration[7.0]
  def change
    change_table :lettings_logs, bulk: true do |t|
      t.belongs_to :updated_by
    end
    change_table :sales_logs, bulk: true do |t|
      t.belongs_to :updated_by
    end
  end
end
