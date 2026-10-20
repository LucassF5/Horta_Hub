# frozen_string_literal: true

class Views::Memberships::New < Views::Base
  def initialize(creation:)
    @creation = creation
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-2xl") do
        render Components::PageHeader.new(
          title: "Novo funcionário",
          description: "Dê acesso à organização. Uma senha será gerada e mostrada uma única vez.",
          back: [ "Voltar para funcionários", memberships_path ]
        )
        render Components::Forms::Errors.new(record: @creation, subject: "o funcionário")
        render Views::Memberships::FormComponent.new(creation: @creation, url: memberships_path, cancel_href: memberships_path)
      end
    end
  end
end
