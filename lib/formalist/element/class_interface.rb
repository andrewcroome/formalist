require "inflecto"
require "formalist/element/permitted_children"

module Formalist
  class Element
    # Class-level API for form elements.
    module ClassInterface
      # Returns the element's type, which is a symbolized, camlized
      # representation of the element's class name.
      #
      # This is a critical hook for customising form rendering when using
      # custom form elements, since the type in this case will be based on the
      # name of form element's sublass.
      #
      # @example Basic element
      #   Formalist::Elements::Field.type # => :field
      #
      # @example Custom element
      #   class MyField < Formalist::Elements::Field
      #   end
      #
      #   MyField.type # => :my_field
      #
      # @!scope class
      # @return [Symbol] the element type.
      def type
        Inflecto.underscore(Inflecto.demodulize(name)).to_sym
      end

      # Define a form element attribute.
      #
      # Form element attributes can be set when the element is defined, and
      # can be further populated by the form element object itself, when the
      # form is being built, using both the user input and any dependencies
      # passed to the element via the form.
      #
      # Attributes are the way to ensure the form renderer has all the
      # information it needs to render the element appropriately. Attributes
      # are type-checked in order to ensure they're being passed appropriate
      # values. Attributes can hold any type of value as long as it can be
      # reduced to an abstract syntax tree representation by
      # `Form::Element::Attributes#to_ast`.
      #
      # @see Formalist::Element::Attributes#to_ast
      #
      # @!scope class
      # @param name [Symbol] attribute name
      # @param type [Dry::Data::Type, #call] value type coercer/checker
      # @param default default value (applied when the attribute is not explicitly populated)
      # @return void
      def attribute(name, type, default: nil)
        attributes(name => {type: type, default: default})
      end

      # Returns the attributes schema for the form element.
      #
      # Each item in the schema includes a type definition and a default value
      # (`nil` if none specified).
      #
      # @example
      #   Formalist::Elements::Field.attributes_schema
      #   # => {
      #     :name => {:type => #<Dry::Data::Type>, :default => "Default name"},
      #     :email => {:type => #<Dry::Data::Type>, :default => "default email"}
      #   }
      #
      # @!scope class
      # @return [Hash<Symbol, Hash>] the attributes schema
      def attributes_schema
        super_schema = superclass.respond_to?(:attributes_schema) ? superclass.attributes_schema : {}
        super_schema.merge(@attributes_schema || {})
      end

      # Sets or fetches the policy for the element's permitted child form elements.
      #
      # @overload permitted_children(policy)
      #   Set a policy for whether the element permits child form elements.
      #
      #   Specify `:all` to allow all children, or `:none` to permit no
      #   children.
      #
      #   @example Permitting all children
      #     permitted_children :all
      #
      #   @example Permitting no children
      #     permitted_children :none
      #
      #   @return void
      #
      # @overload permitted_children(element_type, ...)
      #   Permit the element to contain only the specified element types as children.
      #
      #   @example
      #     permit_children :section, :field
      #
      #   @param element_type [Symbol] the name of a child element type to permit
      #   @param ... [Symbol] more child element types to permit
      #   @return void
      #
      # @overload permitted_children
      #   Returns the permitted child element types for the element.
      #
      #   If no `permitted_children` policy was previously specified, then it
      #   allows all children by default.
      #
      #   @return [#permitted?] permissions object.
      #
      #   @see Formalist::Element::PermittedChildren
      #
      # @!scope class
      def permitted_children(*args)
        return @permitted_children ||= PermittedChildren.all if args.empty?

        @permitted_children = if %i[all none].include?(args.first)
          PermittedChildren.send(args.first)
        else
          PermittedChildren[args]
        end
      end

      private

      # @!scope class
      # @api private
      def attributes(new_schema)
        prev_schema = @attributes_schema || {}
        @attributes_schema = prev_schema.merge(new_schema)

        self
      end
    end
  end
end
