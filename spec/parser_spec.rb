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

    context "when parsing a heading" do
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

    context "when parsing a paragraph" do
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

    context "when parsing a code block" do
      it "converts Token::CodeBlock to Node::CodeBlock" do
        tokens = lex("```ruby\nputs 'hi'\n```\n")
        node = parse(tokens).children.first
        expect(node).to be_a(Mactor::Node::CodeBlock)
        expect(node).to have_attributes(language: "ruby", content: "puts 'hi'")
      end
    end

    context "when parsing a thematic break" do
      it "converts Token::ThematicBreak to Node::ThematicBreak" do
        tokens = lex("---")
        expect(parse(tokens).children.first).to be_a(Mactor::Node::ThematicBreak)
      end
    end

    context "when parsing a blockquote" do
      it "converts Token::Blockquote to Node::Blockquote" do
        tokens = lex("> quoted")
        node = parse(tokens).children.first
        expect(node).to be_a(Mactor::Node::Blockquote)
        expect(node.children.first).to eq(Mactor::Node::Text.new(content: "quoted"))
      end
    end

    context "when parsing a list" do
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

      it "sets checked: nil for a plain list item" do
        tokens = lex("- plain\n")
        item = parse(tokens).children.first.children.first
        expect(item.checked).to be_nil
      end
    end

    context "when parsing a task list" do
      it "sets checked: false for an unchecked task item" do
        tokens = lex("- [ ] unchecked\n")
        item = parse(tokens).children.first.children.first
        expect(item.checked).to be false
      end

      it "sets checked: true for a checked task item with [x]" do
        tokens = lex("- [x] checked\n")
        item = parse(tokens).children.first.children.first
        expect(item.checked).to be true
      end

      it "sets checked: true for a checked task item with [X]" do
        tokens = lex("- [X] checked\n")
        item = parse(tokens).children.first.children.first
        expect(item.checked).to be true
      end

      it "strips the [ ] prefix from the inline content" do
        tokens = lex("- [ ] todo item\n")
        item = parse(tokens).children.first.children.first
        expect(item.children.first).to eq(Mactor::Node::Text.new(content: "todo item"))
      end

      it "mixes task and plain items in the same list" do
        tokens = lex("- [ ] task\n- plain\n")
        items = parse(tokens).children.first.children
        expect(items[0].checked).to be false
        expect(items[1].checked).to be_nil
      end
    end

    context "with inline markup nesting" do
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

    context "when parsing a table" do
      it "converts Token::Table to Node::Table" do
        tokens = lex("| H |\n| --- |\n| r1 |\n")
        node = parse(tokens).children.first
        expect(node).to be_a(Mactor::Node::Table)
      end

      it "builds TableHead with header cells" do
        tokens = lex("| Name | Age |\n| --- | --- |\n")
        table = parse(tokens).children.first
        head = table.children.first
        expect(head).to be_a(Mactor::Node::TableHead)
        row = head.children.first
        expect(row).to be_a(Mactor::Node::TableRow)
        expect(row.children.length).to eq(2)
        expect(row.children).to all(be_a(Mactor::Node::TableCell))
        expect(row.children.first.header).to be true
      end

      it "builds TableBody with data cells" do
        tokens = lex("| H |\n| --- |\n| r1 |\n")
        table = parse(tokens).children.first
        body = table.children.last
        expect(body).to be_a(Mactor::Node::TableBody)
        expect(body.children.first).to be_a(Mactor::Node::TableRow)
        expect(body.children.first.children.first.header).to be false
      end

      it "assigns alignment to cells" do
        tokens = lex("| H |\n| :---: |\n| r |\n")
        table = parse(tokens).children.first
        header_cell = table.children.first.children.first.children.first
        data_cell = table.children.last.children.first.children.first
        expect(header_cell.align).to eq(:center)
        expect(data_cell.align).to eq(:center)
      end

      it "parses inline content in cells" do
        tokens = lex("| **bold** |\n| --- |\n")
        table = parse(tokens).children.first
        cell = table.children.first.children.first.children.first
        expect(cell.children.first).to be_a(Mactor::Node::Strong)
      end
    end

    context "with multiple tokens" do
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
