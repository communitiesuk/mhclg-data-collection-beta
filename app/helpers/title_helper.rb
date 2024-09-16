module TitleHelper
  def format_label(count, item)
    count > 1 ? item.pluralize : item
  end

  def format_title(searched, page_title, current_user, item_label, count, organisation_name)
    sanitised_organisation_name = sanitise_text(organisation_name)
    if searched.present?
      actual_title = support_sab_nav?(current_user, organisation_name) ? sanitised_organisation_name : page_title
      "#{actual_title} (#{count} #{item_label} matching ‘#{searched}’)".html_safe
    else
      support_sab_nav?(current_user, organisation_name) ? "#{sanitised_organisation_name} (#{page_title})".html_safe : page_title.html_safe
    end
  end

private

  def support_sab_nav?(current_user, organisation_name)
    current_user.support? && organisation_name
  end
end
