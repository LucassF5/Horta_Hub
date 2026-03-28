# frozen_string_literal: true

class Views::Home::Index < Views::Base
  def view_template
    div do
        h1(class: "font-bold text-4xl") { "Home::Index" }
        p { "Find me in app/views/home/index.rb" }
    end
  end
end
