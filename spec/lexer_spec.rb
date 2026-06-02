# frozen_string_literal: true

require "spec_helper"
require "mactor/lexer"

RSpec.describe Mactor::Lexer do
  subject(:tokens) { described_class.new(source).tokenize }

  describe "#tokenize" do
    context "empty string" do
      let(:source) { "" }

      it "returns an empty array" do
        expect(tokens).to eq([])
      end
    end

    context "return type" do
      let(:source) { "hello" }

      it "returns an Array" do
        expect(tokens).to be_an(Array)
      end

      it "returns an array of Token objects" do
        expect(tokens).to all(be_a(Mactor::Token))
      end

      it "returns frozen (immutable) tokens" do
        expect(tokens).to all(be_frozen)
      end
    end

    context "blank line" do
      let(:source) { "   " }

      it "emits a Blank token" do
        expect(tokens.first).to be_a(Mactor::Token::Blank)
      end
    end

    context "headings" do
      it "recognizes h1" do
        token = described_class.new("# Hello").tokenize.first
        expect(token).to be_a(Mactor::Token::Heading)
        expect(token).to have_attributes(level: 1, content: "Hello")
      end

      it "recognizes h2" do
        token = described_class.new("## World").tokenize.first
        expect(token).to have_attributes(level: 2, content: "World")
      end

      it "recognizes h3" do
        token = described_class.new("### Section").tokenize.first
        expect(token).to have_attributes(level: 3, content: "Section")
      end

      it "recognizes h4" do
        token = described_class.new("#### Sub").tokenize.first
        expect(token).to have_attributes(level: 4, content: "Sub")
      end

      it "recognizes h5" do
        token = described_class.new("##### Minor").tokenize.first
        expect(token).to have_attributes(level: 5, content: "Minor")
      end

      it "recognizes h6" do
        token = described_class.new("###### Deep").tokenize.first
        expect(token).to have_attributes(level: 6, content: "Deep")
      end

      it "falls back to Paragraph when # count exceeds 6" do
        token = described_class.new("####### Too deep").tokenize.first
        expect(token).to be_a(Mactor::Token::Paragraph)
        expect(token).to have_attributes(content: "####### Too deep")
      end

      it "does not treat # without a trailing space as a heading" do
        token = described_class.new("#notaheading").tokenize.first
        expect(token).to be_a(Mactor::Token::Paragraph)
      end
    end

    context "code block" do
      it "tokenizes a fenced code block with a language tag" do
        token = described_class.new("```ruby\nputs \"hello\"\n```\n").tokenize.first
        expect(token).to be_a(Mactor::Token::CodeBlock)
        expect(token).to have_attributes(language: "ruby", content: "puts \"hello\"")
      end

      it "tokenizes a fenced code block without a language tag" do
        token = described_class.new("```\nputs \"hello\"\n```\n").tokenize.first
        expect(token).to be_a(Mactor::Token::CodeBlock)
        expect(token).to have_attributes(language: nil, content: "puts \"hello\"")
      end

      it "tokenizes a multi-line code block" do
        token = described_class.new("```\nline 1\nline 2\n```\n").tokenize.first
        expect(token).to have_attributes(content: "line 1\nline 2")
      end

      it "tokenizes an empty code block" do
        token = described_class.new("```\n```\n").tokenize.first
        expect(token).to have_attributes(language: nil, content: "")
      end

      it "falls back to Paragraph when the closing fence is missing" do
        token = described_class.new("```ruby\nputs \"hello\"\n").tokenize.first
        expect(token).to be_a(Mactor::Token::Paragraph)
      end

      it "preserves surrounding tokens around a code block" do
        source = "intro\n\n```ruby\ncode\n```\n\noutro\n"
        result = described_class.new(source).tokenize
        types = result.map(&:class)
        expect(types).to eq([
          Mactor::Token::Paragraph,
          Mactor::Token::Blank,
          Mactor::Token::CodeBlock,
          Mactor::Token::Blank,
          Mactor::Token::Paragraph
        ])
      end
    end

    context "thematic break" do
      it "recognizes ---" do
        expect(described_class.new("---").tokenize.first).to be_a(Mactor::Token::ThematicBreak)
      end

      it "recognizes ***" do
        expect(described_class.new("***").tokenize.first).to be_a(Mactor::Token::ThematicBreak)
      end

      it "recognizes ___" do
        expect(described_class.new("___").tokenize.first).to be_a(Mactor::Token::ThematicBreak)
      end

      it "recognizes - - -" do
        expect(described_class.new("- - -").tokenize.first).to be_a(Mactor::Token::ThematicBreak)
      end

      it "recognizes * * *" do
        expect(described_class.new("* * *").tokenize.first).to be_a(Mactor::Token::ThematicBreak)
      end

      it "recognizes _ _ _" do
        expect(described_class.new("_ _ _").tokenize.first).to be_a(Mactor::Token::ThematicBreak)
      end

      it "recognizes 4 or more characters" do
        expect(described_class.new("----").tokenize.first).to be_a(Mactor::Token::ThematicBreak)
      end

      it "does not recognize mixed characters like -*-" do
        expect(described_class.new("-*-").tokenize.first).to be_a(Mactor::Token::Paragraph)
      end

      it "does not recognize only 2 characters" do
        expect(described_class.new("--").tokenize.first).to be_a(Mactor::Token::Paragraph)
      end
    end

    context "unordered list" do
      it "groups consecutive - items into one List" do
        result = described_class.new("- foo\n- bar\n- baz\n").tokenize
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Mactor::Token::List)
        expect(result.first).to have_attributes(ordered: false, items: ["foo", "bar", "baz"])
      end

      it "recognizes * as an unordered marker" do
        token = described_class.new("* item\n").tokenize.first
        expect(token).to be_a(Mactor::Token::List)
        expect(token).to have_attributes(ordered: false, items: ["item"])
      end

      it "splits into separate Lists on a blank line" do
        result = described_class.new("- a\n- b\n\n- c\n").tokenize
        lists = result.select { |t| t.is_a?(Mactor::Token::List) }
        expect(lists.length).to eq(2)
        expect(lists[0]).to have_attributes(items: ["a", "b"])
        expect(lists[1]).to have_attributes(items: ["c"])
      end

      it "flushes a pending list when a block element follows" do
        result = described_class.new("- item\n# Heading\n").tokenize
        expect(result[0]).to be_a(Mactor::Token::List)
        expect(result[1]).to be_a(Mactor::Token::Heading)
      end

      it "flushes a pending paragraph before starting a list" do
        result = described_class.new("text\n- item\n").tokenize
        expect(result[0]).to be_a(Mactor::Token::Paragraph)
        expect(result[1]).to be_a(Mactor::Token::List)
      end
    end

    context "unordered list with + marker" do
      it "recognizes + as an unordered marker" do
        token = described_class.new("+ item\n").tokenize.first
        expect(token).to be_a(Mactor::Token::List)
        expect(token).to have_attributes(ordered: false, items: ["item"])
      end
    end

    context "ordered list" do
      it "groups consecutive ordered items into one List" do
        result = described_class.new("1. foo\n2. bar\n3. baz\n").tokenize
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Mactor::Token::List)
        expect(result.first).to have_attributes(ordered: true, items: ["foo", "bar", "baz"])
      end

      it "splits into a separate List when switching to unordered" do
        result = described_class.new("1. foo\n- bar\n").tokenize
        expect(result[0]).to have_attributes(ordered: true, items: ["foo"])
        expect(result[1]).to have_attributes(ordered: false, items: ["bar"])
      end

      it "splits into a separate List when switching to ordered" do
        result = described_class.new("- foo\n1. bar\n").tokenize
        expect(result[0]).to have_attributes(ordered: false, items: ["foo"])
        expect(result[1]).to have_attributes(ordered: true, items: ["bar"])
      end
    end

    context "list and blockquote interleaving" do
      it "flushes a pending list when a blockquote follows" do
        result = described_class.new("- item\n> quote\n").tokenize
        expect(result[0]).to be_a(Mactor::Token::List)
        expect(result[1]).to be_a(Mactor::Token::Blockquote)
      end

      it "flushes a pending blockquote when a list follows" do
        result = described_class.new("> quote\n- item\n").tokenize
        expect(result[0]).to be_a(Mactor::Token::Blockquote)
        expect(result[1]).to be_a(Mactor::Token::List)
      end
    end

    context "blockquote" do
      it "groups consecutive > lines into one Blockquote" do
        result = described_class.new("> Hello\n> World\n").tokenize
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Mactor::Token::Blockquote)
        expect(result.first).to have_attributes(content: "Hello\nWorld")
      end

      it "strips the leading > marker from each line" do
        token = described_class.new("> quoted\n").tokenize.first
        expect(token).to have_attributes(content: "quoted")
      end

      it "splits into separate Blockquotes on a blank line" do
        result = described_class.new("> a\n\n> b\n").tokenize
        quotes = result.select { |t| t.is_a?(Mactor::Token::Blockquote) }
        expect(quotes.length).to eq(2)
        expect(quotes[0]).to have_attributes(content: "a")
        expect(quotes[1]).to have_attributes(content: "b")
      end

      it "flushes a pending paragraph before starting a blockquote" do
        result = described_class.new("text\n> quote\n").tokenize
        expect(result[0]).to be_a(Mactor::Token::Paragraph)
        expect(result[1]).to be_a(Mactor::Token::Blockquote)
      end
    end

    context "blank lines" do
      it "handles multiple consecutive blank lines between paragraphs" do
        result = described_class.new("foo\n\n\n\nbar\n").tokenize
        paragraphs = result.select { |t| t.is_a?(Mactor::Token::Paragraph) }
        expect(paragraphs.length).to eq(2)
        expect(paragraphs[0]).to have_attributes(content: "foo")
        expect(paragraphs[1]).to have_attributes(content: "bar")
      end
    end

    context "blockquote without space after >" do
      it "strips > and returns the rest as content" do
        token = described_class.new(">content\n").tokenize.first
        expect(token).to be_a(Mactor::Token::Blockquote)
        expect(token).to have_attributes(content: "content")
      end
    end

    context "consecutive code blocks" do
      it "tokenizes two adjacent code blocks" do
        source = "```\nfirst\n```\n```\nsecond\n```\n"
        result = described_class.new(source).tokenize
        code_blocks = result.select { |t| t.is_a?(Mactor::Token::CodeBlock) }
        expect(code_blocks.length).to eq(2)
        expect(code_blocks[0]).to have_attributes(content: "first")
        expect(code_blocks[1]).to have_attributes(content: "second")
      end
    end

    context "paragraph" do
      it "treats plain text as Paragraph" do
        token = described_class.new("plain text").tokenize.first
        expect(token).to be_a(Mactor::Token::Paragraph)
        expect(token).to have_attributes(content: "plain text")
      end
    end

    context "multiple lines" do
      let(:source) { "# Title\n\nSome text\n" }

      it "emits Heading, Blank, then Paragraph" do
        expect(tokens.length).to eq(3)
        expect(tokens[0]).to be_a(Mactor::Token::Heading)
        expect(tokens[1]).to be_a(Mactor::Token::Blank)
        expect(tokens[2]).to be_a(Mactor::Token::Paragraph)
      end
    end

    context "paragraph grouping" do
      it "merges consecutive lines into one Paragraph" do
        source = "Hello world\nthis is same paragraph\n"
        result = described_class.new(source).tokenize
        expect(result.length).to eq(1)
        expect(result.first).to have_attributes(content: "Hello world\nthis is same paragraph")
      end

      it "splits on blank lines into separate Paragraphs" do
        source = "Hello world\nthis is same paragraph\n\nnew paragraph\n"
        result = described_class.new(source).tokenize
        paragraphs = result.select { |t| t.is_a?(Mactor::Token::Paragraph) }
        expect(paragraphs.length).to eq(2)
        expect(paragraphs[0]).to have_attributes(content: "Hello world\nthis is same paragraph")
        expect(paragraphs[1]).to have_attributes(content: "new paragraph")
      end

      it "flushes a pending paragraph when a block element interrupts" do
        source = "some text\n# Heading\n"
        result = described_class.new(source).tokenize
        expect(result[0]).to be_a(Mactor::Token::Paragraph)
        expect(result[1]).to be_a(Mactor::Token::Heading)
      end

      it "handles a trailing paragraph with no final newline" do
        result = described_class.new("line one\nline two").tokenize
        expect(result.first).to have_attributes(content: "line one\nline two")
      end
    end
  end
end
