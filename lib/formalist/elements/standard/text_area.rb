require "formalist/element"
require "formalist/elements"
require "formalist/types"

module Formalist
  class Elements
    class TextArea < Element
      attribute :box_size, Types::Int
    end

    register :text_area, TextArea
  end
end