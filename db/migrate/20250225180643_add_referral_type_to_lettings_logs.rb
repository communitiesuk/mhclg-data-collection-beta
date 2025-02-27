class AddReferralTypeToLettingsLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :lettings_logs, :referral_type, :integer
  end
end
