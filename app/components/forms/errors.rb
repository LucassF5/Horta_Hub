# frozen_string_literal: true

class Components::Forms::Errors < Components::Base
  # subject: o que será salvo, já com artigo ("o produto", "a venda").
  def initialize(record:, subject:)
    @record = record
    @subject = subject
  end

  def view_template
    return if @record.errors.empty?

    render RubyUI::Alert.new(variant: :destructive, class: "mb-6") do
      div do
        h2(class: "mb-2 font-bold") { "Corrija #{pluralize(@record.errors.count, "erro", plural: "erros")} para salvar #{@subject}:" }
        ul(class: "list-inside list-disc") do
          @record.errors.full_messages.each { |message| li { message } }
        end
      end
    end
  end
end
