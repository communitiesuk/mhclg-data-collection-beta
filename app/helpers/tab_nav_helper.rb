module TabNavHelper
  include GovukLinkHelper

  def user_cell(user)
    [govuk_link_to(user.name, user), user.email].join("\n")
  end

  def org_cell(user)
    role = "<span class='app-!-colour-muted'>#{user.role.to_s.humanize}</span>"
    [user.organisation.name, role].join("\n")
  end

  def tab_items(user)
    items = [{ name: t("Details"), url: details_organisation_path(user.organisation) }]
    if user.data_coordinator?
      items << { name: t("Users"), url: users_organisation_path(user.organisation) }
    end
    items
  end
end
