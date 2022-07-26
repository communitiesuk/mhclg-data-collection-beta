class ContentController < ApplicationController
  def accessibility_statement
    render_content_page :accessibility_statement, page_title: "Accessibility statement for Submit social housing lettings and sales data (CORE)"
  end

  def privacy_notice
    render_content_page :privacy_notice, page_title: "Privacy notice for tenants and buyers of new social housing"
  end

  def data_sharing_agreement
    render_content_page :data_sharing_agreement, page_title: "Data sharing agreement"
  end

private

  def render_content_page(page_name, page_title: nil, locals: {})
    raw_content = File.read("app/views/content/#{page_name}.md")
    content_with_erb_tags_replaced = ApplicationController.renderer.render(
      inline: raw_content,
      locals:,
    )

    @page_title = page_title || page_name.to_s.humanize
    @page_content = GovukMarkdown.render(content_with_erb_tags_replaced).html_safe

    render "content/page"
  end
end
