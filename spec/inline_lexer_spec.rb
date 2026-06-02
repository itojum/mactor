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

    context "plain text" do
      it "wraps unformatted text in a Text token" do
        expect(tokenize("plain text")).to eq([Mactor::Token::Text.new(content: "plain text")])
      end
    end

    context "strong" do
      it "tokenizes **bold**" do
        expect(tokenize("**bold**")).to eq([Mactor::Token::Strong.new(content: "bold")])
      end
    end

    context "emphasis" do
      it "tokenizes *em*" do
        expect(tokenize("*em*")).to eq([Mactor::Token::Emphasis.new(content: "em")])
      end
    end

    context "inline code" do
      it "tokenizes `code`" do
        expect(tokenize("`code`")).to eq([Mactor::Token::InlineCode.new(content: "code")])
      end
    end

    context "link" do
      it "tokenizes [text](url)" do
        expect(tokenize("[click](https://example.com)")).to eq([
          Mactor::Token::Link.new(text: "click", url: "https://example.com")
        ])
      end
    end

    context "image" do
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

    context "strong vs emphasis precedence" do
      it "tokenizes ** as Strong, not Emphasis" do
        result = tokenize("**bold**")
        expect(result.first).to be_a(Mactor::Token::Strong)
      end
    end

    context "mixed content" do
      it "splits surrounding text and inline elements" do
        expect(tokenize("Hello **world** and *em*")).to eq([
          Mactor::Token::Text.new(content: "Hello "),
          Mactor::Token::Strong.new(content: "world"),
          Mactor::Token::Text.new(content: " and "),
          Mactor::Token::Emphasis.new(content: "em"),
        ])
      end

      it "handles multiple different inline elements" do
        expect(tokenize("Hello **world** and [link](url)")).to eq([
          Mactor::Token::Text.new(content: "Hello "),
          Mactor::Token::Strong.new(content: "world"),
          Mactor::Token::Text.new(content: " and "),
          Mactor::Token::Link.new(text: "link", url: "url"),
        ])
      end

      it "handles inline code alongside other elements" do
        expect(tokenize("use `foo` and **bar**")).to eq([
          Mactor::Token::Text.new(content: "use "),
          Mactor::Token::InlineCode.new(content: "foo"),
          Mactor::Token::Text.new(content: " and "),
          Mactor::Token::Strong.new(content: "bar"),
        ])
      end
    end
  end
end
