# frozen_string_literal: true

require "mactor/token"

module Mactor
  class Lexer
    def initialize(source)
      @source = source
      @tokens = []
      @paragraph_buffer = []
      @blockquote_buffer = []
      @list_buffer = []
      @list_ordered = nil
      @in_code_block = false
      @code_block_language = nil
      @code_block_buffer = []
    end

    def tokenize
      return [] if @source.empty?

      @source.each_line do |line|
        process_line(line.chomp)
      end

      if @in_code_block
        fence_line = @code_block_language ? "```#{@code_block_language}" : "```"
        @paragraph_buffer << fence_line
        @paragraph_buffer.concat(@code_block_buffer)
        @in_code_block = false
      end

      flush_all
      @tokens
    end

    private

    def process_line(line)
      if @in_code_block
        handle_code_block_line(line)
        return
      end

      classified = classify_line(line)

      case classified
      when Token::CodeFence
        flush_all
        @in_code_block = true
        @code_block_language = classified.language.empty? ? nil : classified.language
        @code_block_buffer = []
      when Token::ListItem
        ordered = ordered_marker?(classified.marker)
        flush_paragraph
        flush_blockquote
        flush_list if !@list_buffer.empty? && @list_ordered != ordered
        @list_ordered = ordered
        @list_buffer << classified.content
      when Token::Blockquote
        flush_paragraph
        flush_list
        @blockquote_buffer << classified.content
      when Token::Paragraph
        flush_list
        flush_blockquote
        @paragraph_buffer << classified.content
      else
        flush_all
        @tokens << classified
      end
    end

    def handle_code_block_line(line)
      if line.match?(/\A`{3}\s*\z/)
        @tokens << Token::CodeBlock.new(language: @code_block_language, content: @code_block_buffer.join("\n"))
        @in_code_block = false
        @code_block_language = nil
        @code_block_buffer = []
      else
        @code_block_buffer << line
      end
    end

    def flush_all
      flush_paragraph
      flush_list
      flush_blockquote
    end

    def flush_paragraph
      return if @paragraph_buffer.empty?

      @tokens << Token::Paragraph.new(content: @paragraph_buffer.join("\n"))
      @paragraph_buffer = []
    end

    def flush_list
      return if @list_buffer.empty?

      @tokens << Token::List.new(ordered: @list_ordered, items: @list_buffer.freeze)
      @list_buffer = []
      @list_ordered = nil
    end

    def flush_blockquote
      return if @blockquote_buffer.empty?

      @tokens << Token::Blockquote.new(content: @blockquote_buffer.join("\n"))
      @blockquote_buffer = []
    end

    def ordered_marker?(marker)
      marker.match?(/\A\d/)
    end

    def classify_line(line)
      case line
      when /\A\s*\z/
        Token::Blank.new
      when /\A(#+)\s+(.*)/
        level = Regexp.last_match(1).length
        return Token::Paragraph.new(content: line) if level > 6

        Token::Heading.new(level: level, content: Regexp.last_match(2))
      when /\A`{3}(.*)/
        Token::CodeFence.new(language: Regexp.last_match(1))
      when /\A[ \t]*([-*_])([ \t]*\1){2,}[ \t]*\z/
        Token::ThematicBreak.new
      when /\A([-*+]|\d+\.)\s+(.*)/
        Token::ListItem.new(marker: Regexp.last_match(1), content: Regexp.last_match(2))
      when /\A>\s?(.*)/
        Token::Blockquote.new(content: Regexp.last_match(1))
      else
        Token::Paragraph.new(content: line)
      end
    end
  end
end
