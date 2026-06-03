# frozen_string_literal: true

require "spec_helper"
require "mactor/renderer/base"

RSpec.describe Mactor::Renderer::Base do
  subject(:renderer) { described_class.new }

  let(:subclass) do
    Class.new(described_class) do
      def render_document(_node) = "document"
      def render_heading(node) = "heading:#{node.level}"
      def render_paragraph(_node)      = "paragraph"
      def render_code_block(_node)     = "code_block"
      def render_list(_node)           = "list"
      def render_list_item(_node)      = "list_item"
      def render_blockquote(_node)     = "blockquote"
      def render_thematic_break(_node) = "thematic_break"
      def render_text(_node)           = "text"
      def render_strong(_node)         = "strong"
      def render_emphasis(_node)       = "emphasis"
      def render_inline_code(_node)    = "inline_code"
      def render_link(_node)           = "link"
      def render_image(_node)          = "image"
    end
  end

  let(:sub) { subclass.new }

  describe "#initialize" do
    it "accepts a config hash and freezes it" do
      r = described_class.new(foo: "bar")
      expect(r.instance_variable_get(:@config)).to be_frozen
    end

    it "defaults config to a frozen empty hash" do
      expect(renderer.instance_variable_get(:@config)).to eq({}).and(be_frozen)
    end
  end

  describe "#render dispatch" do
    it "dispatches Node::Document to render_document" do
      expect(sub.render(Mactor::Node::Document.new(children: []))).to eq("document")
    end

    it "dispatches Node::Heading to render_heading" do
      expect(sub.render(Mactor::Node::Heading.new(level: 2, children: []))).to eq("heading:2")
    end

    it "dispatches Node::Paragraph to render_paragraph" do
      expect(sub.render(Mactor::Node::Paragraph.new(children: []))).to eq("paragraph")
    end

    it "dispatches Node::CodeBlock to render_code_block" do
      expect(sub.render(Mactor::Node::CodeBlock.new(content: "x"))).to eq("code_block")
    end

    it "dispatches Node::List to render_list" do
      expect(sub.render(Mactor::Node::List.new(ordered: false, children: []))).to eq("list")
    end

    it "dispatches Node::ListItem to render_list_item" do
      expect(sub.render(Mactor::Node::ListItem.new(children: []))).to eq("list_item")
    end

    it "dispatches Node::Blockquote to render_blockquote" do
      expect(sub.render(Mactor::Node::Blockquote.new(children: []))).to eq("blockquote")
    end

    it "dispatches Node::ThematicBreak to render_thematic_break" do
      expect(sub.render(Mactor::Node::ThematicBreak.new)).to eq("thematic_break")
    end

    it "dispatches Node::Text to render_text" do
      expect(sub.render(Mactor::Node::Text.new(content: "hi"))).to eq("text")
    end

    it "dispatches Node::Strong to render_strong" do
      expect(sub.render(Mactor::Node::Strong.new(children: []))).to eq("strong")
    end

    it "dispatches Node::Emphasis to render_emphasis" do
      expect(sub.render(Mactor::Node::Emphasis.new(children: []))).to eq("emphasis")
    end

    it "dispatches Node::InlineCode to render_inline_code" do
      expect(sub.render(Mactor::Node::InlineCode.new(content: "x"))).to eq("inline_code")
    end

    it "dispatches Node::Link to render_link" do
      expect(sub.render(Mactor::Node::Link.new(href: "/", children: []))).to eq("link")
    end

    it "dispatches Node::Image to render_image" do
      expect(sub.render(Mactor::Node::Image.new(src: "/", alt: "x"))).to eq("image")
    end
  end

  describe "default render_* methods" do
    it "raises NotImplementedError with the class and method name" do
      node = Mactor::Node::Heading.new(level: 1, children: [])
      expect { renderer.render(node) }
        .to raise_error(NotImplementedError, /render_heading/)
    end

    it "includes the subclass name in the error message" do
      named = Class.new(described_class)
      stub_const("MyRenderer", named)
      node = Mactor::Node::Paragraph.new(children: [])
      expect { MyRenderer.new.render(node) }
        .to raise_error(NotImplementedError, /MyRenderer/)
    end
  end
end
