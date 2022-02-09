class User < ApplicationRecord
  include Constants::User

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :trackable

  belongs_to :organisation
  has_many :owned_case_logs, through: :organisation
  has_many :managed_case_logs, through: :organisation

  has_paper_trail

  enum role: ROLES

  def case_logs
    CaseLog.for_organisation(organisation)
  end

  def completed_case_logs
    case_logs.completed
  end

  def not_completed_case_logs
    case_logs.not_completed
  end
end
