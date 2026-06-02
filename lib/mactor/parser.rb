# frozen_string_literal: true

require "mactor/node"
require "mactor/token"
require "mactor/inline_lexer"

module Mactor
  class Parser
    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    def parse
      children = []

      while @pos < @tokens.length
        node = parse_token(advance)
        children << node if node
      end

      Node::Document.new(children: children.freeze)
    end

    private

    def advance
      token = @tokens[@pos]
      @pos += 1
      token
    end

    def parse_token(token)
      case token
      when Token::Heading
        Node::Heading.new(level: token.level, children: inline_nodes(token.content))
      when Token::Paragraph
        Node::Paragraph.new(children: inline_nodes(token.content))
      when Token::CodeBlock
        Node::CodeBlock.new(language: token.language, content: token.content)
      when Token::ThematicBreak
        Node::ThematicBreak.new
      when Token::Blockquote
        Node::Blockquote.new(children: inline_nodes(token.content))
      when Token::List
        list_children = token.items.map { |item| Node::ListItem.new(children: inline_nodes(item)) }.freeze
        Node::List.new(ordered: token.ordered, children: list_children)
      when Token::Blank
        nil
      end
    end

    def inline_nodes(content)
      InlineLexer.new(content).tokenize.map { |t| inline_token_to_node(t) }.freeze
    end

    def inline_token_to_node(token)
      case token
      when Token::Text       then Node::Text.new(content: token.content)
      when Token::Strong     then Node::Strong.new(children: inline_nodes(token.content))
      when Token::Emphasis   then Node::Emphasis.new(children: inline_nodes(token.content))
      when Token::InlineCode then Node::InlineCode.new(content: token.content)
      when Token::Link       then Node::Link.new(href: token.url, children: inline_nodes(token.text))
      when Token::Image      then Node::Image.new(src: token.url, alt: token.alt)
      end
    end
  end
end
