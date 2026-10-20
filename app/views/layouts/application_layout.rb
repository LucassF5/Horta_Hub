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
    { label: "Vendas", path: :sales_path, controller: "sales", icon: PhlexIcons::Lucide::ShoppingCart },
    { label: "Importações", path: :import_batches_path, controller: "import_batches", icon: PhlexIcons::Lucide::FileSpreadsheet }
  ].freeze

  # Abas do celular, na ordem de uso no dia a dia; o restante fica em "Mais".
  MOBILE_TAB_ITEMS = %w[home sales clients products].map do |controller|
    SIDEBAR_NAV_ITEMS.find { |item| item[:controller] == controller }
  end.freeze

  def view_template(&block)
    doctype
    html(lang: "pt-BR") do
      render_head
      render_body(&block)
    end
  end

  private

  def render_head
    head do
      title { content_for(:title) || "Horta Hub" }
      meta(name: "viewport", content: "width=device-width,initial-scale=1,viewport-fit=cover")
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
  end

  def render_body(&block)
    body(class: "text-foreground min-h-screen flex flex-col") do
      render RubyUI::SidebarWrapper.new do
        render_sidebar if authenticated?

        # O espaço extra no rodapé evita que a barra de abas do celular cubra o fim da página.
        main(class: [ "min-w-0 flex-1 bg-neutral-100 px-3 md:m-4 md:rounded-lg md:px-5", authenticated? ? "pb-28 md:pb-6" : "pb-6" ]) do
          render_application_toolbar if authenticated?
          render_page_header
          render_flash_messages
          yield
        end

        render_mobile_tab_bar if authenticated?
      end
    end
  end

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
        div(class: "min-w-0") do
          p(class: "truncate text-sm font-semibold leading-tight") { "Horta Hub" }
          p(class: "truncate text-xs text-muted-foreground") { Current.organization.name } if Current.organization
        end
      end

      # No celular o menu completo abre pela aba "Mais".
      render RubyUI::SidebarTrigger.new(
        title: "Abrir menu",
        aria: { label: "Abrir menu" },
        class: "hidden md:inline-flex md:h-7 md:w-7"
      )
    end
  end

  def render_sidebar_header
    render RubyUI::SidebarHeader.new(class: "p-3 pr-12 md:pr-3") do
      div(class: "flex items-center gap-3 rounded-md px-2 py-2 group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:px-0") do
        image_tag("/HortaHubIcon.png", alt: "Horta Hub", class: "size-9 rounded-md shrink-0")
        div(class: "flex min-w-0 flex-col group-data-[collapsible=icon]:hidden") do
          span(class: "truncate text-sm font-semibold") { "Horta Hub" }
        end
      end
      div(class: "group-data-[collapsible=icon]:hidden") do
        render_organization_context
      end
    end
  end

  def render_organization_context
    return span(class: "truncate text-xs text-muted-foreground") { "Gestao da horta" } if Current.organization.blank?

    organizations = Current.user.organizations.active.order(:name)

    if organizations.many?
      form_with(url: current_organization_path, method: :patch, local: true, class: "mt-1", data: { controller: "submit-on-change", action: "change->submit-on-change#submit" }) do
        render RubyUI::Select.new do
          render RubyUI::SelectInput.new(
            type: "hidden",
            name: "organization_id",
            value: Current.organization.id,
            data: { ruby_ui__select_target: "input" }
          )

          render RubyUI::SelectTrigger.new(
            class: [
              "h-8 border-sidebar-border bg-sidebar px-2 text-xs text-sidebar-foreground shadow-none",
              "focus:ring-sidebar-ring"
            ],
            aria: { label: "Organização atual" }
          ) do
            render RubyUI::SelectValue.new { Current.organization.name }
          end

          render RubyUI::SelectContent.new do
            organizations.each do |organization|
              render RubyUI::SelectItem.new(value: organization.id, aria_selected: organization.id == Current.organization.id) do
                organization.name
              end
            end
          end
        end
      end
    else
      span(class: "truncate text-xs text-muted-foreground") { Current.organization.name }
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

  def render_mobile_tab_bar
    nav(
      aria: { label: "Navegação principal" },
      class: [
        "fixed inset-x-0 bottom-0 z-30 border-t border-neutral-200 bg-white/95 backdrop-blur",
        "pb-[env(safe-area-inset-bottom)] md:hidden"
      ]
    ) do
      ul(class: "grid grid-cols-5") do
        MOBILE_TAB_ITEMS.each { |item| li { mobile_tab_link(item) } }
        li { mobile_more_button }
      end
    end
  end

  def mobile_tab_link(item)
    active = sidebar_item_active?(item[:controller])

    a(href: public_send(item[:path]), aria: { current: ("page" if active) }, class: mobile_tab_classes(active)) do
      mobile_tab_content(item[:icon], item[:label], active)
    end
  end

  # Abre a sidebar como gaveta, com as seções que não cabem nas abas, a troca de organização e o logout.
  def mobile_more_button
    active = MOBILE_TAB_ITEMS.none? { |item| sidebar_item_active?(item[:controller]) }

    button(
      type: "button",
      class: mobile_tab_classes(active),
      aria: { haspopup: "dialog" },
      data: { action: "click->ruby-ui--sidebar#toggle" }
    ) do
      mobile_tab_content(PhlexIcons::Lucide::Menu, "Mais", active)
    end
  end

  def mobile_tab_content(icon, label, active)
    span(class: [ "flex h-7 w-12 items-center justify-center rounded-full transition-colors", ("bg-green-100" if active) ]) do
      render icon.new(class: "size-5", aria: { hidden: true })
    end
    span { label }
  end

  def mobile_tab_classes(active)
    [
      "flex h-16 w-full flex-col items-center justify-center gap-1 text-[11px] font-medium",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring",
      active ? "text-green-800" : "text-neutral-500 hover:text-neutral-900"
    ]
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

  # Contêiner sempre presente para que turbo streams possam atualizar o flash.
  def render_flash_messages
    div(id: "flash_messages") do
      render Components::FlashMessages.new(messages: flash)
    end
  end
end
