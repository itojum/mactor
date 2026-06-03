# frozen_string_literal: true

module Mactor
  module Node
    class << self
      private

      def define_node(*plain_attrs, **attr_specs)
        all_specs = plain_attrs.to_h { |a| [a, {}.freeze] }
                               .merge(attr_specs.transform_values(&:freeze))
                               .freeze

        Data.define(*all_specs.keys) do
          const_set(:ATTR_SPECS, all_specs)

          def initialize(**kwargs)
            self.class::ATTR_SPECS.each do |attr, opts|
              kwargs[attr] = nil unless kwargs.key?(attr)
              raise ArgumentError, "#{attr} cannot be nil" if !opts.fetch(:nil, false) && kwargs[attr].nil?
            end
            super
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
    ThematicBreak = define_node
    Table = define_node(:children)
    TableHead = define_node(:children)
    TableBody = define_node(:children)
    TableRow = define_node(:children)
    TableCell = define_node(:children, align: { nil: true }, header: { nil: true })

    Text = define_node(:content)
    Strong = define_node(:children)
    Emphasis = define_node(:children)
    InlineCode = define_node(:content)
    Link = define_node(:href, :children, title: { nil: true })
    Image = define_node(:src, :alt, title: { nil: true })
  end
end
