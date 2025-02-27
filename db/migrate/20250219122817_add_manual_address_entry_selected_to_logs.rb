class AddManualAddressEntrySelectedToLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :sales_logs, :manual_address_entry_selected, :boolean, default: false
    add_column :lettings_logs, :manual_address_entry_selected, :boolean, default: false
  end
end
