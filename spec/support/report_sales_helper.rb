module ReportSalesHelper
  def create_report_sale(organization:, date:, items:, status: "completed", seller: nil, responsible_name: nil)
    client = organization.clients.first || create(:client, organization: organization)
    create(:sale, organization: organization, client: client, status: status, sale_date: date,
      seller: seller, responsible_name: responsible_name,
      sale_items_attributes: items.map { |product, quantity, unit_price|
        { product_id: product.id, quantity: quantity, unit_price: unit_price, custom_price: true }
      })
  end
end

RSpec.configure { |config| config.include ReportSalesHelper }
