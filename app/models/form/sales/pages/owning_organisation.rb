class Form::Sales::Pages::OwningOrganisation < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "owning_organisation"
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::OwningOrganisationId.new(nil, nil, self),
    ]
  end

  def routed_to?(log, current_user)
    return false unless current_user
    return true if current_user.support?
    return true if has_multiple_stock_owners_with_own_stock?(current_user)

    stock_owners = if FeatureToggle.merge_organisations_enabled?
                     current_user.organisation.stock_owners.where(holds_own_stock: true) + current_user.organisation.absorbed_organisations.where(holds_own_stock: true)
                   else
                     current_user.organisation.stock_owners.where(holds_own_stock: true)
                   end

    if current_user.organisation.holds_own_stock?
      if FeatureToggle.merge_organisations_enabled? && current_user.organisation.absorbed_organisations.any?(&:holds_own_stock?)
        return true
      end
      return true if stock_owners.count >= 1

      log.update!(owning_organisation: current_user.organisation)
    else
      return false if stock_owners.count.zero?
      return true if stock_owners.count > 1

      log.update!(owning_organisation: stock_owners.first)
    end

    false
  end

private

  def has_multiple_stock_owners_with_own_stock?(user)
    user.organisation.stock_owners.where(holds_own_stock: true).count > 1 || user.organisation.holds_own_stock? && user.organisation.stock_owners.where(holds_own_stock: true).count >= 1
  end
end
