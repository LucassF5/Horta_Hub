# frozen_string_literal: true

class Views::Clients::Edit < Views::Base
  def initialize(client:)
    @client = client
  end

  def view_template
    div(class: "mx-auto bg-background flex flex-col justify-center items-center") do
      div(class: "container mx-auto px-4 py-8") do
        h1(class: "text-3xl font-bold text-gray-800 mb-8") { "Editar cliente" }

        render_errors if @client.errors.any?
      end

      render Views::Clients::FormComponent.new(
        client: @client,
        url: client_path(@client)
      )
    end
  end

  private

  def render_errors
    render RubyUI::Alert.new(variant: :destructive) do
      div do
        h2(class: "font-bold mb-2") do
          "#{pluralize(@client.errors.count, 'erro')} impediram o cliente de ser salvo:"
        end
        ul(class: "list-disc list-inside") do
          @client.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end
end
