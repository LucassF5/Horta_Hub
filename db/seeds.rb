# This file should ensure the existence of records required to run the application in every environment.
# The code here is idempotent so it can be executed repeatedly without creating duplicate seed records.

organization = Organization.find_or_create_by!(slug: "horta-hub-demo") do |org|
  org.name = "Horta Hub Demo"
  org.status = "active"
end

organization.update!(name: "Horta Hub Demo", status: "active")

user = User.find_or_initialize_by(email_address: "admin@hortahub.test")
user.assign_attributes(
  username: "admin",
  password: "password123",
  password_confirmation: "password123"
)
user.save!

Membership.find_or_create_by!(user: user, organization: organization) do |membership|
  membership.role = "owner"
end

products_data = [
  [ "Alface Crespa", 4.50 ],
  [ "Coentro", 2.50 ],
  [ "Cebolinha", 2.75 ],
  [ "Rucula", 5.00 ],
  [ "Tomate Cereja", 9.90 ],
  [ "Pimentao Verde", 6.50 ],
  [ "Manjericao", 3.75 ],
  [ "Hortela", 3.50 ],
  [ "Couve Manteiga", 4.25 ],
  [ "Quiabo", 7.20 ]
]

products = products_data.to_h do |name, price|
  product = Product.find_or_initialize_by(organization: organization, name: name)
  product.price = price
  product.save!

  [ name, product ]
end

clients_data = [
  [ "Ana Souza", "pessoa_fisica", "(85) 98888-1001" ],
  [ "Bruno Lima", "pessoa_fisica", "(85) 98888-1002" ],
  [ "Clara Martins", "pessoa_fisica", "(85) 98888-1003" ],
  [ "Restaurante Sabor Verde", "pessoa_juridica", "(85) 3777-2001" ],
  [ "Mercadinho Bom Preco", "pessoa_juridica", "(85) 3777-2002" ],
  [ "Cafe Jardim", "pessoa_juridica", "(85) 3777-2003" ]
]

clients = clients_data.to_h do |name, client_type, phone|
  client = Client.find_or_initialize_by(organization: organization, name: name)
  client.client_type = client_type
  client.phone = phone
  client.save!

  [ name, client ]
end

sales_data = [
  {
    seed_code: "SEED-001",
    client: "Ana Souza",
    sale_date: Date.current - 6.days,
    status: "completed",
    notes: "Entrega semanal residencial",
    items: [
      [ "Alface Crespa", 2 ],
      [ "Coentro", 1 ],
      [ "Cebolinha", 1 ]
    ]
  },
  {
    seed_code: "SEED-002",
    client: "Restaurante Sabor Verde",
    sale_date: Date.current - 5.days,
    status: "completed",
    notes: "Reposicao para saladas do dia",
    items: [
      [ "Rucula", 6 ],
      [ "Tomate Cereja", 4 ],
      [ "Manjericao", 3 ]
    ]
  },
  {
    seed_code: "SEED-003",
    client: "Bruno Lima",
    sale_date: Date.current - 3.days,
    status: "pending",
    notes: "Retirada combinada no fim da tarde",
    items: [
      [ "Couve Manteiga", 2 ],
      [ "Hortela", 1 ]
    ]
  },
  {
    seed_code: "SEED-004",
    client: "Mercadinho Bom Preco",
    sale_date: Date.current - 2.days,
    status: "completed",
    notes: "Pedido para expositor de hortifruti",
    items: [
      [ "Alface Crespa", 10 ],
      [ "Pimentao Verde", 5 ],
      [ "Quiabo", 4 ]
    ]
  },
  {
    seed_code: "SEED-005",
    client: "Cafe Jardim",
    sale_date: Date.current - 1.day,
    status: "cancelled",
    notes: "Cancelado por reagendamento do cliente",
    items: [
      [ "Hortela", 4 ],
      [ "Manjericao", 2 ]
    ]
  },
  {
    seed_code: "SEED-006",
    client: "Clara Martins",
    sale_date: Date.current,
    status: "pending",
    notes: "Separar produtos mais frescos para entrega",
    items: [
      [ "Tomate Cereja", 1 ],
      [ "Rucula", 1 ],
      [ "Cebolinha", 2 ]
    ]
  }
]

sales_data.each do |sale_data|
  seed_note = "[#{sale_data[:seed_code]}] #{sale_data[:notes]}"
  sale = Sale.find_or_initialize_by(
    organization: organization,
    notes: seed_note
  )

  sale.client = clients.fetch(sale_data[:client])
  sale.sale_date = sale_data[:sale_date]
  sale.status = sale_data[:status]
  sale.sale_items.destroy_all if sale.persisted?

  sale_data[:items].each do |product_name, quantity|
    product = products.fetch(product_name)
    sale.sale_items.build(
      product: product,
      quantity: quantity,
      unit_price: product.price
    )
  end

  sale.save!
end

puts "Seed concluido:"
puts "- Organizacao: #{organization.name}"
puts "- Usuario: #{user.email_address} / password123"
puts "- Produtos: #{organization.products.count}"
puts "- Clientes: #{organization.clients.count}"
puts "- Vendas: #{organization.sales.count}"
