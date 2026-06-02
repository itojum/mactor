module Mactor
  module Node
    class << self
      private

      def define_node(*plain_attrs, **attr_specs)
        all_specs = plain_attrs.each_with_object({}) { |a, h| h[a] = {} }.merge(attr_specs)

        Data.define(*all_specs.keys) do
          define_method(:initialize) do |**kwargs|
            all_specs.each do |attr, opts|
              kwargs[attr] = nil unless kwargs.key?(attr)
              raise ArgumentError, "#{attr} cannot be nil" if !opts.fetch(:nil, false) && kwargs[attr].nil?
            end
            super(**kwargs)
          end
        end
      end
    end

    Document = define_node(:children)
    Heading = define_node(:level, :children)
    Paragraph = define_node(:children)
    CodeBlock = define_node(:content, language: { nil: true })
    List = define_node(:ordered, :children)
    ListItem = define_node(:children)
    Blockquote = define_node(:children)
    ThematicBreak = define_node()

    Text = define_node(:content)
    Strong = define_node(:children)
    Emphasis = define_node(:children)
    InlineCode = define_node(:content)
    Link = define_node(:href, :children, title: { nil: true })
    Image = define_node(:src, :alt, title: { nil: true })
  end
end
