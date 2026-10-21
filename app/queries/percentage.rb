# frozen_string_literal: true

module Percentage
  def self.change(current, previous)
    return if previous.nil? || previous.zero?

    ((current.to_d - previous.to_d) / previous.to_d * 100).round(1)
  end

  def self.share(part, whole)
    return if whole.nil? || whole.zero?

    (part.to_d / whole.to_d * 100).round(1)
  end
end
