require 'sass/tree/node'

module Sass::Tree
  # A dynamic node representing a Sass `@if` statement.
  #
  # {IfNode}s are a little odd, in that they also represent `@else` and `@else if`s.
  # This is done as a linked list:
  # each {IfNode} has a link (\{#else}) to the next {IfNode}.
  #
  # @see Sass::Tree
  class IfNode < Node
    # The conditional expression.
    # If this is nil, this is an `@else` node, not an `@else if`.
    #
    # @return [Script::Expr]
    attr_accessor :expr

    # The next {IfNode} in the if-else list, or `nil`.
    #
    # @return [IfNode]
    attr_accessor :else

    # @param expr [Script::Expr] See \{#expr}
    def initialize(expr)
      @expr = expr
      @last_else = self
      super()
    end

    # Append an `@else` node to the end of the list.
    #
    # @param node [IfNode] The `@else` node to append
    def add_else(node)
      @last_else.else = node
      @last_else = node
    end

    def marshal_dump
      [expr, self.else, children, options]
    end
    
    def marshal_load(values)
      @expr, @else, @children, @options = values
      @last_else = self.else.instance_variable_get('@last_else') if self.else
    end
  end
end
