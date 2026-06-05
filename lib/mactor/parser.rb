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

    TASK_ITEM_PATTERN = /\A\[([ xX])\] (.*)/m

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
        list_children = token.items.map { |item| parse_list_item(item) }.freeze
        Node::List.new(ordered: token.ordered, children: list_children)
      when Token::Table
        parse_table(token)
      when Token::Blank
        nil
      end
    end

    def parse_list_item(content)
      m = content.match(TASK_ITEM_PATTERN)
      if m
        Node::ListItem.new(children: inline_nodes(m[2]), checked: m[1] != " ")
      else
        Node::ListItem.new(children: inline_nodes(content))
      end
    end

    def parse_table(token)
      aligns = token.aligns
      header_cells = token.headers.each_with_index.map do |content, i|
        Node::TableCell.new(children: inline_nodes(content), align: aligns[i], header: true)
      end.freeze
      head = Node::TableHead.new(children: [Node::TableRow.new(children: header_cells)].freeze)

      body_rows = token.rows.map do |row|
        cells = row.each_with_index.map do |content, i|
          Node::TableCell.new(children: inline_nodes(content), align: aligns[i], header: false)
        end.freeze
        Node::TableRow.new(children: cells)
      end.freeze
      body = Node::TableBody.new(children: body_rows)

      Node::Table.new(children: [head, body].freeze)
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
