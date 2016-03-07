require "formalist/element"
require "formalist/elements"
require "formalist/types"

module Formalist
  class Elements
    class CheckBox < Element
      attribute :question_text, Types::String
    end

    register :check_box, CheckBox
  end
end