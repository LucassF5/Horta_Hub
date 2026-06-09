# frozen_string_literal: true

class Views::Layouts::ApplicationLayout < Views::Base
  include Phlex::Rails::Layout

  include PhlexIcons

  include Phlex::Rails::Helpers::ControllerName
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::StyleSheetLinkTag
  include Phlex::Rails::Helpers::JavaScriptImportmapTags
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::Flash
  include Phlex::Rails::Helpers::ImageTag

  SIDEBAR_NAV_ITEMS = [
    { label: "Home", path: :root_path, controller: "home", icon: PhlexIcons::Lucide::House },
    { label: "Produtos", path: :products_path, controller: "products", icon: PhlexIcons::Lucide::Package },
    { label: "Clientes", path: :clients_path, controller: "clients", icon: PhlexIcons::Lucide::Users },
    { label: "Vendas", path: :sales_path, controller: "sales", icon: PhlexIcons::Lucide::ShoppingCart }
  ].freeze

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

          main(class: "min-w-0 flex-1 bg-neutral-100 px-3 pb-6 md:m-4 md:rounded-lg md:px-5") do
            render_application_toolbar if authenticated?
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
    render RubyUI::Sidebar.new(variant: :inset, collapsible: :icon) do
      render RubyUI::SidebarContent.new do
        render_sidebar_header

        render RubyUI::SidebarGroup.new do
          render RubyUI::SidebarGroupLabel.new { "Menu" }
          render RubyUI::SidebarGroupContent.new do
            render RubyUI::SidebarMenu.new do
              SIDEBAR_NAV_ITEMS.each { |item| sidebar_menu_item(item) }
            end
          end
        end

        div(class: "flex-1")

        render RubyUI::SidebarFooter.new do
          form_with(url: session_path, method: :delete, local: true) do |_form|
            render RubyUI::Button.new(
              type: :submit,
              variant: :destructive,
              title: "Deslogar",
              class: [
                "w-full justify-start gap-2",
                "group-data-[collapsible=icon]:justify-center",
                "group-data-[collapsible=icon]:px-0"
              ]
            ) do
              render PhlexIcons::Lucide::LogOut.new(class: "size-4 shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Deslogar" }
            end
          end
        end
      end
    end
  end

  def render_application_toolbar
    header(
      class: [
        "sticky top-0 z-20 -mx-3 mb-4 flex h-14 items-center",
        "justify-between border-b border-neutral-200/80 bg-neutral-100/95",
        "px-3 backdrop-blur md:static md:-mx-5 md:h-12 md:justify-start md:px-5"
      ]
    ) do
      div(class: "flex min-w-0 items-center gap-2 md:hidden") do
        image_tag("/HortaHubIcon.png", alt: "Horta Hub", class: "size-8 rounded-md")
        span(class: "truncate text-sm font-semibold") { "Horta Hub" }
      end

      render RubyUI::SidebarTrigger.new(
        title: "Abrir menu",
        aria: { label: "Abrir menu" },
        class: "h-9 w-9 md:h-7 md:w-7"
      )
    end
  end

  def render_sidebar_header
    render RubyUI::SidebarHeader.new(class: "p-3 pr-12 md:pr-3") do
      div(class: "flex items-center gap-3 rounded-md px-2 py-2 group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:px-0") do
        image_tag("/HortaHubIcon.png", alt: "Horta Hub", class: "size-9 rounded-md shrink-0")
        div(class: "flex min-w-0 flex-col group-data-[collapsible=icon]:hidden") do
          span(class: "truncate text-sm font-semibold") { "Horta Hub" }
          span(class: "truncate text-xs text-muted-foreground") { "Gestao da horta" }
        end
      end
    end
  end

  def sidebar_menu_item(item)
    path = public_send(item[:path])

    render RubyUI::SidebarMenuItem.new do
      render RubyUI::SidebarMenuButton.new(as: :a, href: path, active: sidebar_item_active?(item[:controller]), title: item[:label]) do
        render item[:icon].new(class: "size-4 shrink-0")
        span(class: "group-data-[collapsible=icon]:hidden") { item[:label] }
      end
    end
  end

  def sidebar_item_active?(item_controller)
    controller_name == item_controller
  end

  def render_page_header
    page_title = content_for(:page_title)
    return if page_title.blank?

    div(class: "mb-4 flex items-center gap-4 md:mb-6") do
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
