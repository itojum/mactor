# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mactor do
  it "has a version number" do
    expect(Mactor::VERSION).not_to be_nil
  end

  describe ".parse" do
    it "returns a Node::Document" do
      expect(described_class.parse("# Hello")).to be_a(Mactor::Node::Document)
    end

    it "returns an empty Document for an empty string" do
      expect(described_class.parse("")).to eq(Mactor::Node::Document.new(children: []))
    end

    it "parses headings and paragraphs" do
      doc = described_class.parse("# Title\n\nHello world\n")
      expect(doc.children[0]).to be_a(Mactor::Node::Heading)
      expect(doc.children[1]).to be_a(Mactor::Node::Paragraph)
    end
  end

  describe ".to_html" do
    it "returns a String" do
      expect(described_class.to_html("# Hello")).to be_a(String)
    end

    it "converts a heading to <h1>" do
      expect(described_class.to_html("# Hello")).to include("<h1>Hello</h1>")
    end

    it "converts a paragraph to <p>" do
      expect(described_class.to_html("Hello world")).to include("<p>Hello world</p>")
    end

    it "converts inline markup" do
      expect(described_class.to_html("**bold**")).to include("<strong>bold</strong>")
    end
  end

  describe ".render" do
    it "delegates to the given renderer" do
      spy = Class.new(Mactor::Renderer::Base) do
        def render_document(node) = node.children.length.to_s
        def render_heading(_node) = ""
        def render_paragraph(_node) = ""
        def render_blank(_node) = ""
      end
      expect(described_class.render("# A\n\nB\n", renderer: spy.new)).to eq("2")
    end

    it "works with the default HTML renderer" do
      result = described_class.render("---", renderer: Mactor::Renderer::Html.new)
      expect(result).to eq("<hr>\n")
    end
  end

  describe ".to_html complex document" do
    it "renders a mixed-content document end-to-end" do
      source = <<~MD
        # Title

        A paragraph with **bold** and *italic*.

        - item one
        - item two

        > A blockquote

        ```ruby
        puts 'hi'
        ```
      MD
      html = described_class.to_html(source)
      expect(html).to include("<h1>Title</h1>")
      expect(html).to include("<strong>bold</strong>")
      expect(html).to include("<em>italic</em>")
      expect(html).to include("<ul>")
      expect(html).to include("<li>item one</li>")
      expect(html).to include("<blockquote>")
      expect(html).to include("<pre><code class=\"language-ruby\">")
    end

    it "renders nested inline markup inside strong" do
      html = described_class.to_html("**bold *inner* more**")
      expect(html).to include("<strong>bold <em>inner</em> more</strong>")
    end

    it "renders inline markup inside link text" do
      html = described_class.to_html("[**bold** link](https://example.com)")
      expect(html).to include('<a href="https://example.com"><strong>bold</strong> link</a>')
    end
  end

  describe "Ractor compatibility" do
    it "can be called from within a Ractor" do
      source = "# Hello\n\n**world**\n"
      result = Ractor.new(source, described_class) { |src, klass| klass.to_html(src) }.value
      expect(result).to include("<h1>")
      expect(result).to include("<strong>world</strong>")
    end
  end
end
