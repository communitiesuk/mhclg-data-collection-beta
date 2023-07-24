class Merge::MergeOrganisationsService
  def initialize(absorbing_organisation_id:, merging_organisation_ids:)
    @absorbing_organisation = Organisation.find(absorbing_organisation_id)
    @merging_organisations = Organisation.find(merging_organisation_ids)
  end

  def call
    merge_organisation_details
    merge_rent_periods
    merge_organisation_relationships
    merge_users
    mark_organisations_as_merged
    @absorbing_organisation.save!
  end

private

  def merge_organisation_details
    @absorbing_organisation.holds_own_stock = merge_boolean_organisation_attribute("holds_own_stock")
    @absorbing_organisation.choice_based_lettings = merge_boolean_organisation_attribute("choice_based_lettings")
    @absorbing_organisation.common_housing_register = merge_boolean_organisation_attribute("common_housing_register")
    @absorbing_organisation.choice_allocation_policy = merge_boolean_organisation_attribute("choice_allocation_policy")
  end

  def merge_rent_periods
    @merging_organisations.each do |merging_organisation|
      merging_organisation.rent_periods.each do |rent_period|
        @absorbing_organisation.organisation_rent_periods << OrganisationRentPeriod.new(rent_period:) unless @absorbing_organisation.rent_periods.include?(rent_period)
      end
    end
  end

  def merge_organisation_relationships
    @merging_organisations.each do |merging_organisation|
      merging_organisation.parent_organisation_relationships.each do |parent_organisation_relationship|
        if parent_relationship_exists_on_absorbing_organisation?(parent_organisation_relationship)
          parent_organisation_relationship.destroy!
        else
          parent_organisation_relationship.update!(child_organisation: @absorbing_organisation)
        end
      end
      merging_organisation.child_organisation_relationships.each do |child_organisation_relationship|
        if child_relationship_exists_on_absorbing_organisation?(child_organisation_relationship)
          child_organisation_relationship.destroy!
        else
          child_organisation_relationship.update!(parent_organisation: @absorbing_organisation)
        end
      end
    end
  end

  def merge_users
    @merging_organisations.each do |merging_organisation|
      merging_organisation.users.update_all(organisation_id: @absorbing_organisation.id)
    end
  end

  def mark_organisations_as_merged
    # @merging_organisations.update_all(merge_date: Time.zone.today)
  end

  def merge_boolean_organisation_attribute(attribute)
    @absorbing_organisation[attribute] ||= @merging_organisations.any? { |merging_organisation| merging_organisation[attribute] }
  end

  def parent_relationship_exists_on_absorbing_organisation?(parent_organisation_relationship)
    parent_organisation_relationship.parent_organisation == @absorbing_organisation || @absorbing_organisation.parent_organisation_relationships.where(parent_organisation: parent_organisation_relationship.parent_organisation).exists?
  end

  def child_relationship_exists_on_absorbing_organisation?(child_organisation_relationship)
    child_organisation_relationship.child_organisation == @absorbing_organisation || @absorbing_organisation.child_organisation_relationships.where(child_organisation: child_organisation_relationship.child_organisation).exists?
  end
end
