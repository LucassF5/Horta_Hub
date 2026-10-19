# frozen_string_literal: true

class Components::FlashMessages < Components::Base
  def initialize(messages:)
    @messages = messages
  end

  def view_template
    return unless @messages.any?

    div(class: "mb-4") do
      @messages.each do |type, message|
        css = if type.to_s == "alert"
          "py-2 px-3 bg-red-50 mb-2 text-red-500 font-medium rounded-lg inline-block"
        else
          "py-2 px-3 bg-green-50 mb-2 text-green-500 font-medium rounded-lg inline-block"
        end
        p(class: css, id: type) { message }
      end
    end
  end
end
