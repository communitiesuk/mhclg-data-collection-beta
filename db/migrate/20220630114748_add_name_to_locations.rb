class AddNameToLocations < ActiveRecord::Migration[7.0]
  change_table :locations, bulk: true do |t|
    t.integer :total_units
  end
end
