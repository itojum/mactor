# frozen_string_literal: true

require "spec_helper"
require "mactor/renderer/html"

RSpec.describe Mactor::Renderer::Html do
  subject(:renderer) { described_class.new }

  def text(content)
    Mactor::Node::Text.new(content: content)
  end

  def render(node)
    renderer.render(node)
  end

  describe "Node::Document" do
    it "concatenates children" do
      doc = Mactor::Node::Document.new(children: [
        Mactor::Node::Paragraph.new(children: [text("foo")]),
        Mactor::Node::Paragraph.new(children: [text("bar")])
      ])
      expect(render(doc)).to eq("<p>foo</p>\n<p>bar</p>\n")
    end

    it "returns empty string for a document with no children" do
      expect(render(Mactor::Node::Document.new(children: []))).to eq("")
    end
  end

  describe "Node::Heading" do
    it "renders h1" do
      node = Mactor::Node::Heading.new(level: 1, children: [text("Hello")])
      expect(render(node)).to eq("<h1>Hello</h1>\n")
    end

    it "renders h6" do
      node = Mactor::Node::Heading.new(level: 6, children: [text("Deep")])
      expect(render(node)).to eq("<h6>Deep</h6>\n")
    end
  end

  describe "Node::Paragraph" do
    it "renders <p>" do
      node = Mactor::Node::Paragraph.new(children: [text("Hello world")])
      expect(render(node)).to eq("<p>Hello world</p>\n")
    end
  end

  describe "Node::CodeBlock" do
    it "renders <pre><code> with a language class" do
      node = Mactor::Node::CodeBlock.new(language: "ruby", content: "puts 'hi'")
      expect(render(node)).to eq("<pre><code class=\"language-ruby\">puts 'hi'</code></pre>\n")
    end

    it "renders <pre><code> without a class when language is nil" do
      node = Mactor::Node::CodeBlock.new(content: "code")
      expect(render(node)).to eq("<pre><code>code</code></pre>\n")
    end

    it "escapes HTML in the content" do
      node = Mactor::Node::CodeBlock.new(content: "<script>")
      expect(render(node)).to eq("<pre><code>&lt;script&gt;</code></pre>\n")
    end
  end

  describe "Node::List" do
    it "renders <ul> for unordered list" do
      node = Mactor::Node::List.new(ordered: false, children: [
        Mactor::Node::ListItem.new(children: [text("foo")]),
        Mactor::Node::ListItem.new(children: [text("bar")])
      ])
      expect(render(node)).to eq("<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>\n")
    end

    it "renders <ol> for ordered list" do
      node = Mactor::Node::List.new(ordered: true, children: [
        Mactor::Node::ListItem.new(children: [text("one")])
      ])
      expect(render(node)).to eq("<ol>\n<li>one</li>\n</ol>\n")
    end
  end

  describe "Node::Blockquote" do
    it "renders <blockquote>" do
      node = Mactor::Node::Blockquote.new(children: [text("quoted")])
      expect(render(node)).to eq("<blockquote>quoted</blockquote>\n")
    end
  end

  describe "Node::ThematicBreak" do
    it "renders <hr>" do
      expect(render(Mactor::Node::ThematicBreak.new)).to eq("<hr>\n")
    end
  end

  describe "Node::Strong" do
    it "renders <strong>" do
      node = Mactor::Node::Strong.new(children: [text("bold")])
      expect(render(node)).to eq("<strong>bold</strong>")
    end
  end

  describe "Node::Emphasis" do
    it "renders <em>" do
      node = Mactor::Node::Emphasis.new(children: [text("italic")])
      expect(render(node)).to eq("<em>italic</em>")
    end
  end

  describe "Node::InlineCode" do
    it "renders <code>" do
      node = Mactor::Node::InlineCode.new(content: "foo")
      expect(render(node)).to eq("<code>foo</code>")
    end

    it "escapes HTML in the content" do
      node = Mactor::Node::InlineCode.new(content: "<br>")
      expect(render(node)).to eq("<code>&lt;br&gt;</code>")
    end
  end

  describe "Node::Link" do
    it "renders <a href>" do
      node = Mactor::Node::Link.new(href: "https://example.com", children: [text("click")])
      expect(render(node)).to eq('<a href="https://example.com">click</a>')
    end

    it "escapes & in href" do
      node = Mactor::Node::Link.new(href: "/path?a=1&b=2", children: [text("link")])
      expect(render(node)).to eq('<a href="/path?a=1&amp;b=2">link</a>')
    end
  end

  describe "Node::Image" do
    it "renders <img src alt>" do
      node = Mactor::Node::Image.new(src: "/img.png", alt: "photo")
      expect(render(node)).to eq('<img src="/img.png" alt="photo">')
    end

    it "escapes HTML in alt text" do
      node = Mactor::Node::Image.new(src: "/img.png", alt: "<logo>")
      expect(render(node)).to eq('<img src="/img.png" alt="&lt;logo&gt;">')
    end
  end

  describe "HTML escaping in text" do
    it "escapes & < > in text nodes" do
      node = Mactor::Node::Paragraph.new(children: [text("a & b < c > d")])
      expect(render(node)).to eq("<p>a &amp; b &lt; c &gt; d</p>\n")
    end
  end

  describe "inline elements within block elements" do
    it "renders strong inside a paragraph" do
      node = Mactor::Node::Paragraph.new(children: [
        text("Hello "),
        Mactor::Node::Strong.new(children: [text("world")])
      ])
      expect(render(node)).to eq("<p>Hello <strong>world</strong></p>\n")
    end
  end
end
