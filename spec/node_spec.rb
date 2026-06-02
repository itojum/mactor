# frozen_string_literal: true

require 'mactor/node'

RSpec.describe Mactor::Node do
  BLOCK_NODES = [
    { klass: Mactor::Node::Document,      args: { children: [] } },
    { klass: Mactor::Node::Heading,       args: { level: 1, children: [] } },
    { klass: Mactor::Node::Paragraph,     args: { children: [] } },
    { klass: Mactor::Node::CodeBlock,     args: { language: "ruby", content: "puts 'hello'" } },
    { klass: Mactor::Node::List,          args: { ordered: false, children: [] } },
    { klass: Mactor::Node::ListItem,      args: { children: [] } },
    { klass: Mactor::Node::Blockquote,    args: { children: [] } },
    { klass: Mactor::Node::ThematicBreak, args: {} },
  ].freeze

  INLINE_NODES = [
    { klass: Mactor::Node::Text,       args: { content: "hello" } },
    { klass: Mactor::Node::Strong,     args: { children: [] } },
    { klass: Mactor::Node::Emphasis,   args: { children: [] } },
    { klass: Mactor::Node::InlineCode, args: { content: "code" } },
    { klass: Mactor::Node::Link,       args: { href: "https://example.com", title: "Example", children: [] } },
    { klass: Mactor::Node::Image,      args: { src: "image.png", alt: "alt text", title: "Title" } },
  ].freeze

  ALL_NODES = (BLOCK_NODES + INLINE_NODES).freeze

  describe "can be instantiated" do
    ALL_NODES.each do |entry|
      it entry[:klass].name do
        node = entry[:klass].new(**entry[:args])
        expect(node).to be_a(entry[:klass])
      end
    end
  end

  describe "is immutable" do
    ALL_NODES.each do |entry|
      it entry[:klass].name do
        node = entry[:klass].new(**entry[:args])
        expect(node).to be_frozen
      end
    end
  end

  describe "attribute access" do
    ALL_NODES.each do |entry|
      it entry[:klass].name do
        node = entry[:klass].new(**entry[:args])
        entry[:args].each do |attr, value|
          expect(node.public_send(attr)).to eq(value)
        end
      end
    end
  end

  describe "nullable attributes" do
    {
      Mactor::Node::CodeBlock => { language: nil, content: "puts 'hello'" },
      Mactor::Node::Link      => { href: "https://example.com", title: nil, children: [] },
      Mactor::Node::Image     => { src: "image.png", alt: "alt text", title: nil },
    }.each do |klass, args|
      it "#{klass.name} nullable attributes" do
        node = klass.new(**args)
        nil_attrs = args.select { |_, v| v.nil? }.keys
        nil_attrs.each do |attr|
          expect(node.public_send(attr)).to be_nil
        end
      end
    end
  end

  describe "Ractor compatibility" do
    ALL_NODES.each do |entry|
      it "#{entry[:klass].name} can be passed between Ractors without freezing" do
        node = entry[:klass].new(**entry[:args])
        result = Ractor.new(node) { |n| n }.value
        expect(result).to eq(node)
      end
    end
  end
end
