# frozen_string_literal: true

require "spec_helper"
require "mactor/inline_lexer"

RSpec.describe Mactor::InlineLexer do
  def tokenize(source)
    described_class.new(source).tokenize
  end

  describe "#tokenize" do
    it "returns [] for an empty string" do
      expect(tokenize("")).to eq([])
    end

    it "returns an array of Token objects" do
      expect(tokenize("hello")).to all(be_a(Mactor::Token))
    end

    it "returns frozen tokens" do
      expect(tokenize("hello")).to all(be_frozen)
    end

    context "with plain text" do
      it "wraps unformatted text in a Text token" do
        expect(tokenize("plain text")).to eq([Mactor::Token::Text.new(content: "plain text")])
      end
    end

    context "with strong markup" do
      it "tokenizes **bold**" do
        expect(tokenize("**bold**")).to eq([Mactor::Token::Strong.new(content: "bold")])
      end
    end

    context "with emphasis markup" do
      it "tokenizes *em*" do
        expect(tokenize("*em*")).to eq([Mactor::Token::Emphasis.new(content: "em")])
      end
    end

    context "with inline code" do
      it "tokenizes `code`" do
        expect(tokenize("`code`")).to eq([Mactor::Token::InlineCode.new(content: "code")])
      end
    end

    context "with a link" do
      it "tokenizes [text](url)" do
        expect(tokenize("[click](https://example.com)")).to eq([
                                                                 Mactor::Token::Link.new(text: "click", url: "https://example.com")
                                                               ])
      end
    end

    context "with an image" do
      it "tokenizes ![alt](url)" do
        expect(tokenize("![logo](logo.png)")).to eq([
                                                      Mactor::Token::Image.new(alt: "logo", url: "logo.png")
                                                    ])
      end

      it "prefers Image over Link when ! precedes [" do
        result = tokenize("![img](img.png)")
        expect(result.first).to be_a(Mactor::Token::Image)
      end
    end

    context "with strong vs emphasis precedence" do
      it "tokenizes ** as Strong, not Emphasis" do
        result = tokenize("**bold**")
        expect(result.first).to be_a(Mactor::Token::Strong)
      end
    end

    context "with edge cases" do
      it "treats ** with no content as plain text" do
        expect(tokenize("**")).to eq([Mactor::Token::Text.new(content: "**")])
      end

      it "treats empty link syntax as plain text" do
        expect(tokenize("[]()")).to eq([Mactor::Token::Text.new(content: "[]()")])
      end

      it "handles multiple consecutive strong elements" do
        expect(tokenize("**a** **b**")).to eq([
                                                Mactor::Token::Strong.new(content: "a"),
                                                Mactor::Token::Text.new(content: " "),
                                                Mactor::Token::Strong.new(content: "b")
                                              ])
      end

      it "handles multiple consecutive emphasis elements" do
        expect(tokenize("*a* *b*")).to eq([
                                            Mactor::Token::Emphasis.new(content: "a"),
                                            Mactor::Token::Text.new(content: " "),
                                            Mactor::Token::Emphasis.new(content: "b")
                                          ])
      end

      it "tokenizes strong containing emphasis markers as Strong (non-greedy)" do
        result = tokenize("**bold *inner* more**")
        expect(result.first).to be_a(Mactor::Token::Strong)
        expect(result.first.content).to eq("bold *inner* more")
      end

      it "handles a URL with special characters in a link" do
        result = tokenize("[link](/path?a=1&b=2)")
        expect(result.first).to eq(Mactor::Token::Link.new(text: "link", url: "/path?a=1&b=2"))
      end
    end

    context "with mixed content" do
      it "splits surrounding text and inline elements" do
        expect(tokenize("Hello **world** and *em*")).to eq([
                                                             Mactor::Token::Text.new(content: "Hello "),
                                                             Mactor::Token::Strong.new(content: "world"),
                                                             Mactor::Token::Text.new(content: " and "),
                                                             Mactor::Token::Emphasis.new(content: "em")
                                                           ])
      end

      it "handles multiple different inline elements" do
        expect(tokenize("Hello **world** and [link](url)")).to eq([
                                                                    Mactor::Token::Text.new(content: "Hello "),
                                                                    Mactor::Token::Strong.new(content: "world"),
                                                                    Mactor::Token::Text.new(content: " and "),
                                                                    Mactor::Token::Link.new(text: "link", url: "url")
                                                                  ])
      end

      it "handles inline code alongside other elements" do
        expect(tokenize("use `foo` and **bar**")).to eq([
                                                          Mactor::Token::Text.new(content: "use "),
                                                          Mactor::Token::InlineCode.new(content: "foo"),
                                                          Mactor::Token::Text.new(content: " and "),
                                                          Mactor::Token::Strong.new(content: "bar")
                                                        ])
      end
    end
  end
end
