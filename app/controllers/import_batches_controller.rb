class ImportBatchesController < ApplicationController
  def index
    authorize! ImportBatch
    @import_batches = Current.organization.import_batches.with_attached_file.order(created_at: :desc)
    render Views::ImportBatches::Index.new(import_batches: @import_batches)
  end

  def show
    @import_batch = Current.organization.import_batches.find(params[:id])
    authorize! @import_batch
    render Views::ImportBatches::Show.new(import_batch: @import_batch)
  end

  # Polling do progresso (poll_controller.js). Rota separada do show porque o
  # redirect após o envio do formulário pelo Turbo também aceita turbo_stream.
  def progress
    @import_batch = Current.organization.import_batches.find(params[:id])
    authorize! @import_batch

    streams = [
      turbo_stream.replace(
        helpers.dom_id(@import_batch, :progress),
        Views::ImportBatches::Progress.new(import_batch: @import_batch)
      )
    ]
    streams << turbo_stream.update("flash_messages", Components::FlashMessages.new(messages: completion_message)) unless @import_batch.running?

    render turbo_stream: streams
  end

  def new
    @import_batch = Current.organization.import_batches.build
    authorize! @import_batch
    render Views::ImportBatches::New.new(import_batch: @import_batch)
  end

  def create
    @import_batch = Current.organization.import_batches.build(import_batch_params)
    @import_batch.user = Current.user
    @import_batch.status = :pending
    authorize! @import_batch

    if @import_batch.save
      SalesImportJob.perform_later(@import_batch)
      redirect_to @import_batch, notice: "Importação iniciada."
    else
      render Views::ImportBatches::New.new(import_batch: @import_batch), status: :unprocessable_entity
    end
  end

  private

  def completion_message
    if @import_batch.failed?
      { alert: "A importação falhou. Veja os erros abaixo." }
    elsif @import_batch.failed_rows.positive?
      { alert: "Importação concluída: #{@import_batch.successful_rows} linhas importadas, #{@import_batch.failed_rows} com erro." }
    else
      { notice: "Importação concluída: #{@import_batch.successful_rows} linhas importadas." }
    end
  end

  def import_batch_params
    params.expect(import_batch: %i[ file year ])
  end
end
