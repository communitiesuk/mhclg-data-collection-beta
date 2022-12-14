class AddEcstat3ToSales < ActiveRecord::Migration[7.0]
  def change
    change_table :sales_logs, bulk: true do |t|
      t.column :ecstat3, :integer
      t.column :ecstat4, :integer
      t.column :ecstat5, :integer
      t.column :ecstat6, :integer
    end
  end
end
