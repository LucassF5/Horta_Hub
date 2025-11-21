# frozen_string_literal: true

class LinkToComponent < ViewComponent::Base
  def initialize(label:, path:, theme: nil)
    @label = label
    @path = path
    @theme = theme
  end

  private

  def button_theme
    case @theme
    when :primary
      "btn btn-primary"
    when :secondary
      "btn btn-secondary"
    when :success
      "btn btn-success"
    when :warning
      "btn btn-warning"
    when :danger
      "btn btn-danger"
    when :white
      "btn btn-white"
    else
      "hover:underline text-blue-600"
    end
  end
end
