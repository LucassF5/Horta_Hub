# frozen_string_literal: true

class Views::Memberships::New < Views::Base
  def initialize(creation:)
    @creation = creation
  end

  def view_template
    div(class: "mx-auto bg-background flex flex-col justify-center items-center") do
      div(class: "container mx-auto px-4 py-8") do
        h1(class: "text-3xl font-bold text-gray-800 mb-8") { "Novo funcionário" }

        render_errors if @creation.errors.any?
      end

      render Views::Memberships::FormComponent.new(
        creation: @creation,
        url: memberships_path
      )
    end
  end

  private

  def render_errors
    render RubyUI::Alert.new(variant: :destructive) do
      div do
        h2(class: "font-bold mb-2") do
          "#{pluralize(@creation.errors.count, 'erro')} impediram o funcionário de ser adicionado:"
        end
        ul(class: "list-disc list-inside") do
          @creation.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end
end
