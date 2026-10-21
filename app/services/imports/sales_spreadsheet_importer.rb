# frozen_string_literal: true

module Imports
  class SalesSpreadsheetImporter
    # Erro esperado de importação; a mensagem é exibida ao usuário.
    class Error < StandardError; end
    class RowError < Error; end

    MAX_ROWS = 5_000

    REQUIRED_HEADERS = [
      "DIA",
      "DATA",
      "CLIENTE",
      "PRODUTO",
      "QTD",
      "VALOR",
      "RESPONSAVEL",
      "STATUS",
      "OBSERVACAO"
    ].freeze

    STATUS_MAP = {
      "PG" => "completed",
      "PAGO" => "completed",
      "PENDENTE" => "pending",
      "CANCELADO" => "cancelled"
    }.freeze

    MONTHS = {
      "JAN" => 1, "FEV" => 2, "MAR" => 3, "ABR" => 4, "MAI" => 5, "JUN" => 6,
      "JUL" => 7, "AGO" => 8, "SET" => 9, "OUT" => 10, "NOV" => 11, "DEZ" => 12
    }.freeze

    DATE_FORMAT = %r{\A(\d{1,2})[/-](\d{1,2}|[A-Z]{3,})(?:[/-](\d{2}|\d{4}))?\z}

    def initialize(import_batch:, spreadsheet:)
      @import_batch = import_batch
      @spreadsheet = spreadsheet.sheet(0)
      @organization = import_batch.organization
    end

    def call
      validate_headers!

      row_numbers = data_row_numbers
      raise Error, "A planilha tem #{row_numbers.size} linhas; o limite é #{MAX_ROWS}." if row_numbers.size > MAX_ROWS

      import_batch.update!(total_rows: row_numbers.size)

      grouped_rows(parsed_rows(row_numbers)).each_value { |sale_rows| import_sale(sale_rows) }
    end

    private

    attr_reader :import_batch, :spreadsheet, :organization

    def validate_headers!
      missing_headers = REQUIRED_HEADERS - headers
      return if missing_headers.empty?

      raise Error, "Cabeçalhos ausentes: #{missing_headers.join(', ')}"
    end

    # Linhas com erro nos campos da venda não podem ser agrupadas e são
    # descartadas aqui. Erros nos campos do item ficam na linha para invalidar
    # a venda inteira em #import_sale.
    def parsed_rows(row_numbers)
      row_numbers.filter_map do |row_number|
        parse_row(row_number)
      rescue RowError => error
        register_row_error(row_number, error.message)
        nil
      end
    end

    def data_row_numbers
      (2..spreadsheet.last_row.to_i).reject { |row_number| blank_row?(row_number) }
    end

    def parse_row(row_number)
      row = {
        row_number: row_number,
        sale_date: parse_date(cell(row_number, "DATA")),
        client_name: required_name(cell(row_number, "CLIENTE"), "Cliente"),
        responsible_name: normalize_name(cell(row_number, "RESPONSAVEL")).presence,
        status: parse_status(cell(row_number, "STATUS")),
        notes: cell(row_number, "OBSERVACAO").to_s.strip.presence
      }

      row.merge(parse_item(row_number))
    end

    def parse_item(row_number)
      quantity = parse_quantity(cell(row_number, "QTD"))
      total_value = parse_money(cell(row_number, "VALOR"))

      {
        product_name: required_name(cell(row_number, "PRODUTO"), "Produto"),
        quantity: quantity,
        unit_price: (total_value / quantity).round(2)
      }
    rescue RowError => error
      { error: error.message }
    end

    def grouped_rows(rows)
      rows.group_by do |row|
        [
          row[:sale_date],
          row[:client_name],
          row[:responsible_name],
          row[:status],
          row[:notes]
        ]
      end
    end

    def import_sale(rows)
      return reject_sale(rows) if rows.any? { |row| row[:error] }

      ActiveRecord::Base.transaction do
        first_row = rows.first
        sale = organization.sales.build(
          client: find_or_create_client(first_row[:client_name]),
          sale_date: first_row[:sale_date],
          status: first_row[:status],
          seller: organization.member_named(first_row[:responsible_name]),
          responsible_name: first_row[:responsible_name],
          notes: first_row[:notes]
        )

        rows.each do |row|
          product = find_or_create_product(row[:product_name], row[:unit_price])

          sale.sale_items.build(
            product: product,
            quantity: row[:quantity],
            unit_price: row[:unit_price],
            custom_price: row[:unit_price] != product.price
          )
        end

        sale.save!
      end

      import_batch.increment!(:processed_rows, rows.size)
      import_batch.increment!(:successful_rows, rows.size)
    rescue RowError, ActiveRecord::RecordInvalid => error
      forget_rolled_back_records
      message = error.is_a?(RowError) ? error.message : "Venda inválida: #{error.record.errors.full_messages.to_sentence}"
      rows.each { |row| register_row_error(row[:row_number], message) }
    end

    def reject_sale(rows)
      invalid_row_numbers = rows.select { |row| row[:error] }.map { |row| row[:row_number] }

      rows.each do |row|
        message = row[:error] ||
          "Venda não importada: a(s) linha(s) #{invalid_row_numbers.join(', ')} da mesma venda contém erros"
        register_row_error(row[:row_number], message)
      end
    end

    def find_or_create_client(name)
      clients_by_name[name] ||= organization.clients.create!(name: name, client_type: :pessoa_juridica)
    rescue ActiveRecord::RecordInvalid => error
      raise RowError, "Cliente \"#{name}\": #{error.record.errors.full_messages.to_sentence}"
    end

    def find_or_create_product(name, unit_price)
      products_by_name[name] ||= organization.products.create!(name: name, price: unit_price)
    rescue ActiveRecord::RecordInvalid => error
      raise RowError, "Produto \"#{name}\": #{error.record.errors.full_messages.to_sentence}"
    end

    def clients_by_name
      @clients_by_name ||= organization.clients.index_by { |client| normalize_name(client.name) }
    end

    def products_by_name
      @products_by_name ||= organization.products.index_by { |product| normalize_name(product.name) }
    end

    # Registros criados numa transação desfeita voltam a ser new_record? e
    # não podem ser reaproveitados nem continuar nas associações em memória,
    # senão um save posterior da organização os recriaria.
    def forget_rolled_back_records
      clients_by_name.reject! { |_name, client| client.new_record? }
      products_by_name.reject! { |_name, product| product.new_record? }
      organization.clients.reset
      organization.products.reset
      organization.sales.reset
    end

    def parse_date(value)
      return value.to_date if value.is_a?(Date) || value.is_a?(Time)

      match = DATE_FORMAT.match(normalize_text(value))
      raise RowError, "Data inválida: #{value}. Use dd/mm/aaaa, dd/mm ou dd/mês (ex.: 02/out)." unless match

      day, month, year = match.captures
      month = month.match?(/\A\d+\z/) ? month.to_i : MONTHS.fetch(month[0, 3]) { raise RowError, "Data inválida: #{value}" }
      year = year ? year.to_i : import_batch.year
      year += 2000 if year < 100

      Date.new(year, month, day.to_i)
    rescue Date::Error
      raise RowError, "Data inválida: #{value}"
    end

    def parse_quantity(value)
      quantity = value.is_a?(Numeric) ? value : Integer(value.to_s.strip, 10)
      raise RowError, "Quantidade deve ser um número inteiro: #{value}" unless quantity == quantity.to_i
      raise RowError, "Quantidade deve ser maior que zero" unless quantity.positive?

      quantity.to_i
    rescue ArgumentError
      raise RowError, "Quantidade inválida: #{value}"
    end

    def parse_money(value)
      money = value.is_a?(Numeric) ? value.to_d : parse_money_text(value)
      raise RowError, "Valor deve ser maior que zero" unless money.positive?

      money
    end

    # Aceita formato brasileiro (1.234,56) e decimal com ponto (60.50).
    # Ponto seguido de 3 dígitos é separador de milhar.
    def parse_money_text(value)
      normalized = value.to_s.gsub("R$", "").gsub(/[[:space:]]/, "")

      case normalized
      when /\A\d{1,3}(\.\d{3})*(,\d{1,2})?\z/, /\A\d+(,\d{1,2})?\z/
        BigDecimal(normalized.delete(".").tr(",", "."))
      when /\A\d+\.\d{1,2}\z/
        BigDecimal(normalized)
      else
        raise RowError, "Valor inválido: #{value}"
      end
    end

    def parse_status(value)
      STATUS_MAP.fetch(normalize_text(value)) { raise RowError, "Status inválido: #{value}" }
    end

    def required_name(value, field)
      normalize_name(value).presence || raise(RowError, "#{field} não informado")
    end

    def register_row_error(row_number, message)
      import_batch.increment!(:processed_rows)
      import_batch.increment!(:failed_rows)
      import_batch.add_error_detail(row: row_number, message: message)
    end

    def blank_row?(row_number)
      REQUIRED_HEADERS.all? { |header| cell(row_number, header).blank? }
    end

    def cell(row_number, header)
      spreadsheet.cell(row_number, header_columns.fetch(header))
    end

    def headers
      @headers ||= spreadsheet.row(1).map { |value| normalize_text(value) }
    end

    def header_columns
      @header_columns ||= headers.each_with_index.to_h { |header, index| [ header, index + 1 ] }
    end

    def normalize_name(value)
      value.to_s.strip.squeeze(" ").upcase
    end

    def normalize_text(value)
      I18n.transliterate(value.to_s).strip.squeeze(" ").upcase
    end
  end
end
