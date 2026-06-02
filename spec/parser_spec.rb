# frozen_string_literal: true

require "spec_helper"
require "mactor/parser"
require "mactor/lexer"

RSpec.describe Mactor::Parser do
  def parse(tokens)
    described_class.new(tokens).parse
  end

  def lex(source)
    Mactor::Lexer.new(source).tokenize
  end

  describe "#parse" do
    it "returns a Node::Document" do
      expect(parse([])).to be_a(Mactor::Node::Document)
    end

    it "returns Document with empty children for an empty token list" do
      expect(parse([])).to eq(Mactor::Node::Document.new(children: []))
    end

    it "skips Blank tokens" do
      tokens = [Mactor::Token::Blank.new]
      expect(parse(tokens).children).to be_empty
    end

    context "heading" do
      it "converts Token::Heading to Node::Heading" do
        tokens = lex("# Hello")
        doc = parse(tokens)
        expect(doc.children.first).to be_a(Mactor::Node::Heading)
        expect(doc.children.first).to have_attributes(level: 1)
      end

      it "wraps the content in inline nodes" do
        tokens = lex("# Hello")
        heading = parse(tokens).children.first
        expect(heading.children.first).to eq(Mactor::Node::Text.new(content: "Hello"))
      end
    end

    context "paragraph" do
      it "converts Token::Paragraph to Node::Paragraph" do
        tokens = lex("hello world")
        doc = parse(tokens)
        expect(doc.children.first).to be_a(Mactor::Node::Paragraph)
      end

      it "converts inline markup inside the paragraph" do
        tokens = lex("**bold**")
        para = parse(tokens).children.first
        expect(para.children.first).to be_a(Mactor::Node::Strong)
      end
    end

    context "code block" do
      it "converts Token::CodeBlock to Node::CodeBlock" do
        tokens = lex("```ruby\nputs 'hi'\n```\n")
        node = parse(tokens).children.first
        expect(node).to be_a(Mactor::Node::CodeBlock)
        expect(node).to have_attributes(language: "ruby", content: "puts 'hi'")
      end
    end

    context "thematic break" do
      it "converts Token::ThematicBreak to Node::ThematicBreak" do
        tokens = lex("---")
        expect(parse(tokens).children.first).to be_a(Mactor::Node::ThematicBreak)
      end
    end

    context "blockquote" do
      it "converts Token::Blockquote to Node::Blockquote" do
        tokens = lex("> quoted")
        node = parse(tokens).children.first
        expect(node).to be_a(Mactor::Node::Blockquote)
        expect(node.children.first).to eq(Mactor::Node::Text.new(content: "quoted"))
      end
    end

    context "list" do
      it "converts Token::List (unordered) to Node::List with ListItems" do
        tokens = lex("- foo\n- bar\n")
        node = parse(tokens).children.first
        expect(node).to be_a(Mactor::Node::List)
        expect(node).to have_attributes(ordered: false)
        expect(node.children.length).to eq(2)
        expect(node.children).to all(be_a(Mactor::Node::ListItem))
      end

      it "converts Token::List (ordered) to Node::List with ordered: true" do
        tokens = lex("1. foo\n2. bar\n")
        node = parse(tokens).children.first
        expect(node).to have_attributes(ordered: true)
      end
    end

    context "inline markup nesting" do
      it "processes inline nodes inside Strong content" do
        tokens = lex("**bold *inner* more**")
        para = parse(tokens).children.first
        strong = para.children.first
        expect(strong).to be_a(Mactor::Node::Strong)
        expect(strong.children[0]).to eq(Mactor::Node::Text.new(content: "bold "))
        expect(strong.children[1]).to be_a(Mactor::Node::Emphasis)
        expect(strong.children[1].children.first).to eq(Mactor::Node::Text.new(content: "inner"))
        expect(strong.children[2]).to eq(Mactor::Node::Text.new(content: " more"))
      end

      it "processes inline nodes inside Emphasis content" do
        tokens = lex("*em `code` em*")
        para = parse(tokens).children.first
        em = para.children.first
        expect(em).to be_a(Mactor::Node::Emphasis)
        expect(em.children[0]).to eq(Mactor::Node::Text.new(content: "em "))
        expect(em.children[1]).to be_a(Mactor::Node::InlineCode)
        expect(em.children[2]).to eq(Mactor::Node::Text.new(content: " em"))
      end

      it "processes inline nodes in link text" do
        tokens = lex("[**bold** link](url)")
        para = parse(tokens).children.first
        link = para.children.first
        expect(link).to be_a(Mactor::Node::Link)
        expect(link.children.first).to be_a(Mactor::Node::Strong)
        expect(link.children.last).to eq(Mactor::Node::Text.new(content: " link"))
      end
    end

    context "multiple tokens" do
      it "builds a document with multiple children" do
        tokens = lex("# Title\n\nHello world\n")
        doc = parse(tokens)
        expect(doc.children.length).to eq(2)
        expect(doc.children[0]).to be_a(Mactor::Node::Heading)
        expect(doc.children[1]).to be_a(Mactor::Node::Paragraph)
      end
    end
  end
end
