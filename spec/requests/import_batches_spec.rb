require "rails_helper"

RSpec.describe "ImportBatches", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:role) { "owner" }
  let!(:membership) { create(:membership, user: user, organization: organization, role: role) }

  before do
    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
    allow(Current).to receive(:session).and_return(session)
    allow(Current).to receive(:user).and_return(user)
    allow(Current).to receive(:organization).and_return(organization)
  end

  def uploaded_xlsx
    tempfile = Tempfile.new([ "vendas", ".xlsx" ])
    tempfile.write("xlsx")
    tempfile.rewind

    Rack::Test::UploadedFile.new(
      tempfile.path,
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  end

  describe "GET /import_batches" do
    it "renders import batches from the current organization" do
      create(:import_batch, organization: organization, user: user, year: 2026)

      other_organization = create(:organization)
      create(:import_batch, organization: other_organization, user: create(:user), year: 2025)

      get import_batches_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("2026")
      expect(response.body).not_to include("2025")
    end
  end

  describe "GET /import_batches/new" do
    it "renders the upload form" do
      get new_import_batch_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Nova Importação")
      expect(response.body).to include("Arquivo XLSX")
      expect(response.body).to include("Ano")
    end
  end

  describe "GET /import_batches/:id" do
    it "renders import status and errors" do
      import_batch = create(:import_batch, organization: organization, user: user, year: 2026, status: :completed)
      import_batch.add_error_detail(row: 3, message: "Status inválido")

      get import_batch_path(import_batch)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Importação ##{import_batch.id}")
      expect(response.body).to include("Status inválido")
    end

    it "polls progress while the import is running and hides the error list" do
      import_batch = create(:import_batch, organization: organization, user: user, status: :processing)
      import_batch.add_error_detail(row: 3, message: "Status inválido")

      get import_batch_path(import_batch)

      expect(response.body).to include(%(id="progress_import_batch_#{import_batch.id}"))
      expect(response.body).to include(%(data-controller="poll"))
      expect(response.body).to include(%(data-poll-url-value="#{progress_import_batch_path(import_batch)}"))
      expect(response.body).not_to include("Status inválido")
    end

    it "keeps showing the batch history after the spreadsheet was removed" do
      import_batch = create(:import_batch, organization: organization, user: user, status: :completed, successful_rows: 3)
      import_batch.purge_file

      get import_batch_path(import_batch)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("vendas.xlsx")

      get import_batches_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("vendas.xlsx")
    end

    it "stops polling once the import is finished" do
      import_batch = create(:import_batch, organization: organization, user: user, status: :completed)

      get import_batch_path(import_batch)

      expect(response.body).not_to include(%(data-controller="poll"))
    end

    it "does not expose imports from another organization" do
      other_organization = create(:organization)
      import_batch = create(:import_batch, organization: other_organization, user: create(:user))

      get import_batch_path(import_batch)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /import_batches/:id/progress" do
    let(:turbo_stream_accept) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "replaces the progress section without touching the flash while running" do
      import_batch = create(:import_batch, organization: organization, user: user, status: :processing,
                                           total_rows: 10, processed_rows: 4)

      get progress_import_batch_path(import_batch), headers: turbo_stream_accept

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(action="replace" target="progress_import_batch_#{import_batch.id}"))
      expect(response.body).to include("4/10 linhas (40%)")
      expect(response.body).to include(%(data-controller="poll"))
      expect(response.body).not_to include(%(target="flash_messages"))
    end

    it "shows a completion notice once the import finishes" do
      import_batch = create(:import_batch, organization: organization, user: user, status: :completed,
                                           total_rows: 3, processed_rows: 3, successful_rows: 3)

      get progress_import_batch_path(import_batch), headers: turbo_stream_accept

      expect(response.body).not_to include(%(data-controller="poll"))
      expect(response.body).to include(%(action="update" target="flash_messages"))
      expect(response.body).to include("Importação concluída: 3 linhas importadas.")
    end

    it "shows an alert when the import finishes with row errors" do
      import_batch = create(:import_batch, organization: organization, user: user, status: :completed,
                                           total_rows: 3, processed_rows: 3, successful_rows: 2, failed_rows: 1)

      get progress_import_batch_path(import_batch), headers: turbo_stream_accept

      expect(response.body).to include("Importação concluída: 2 linhas importadas, 1 com erro.")
      expect(response.body).to include("text-red-500")
    end

    it "shows an alert when the import fails" do
      import_batch = create(:import_batch, organization: organization, user: user, status: :failed)

      get progress_import_batch_path(import_batch), headers: turbo_stream_accept

      expect(response.body).to include("A importação falhou. Veja os erros abaixo.")
    end

    it "does not expose progress from another organization" do
      import_batch = create(:import_batch, organization: create(:organization), user: create(:user))

      get progress_import_batch_path(import_batch), headers: turbo_stream_accept

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /import_batches" do
    it "creates an import batch with the attached file" do
      allow(SalesImportJob).to receive(:perform_later)

      expect {
        post import_batches_path, params: {
          import_batch: {
            file: uploaded_xlsx,
            year: 2026
          }
        }
      }.to change(ImportBatch, :count).by(1)

      import_batch = ImportBatch.last
      expect(import_batch.organization).to eq(organization)
      expect(import_batch.user).to eq(user)
      expect(import_batch.file).to be_attached
      expect(import_batch.year).to eq(2026)
    end

    it "enqueues the sales import job" do
      allow(SalesImportJob).to receive(:perform_later)

      post import_batches_path, params: {
        import_batch: {
          file: uploaded_xlsx,
          year: 2026
        }
      }

      expect(SalesImportJob).to have_received(:perform_later).with(ImportBatch.last)
      expect(response).to redirect_to(import_batch_path(ImportBatch.last))
    end

    it "lands on the import page when submitted by Turbo" do
      allow(SalesImportJob).to receive(:perform_later)
      turbo_accept = "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"

      post import_batches_path,
           params: { import_batch: { file: uploaded_xlsx, year: 2026 } },
           headers: { "Accept" => turbo_accept }
      follow_redirect!(headers: { "Accept" => turbo_accept })

      expect(response.media_type).to eq("text/html")
      expect(response.body).to include("Importação ##{ImportBatch.last.id}")
      expect(response.body).to include("Importação iniciada.")
    end

    it "renders the form again when invalid" do
      expect {
        post import_batches_path, params: {
          import_batch: {
            year: nil
          }
        }
      }.not_to change(ImportBatch, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Não foi possível iniciar a importação")
    end
  end

  describe "POST /import_batches with unsafe input" do
    it "rejects non XLSX uploads" do
      tempfile = Tempfile.new([ "evil", ".html" ])
      tempfile.write("<script>alert(1)</script>")
      tempfile.rewind

      expect {
        post import_batches_path, params: {
          import_batch: { file: Rack::Test::UploadedFile.new(tempfile.path, "text/html"), year: 2026 }
        }
      }.not_to change(ImportBatch, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns bad request when params are missing" do
      post import_batches_path, params: {}

      expect(response).to have_http_status(:bad_request)
    end
  end

  context "when membership is viewer" do
    let(:role) { "viewer" }

    it "can list imports" do
      get import_batches_path

      expect(response).to have_http_status(:success)
    end

    it "can follow import progress" do
      import_batch = create(:import_batch, organization: organization, user: create(:user), status: :processing)

      get progress_import_batch_path(import_batch), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
    end

    it "cannot open the new import form" do
      get new_import_batch_path

      expect(response).to redirect_to(root_path)
    end

    it "cannot create imports" do
      expect {
        post import_batches_path, params: {
          import_batch: {
            file: uploaded_xlsx,
            year: 2026
          }
        }
      }.not_to change(ImportBatch, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
