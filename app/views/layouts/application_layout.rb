# frozen_string_literal: true

class Views::Layouts::ApplicationLayout < Views::Base
  include Phlex::Rails::Layout

  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::StyleSheetLinkTag
  include Phlex::Rails::Helpers::JavaScriptImportmapTags
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::CurrentPage
  include Phlex::Rails::Helpers::Flash
  include Phlex::Rails::Helpers::ImageTag

  def view_template(&block)
    doctype
    html do
      head do
        title { content_for(:title) || "Horta Hub" }
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        meta(name: "apple-mobile-web-app-capable", content: "yes")
        meta(name: "mobile-web-app-capable", content: "yes")
        csrf_meta_tags
        csp_meta_tag
        link(rel: "icon", href: "/HortaHubIcon.png", type: "image/png")
        link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
        link(rel: "apple-touch-icon", href: "/icon.png")
        stylesheet_link_tag :app, "data-turbo-track": "reload"
        javascript_importmap_tags
      end

      body(class: "text-foreground min-h-screen flex flex-col") do
        render RubyUI::SidebarWrapper.new do
          render_sidebar if authenticated?

          main(class: "flex-1 px-5 m-4 bg-neutral-100 rounded-lg") do
            render_page_header
            render_flash_messages
            yield
          end
        end
      end
    end
  end

  private

  def authenticated?
    Current.session.present?
  end

  def render_sidebar
    render RubyUI::Sidebar.new(variant: :inset, class: "hidden md:flex") do
      render RubyUI::SidebarContent.new do
        render RubyUI::SidebarHeader.new

        render RubyUI::SidebarGroup.new do
          render RubyUI::SidebarGroupContent.new do
            render RubyUI::SidebarMenu.new do
              sidebar_menu_item("Home", root_path)
              sidebar_menu_item("Produtos", products_path)
              sidebar_menu_item("Clientes", clients_path)
            end
          end
        end

        div(class: "flex-1")

        render RubyUI::SidebarFooter.new do
          form_with(url: session_path, method: :delete, local: true) do |_form|
            render RubyUI::Button.new(type: :submit, variant: :destructive, class: "w-full") { "Deslogar" }
          end
        end
      end
    end
  end

  def sidebar_menu_item(label, path)
    render RubyUI::SidebarMenuItem.new do
      render RubyUI::SidebarMenuButton.new(as: :a, href: path, active: current_page?(path)) do
        span { label }
      end
    end
  end

  def render_page_header
    page_title = content_for(:page_title)
    return if page_title.blank?

    div(class: "flex items-center gap-4 mb-6") do
      h1(class: "text-lg font-semibold") { page_title }
    end
  end

  def render_flash_messages
    return unless flash.any?

    div(class: "mb-4") do
      flash.each do |type, message|
        css = if type.to_s == "alert"
          "py-2 px-3 bg-red-50 mb-2 text-red-500 font-medium rounded-lg inline-block"
        else
          "py-2 px-3 bg-green-50 mb-2 text-green-500 font-medium rounded-lg inline-block"
        end
        p(class: css, id: type) { message }
      end
    end
  end
end
