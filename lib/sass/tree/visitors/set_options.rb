# A visitor for setting options on the Sass tree
class Sass::Tree::Visitors::SetOptions < Sass::Tree::Visitors::Base
  # @param root [Tree::Node] The root node of the tree to visit.
  # @param options [{Symbol => Object}] The options has to set.
  def self.visit(root, options); new(options).send(:visit, root); end

  protected

  def initialize(options)
    @options = options
  end

  def visit(node)
    node.set_options(@options)
    super
  end

  def visit_debug(node)
    node.expr.set_options(@options)
    yield
  end

  def visit_each(node)
    node.list.set_options(@options)
    yield
  end

  def visit_extend(node)
    node.selector.each {|c| c.set_options(@options) if c.is_a?(Sass::Script::Node)}
    yield
  end

  def visit_for(node)
    node.from.set_options(@options)
    node.to.set_options(@options)
    yield
  end

  def visit_function(node)
    node.args.each do |k, v|
      k.set_options(@options)
      v.set_options(@options) if v
    end
    yield
  end

  def visit_if(node)
    node.expr.set_options(@options) if node.expr
    visit(node.else) if node.else
    yield
  end

  def visit_mixin_def(node)
    node.args.each do |k, v|
      k.set_options(@options)
      v.set_options(@options) if v
    end
    yield
  end

  def visit_mixin(node)
    node.args.each {|a| a.set_options(@options)}
    node.keywords.each {|k, v| v.set_options(@options)}
    yield
  end

  def visit_prop(node)
    node.name.each {|c| c.set_options(@options) if c.is_a?(Sass::Script::Node)}
    node.value.set_options(@options)
    yield
  end

  def visit_return(node)
    node.expr.set_options(@options)
    yield
  end

  def visit_rule(node)
    node.rule.each {|c| c.set_options(@options) if c.is_a?(Sass::Script::Node)}
    yield
  end

  def visit_variable(node)
    node.expr.set_options(@options)
    yield
  end

  def visit_warn(node)
    node.expr.set_options(@options)
    yield
  end

  def visit_while(node)
    node.expr.set_options(@options)
    yield
  end
end
