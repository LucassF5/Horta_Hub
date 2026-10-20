# frozen_string_literal: true

# Layout das telas de acesso (login, cadastro e senha): apresenta o Horta Hub ao
# lado do formulário, sem a navegação da área autenticada.
class Views::Layouts::AuthLayout < Views::Layouts::ApplicationLayout
  HIGHLIGHTS = [
    [ PhlexIcons::Lucide::ShoppingCart, "Vendas com itens, status e total calculado automaticamente" ],
    [ PhlexIcons::Lucide::FileSpreadsheet, "Histórico importado das planilhas que você já usa" ],
    [ PhlexIcons::Lucide::ShieldCheck, "Equipe com papéis de acesso e dados isolados por organização" ]
  ].freeze

  private

  def render_body(&block)
    body(class: "min-h-screen bg-white text-foreground") do
      div(class: "grid min-h-screen lg:grid-cols-[minmax(0,5fr)_minmax(0,6fr)]") do
        render_brand_panel

        main(class: "flex min-w-0 flex-col px-4 py-8 sm:px-8 lg:px-12") do
          render_compact_brand

          div(class: "mx-auto my-auto w-full max-w-md py-8") do
            render_flash_messages
            yield
          end
        end
      end
    end
  end

  def render_brand_panel
    aside(class: "relative hidden overflow-hidden bg-[#17382b] text-white lg:flex lg:flex-col lg:p-12") do
      # O traço do logo, ampliado e recortado na borda, faz a textura do painel.
      image_tag(
        "/HortaHubIcon.png",
        alt: "",
        aria: { hidden: true },
        class: "pointer-events-none absolute -bottom-40 -right-40 w-[40rem] max-w-none select-none opacity-[0.12] invert mix-blend-screen"
      )

      div(class: "relative flex items-center gap-3") do
        image_tag("/HortaHubIcon.png", alt: "", class: "size-10 rounded-lg bg-white")
        span(class: "text-lg font-semibold tracking-tight") { "Horta Hub" }
      end

      div(class: "relative my-auto max-w-md py-12") do
        h2(class: "text-4xl font-semibold leading-[1.1] tracking-tight text-balance") { "Gestão de vendas para quem vive da horta." }
        p(class: "mt-5 text-base leading-relaxed text-white/75") do
          "Cadastre produtos e clientes, registre cada venda e acompanhe o mês no painel, sem depender de cadernos e planilhas soltas."
        end

        ul(class: "mt-10 space-y-4") do
          HIGHLIGHTS.each do |icon, text|
            li(class: "flex items-start gap-3 text-sm text-white/90") do
              span(class: "mt-0.5 flex size-7 shrink-0 items-center justify-center rounded-md bg-white/10 text-[#b5d98a]") do
                render icon.new(class: "size-4", aria: { hidden: true })
              end
              span(class: "pt-1") { text }
            end
          end
        end
      end
    end
  end

  # Em telas pequenas o painel some; a marca fica no topo do formulário.
  def render_compact_brand
    div(class: "flex items-center gap-3 lg:hidden") do
      image_tag("/HortaHubIcon.png", alt: "", class: "size-9 rounded-lg border")
      div(class: "min-w-0") do
        p(class: "text-sm font-semibold leading-tight") { "Horta Hub" }
        p(class: "text-xs text-gray-500") { "Gestão de vendas para quem vive da horta." }
      end
    end
  end
end
