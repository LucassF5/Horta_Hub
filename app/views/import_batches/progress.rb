# frozen_string_literal: true

# Renderizado na página e nas respostas de polling (ImportBatchesController#progress).
# Enquanto a importação roda, o elemento carrega o poll_controller; a resposta
# final vem sem ele e o polling para sozinho.
class Views::ImportBatches::Progress < Views::Base
  include Phlex::Rails::Helpers::DOMID

  POLL_INTERVAL_MS = 2_000

  def initialize(import_batch:)
    @import_batch = import_batch
  end

  def view_template
    div(id: dom_id(@import_batch, :progress), data: poll_data) do
      render_progress_bar
      render_summary
      # A lista pode ter milhares de linhas; só é renderizada ao final para
      # manter leve cada resposta do polling.
      render_errors if !@import_batch.running? && @import_batch.error_details.any?
    end
  end

  private

  def poll_data
    return {} unless @import_batch.running?

    {
      controller: "poll",
      poll_url_value: progress_import_batch_path(@import_batch),
      poll_interval_value: POLL_INTERVAL_MS
    }
  end

  def render_progress_bar
    div(class: "mb-6") do
      div(class: "mb-1 flex justify-between text-sm text-gray-600") do
        span { status_label }
        span { "#{@import_batch.processed_rows}/#{@import_batch.total_rows} linhas (#{percentage}%)" }
      end

      div(class: "h-2 w-full rounded-full bg-gray-200") do
        div(class: "h-2 rounded-full bg-primary transition-all", style: "width: #{percentage}%")
      end
    end
  end

  def render_summary
    div(class: "mb-8 grid grid-cols-1 gap-4 md:grid-cols-3") do
      render_detail("Arquivo", @import_batch.file.filename.to_s)
      render_detail("Ano", @import_batch.year.to_s)
      render_detail("Status", status_label)
      render_detail("Total de linhas", @import_batch.total_rows.to_s)
      render_detail("Processadas", @import_batch.processed_rows.to_s)
      render_detail("Criadas", @import_batch.successful_rows.to_s)
      render_detail("Falhas", @import_batch.failed_rows.to_s)
      render_detail("Iniciada em", formatted_datetime(@import_batch.started_at))
      render_detail("Finalizada em", formatted_datetime(@import_batch.finished_at))
    end
  end

  def render_detail(label, value)
    div(class: "rounded-md border bg-white p-4") do
      p(class: "text-sm font-semibold text-gray-500") { label }
      p(class: "mt-1 text-lg text-gray-800") { value.presence || "-" }
    end
  end

  def render_errors
    div(class: "rounded-md border bg-white p-4") do
      h2(class: "mb-4 text-xl font-semibold text-gray-800") { "Erros" }

      render RubyUI::Table.new do
        render RubyUI::TableHeader.new do
          render RubyUI::TableRow.new do
            render RubyUI::TableHead.new { "Linha" }
            render RubyUI::TableHead.new { "Mensagem" }
          end
        end

        render RubyUI::TableBody.new do
          @import_batch.error_details.each do |error_detail|
            render RubyUI::TableRow.new do
              render RubyUI::TableCell.new { error_detail["row"].presence&.to_s || "-" }
              render RubyUI::TableCell.new { error_detail["message"].to_s }
            end
          end
        end
      end
    end
  end

  def percentage
    return 0 if @import_batch.total_rows.zero?

    (@import_batch.processed_rows * 100 / @import_batch.total_rows).clamp(0, 100)
  end

  def status_label
    case @import_batch.status
    when "pending" then "Pendente"
    when "processing" then "Processando"
    when "completed" then "Concluída"
    when "failed" then "Falhou"
    end
  end

  def formatted_datetime(value)
    return nil if value.blank?

    l(value, format: :short)
  end
end
