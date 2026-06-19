# frozen_string_literal: true

class Components::Base < Phlex::HTML
  extend Phlex::Rails::HelperMacros

  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::L
  include Phlex::Rails::Helpers::NumberToCurrency
  include Phlex::Rails::Helpers::Pluralize

  register_value_helper def allowed_to?(...) = nil

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
