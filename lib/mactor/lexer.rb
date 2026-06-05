# frozen_string_literal: true

require "mactor/token"

module Mactor
  module TableParsing
    private

    def flush_table
      return if @table_buffer.empty?

      if @table_buffer.length >= 2 && separator_row?(@table_buffer[1])
        headers = parse_cells(@table_buffer[0]).freeze
        aligns = parse_aligns(@table_buffer[1]).freeze
        rows = @table_buffer[2..].map { |line| parse_cells(line).freeze }.freeze
        @tokens << Token::Table.new(headers: headers, aligns: aligns, rows: rows)
      else
        @table_buffer.each { |line| @tokens << Token::Paragraph.new(content: line) }
      end
      @table_buffer = []
    end

    def parse_cells(line)
      line = line.strip
      line = line[1..] if line.start_with?("|")
      line = line[..-2] if line.end_with?("|")
      line.split("|").map(&:strip)
    end

    def separator_row?(line)
      cells = parse_cells(line)
      cells.any? && cells.all? { |cell| cell.strip.match?(/\A:?-+:?\z/) }
    end

    def parse_aligns(line)
      parse_cells(line).map do |cell|
        cell = cell.strip
        if cell.start_with?(":") && cell.end_with?(":")
          :center
        elsif cell.start_with?(":")
          :left
        elsif cell.end_with?(":")
          :right
        end
      end
    end
  end

  module LineClassification
    private

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
      when /\A\|/
        Token::TableLine.new(raw: line)
      else
        Token::Paragraph.new(content: line)
      end
    end

    def ordered_marker?(marker)
      marker.match?(/\A\d/)
    end
  end

  class Lexer
    include TableParsing
    include LineClassification

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
      @table_buffer = []
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

      dispatch_token(classify_line(line))
    end

    def dispatch_token(classified)
      case classified
      when Token::CodeFence  then handle_code_fence(classified)
      when Token::TableLine  then handle_table_line(classified)
      when Token::ListItem   then handle_list_item(classified)
      when Token::Blockquote then handle_blockquote_token(classified)
      when Token::Paragraph  then handle_paragraph_token(classified)
      else
        flush_all
        @tokens << classified
      end
    end

    def handle_code_fence(classified)
      flush_all
      @in_code_block = true
      @code_block_language = classified.language.empty? ? nil : classified.language
      @code_block_buffer = []
    end

    def handle_table_line(classified)
      flush_paragraph
      flush_blockquote
      flush_list
      @table_buffer << classified.raw
    end

    def handle_list_item(classified)
      ordered = ordered_marker?(classified.marker)
      flush_paragraph
      flush_blockquote
      flush_table
      flush_list if !@list_buffer.empty? && @list_ordered != ordered
      @list_ordered = ordered
      @list_buffer << classified.content
    end

    def handle_blockquote_token(classified)
      flush_paragraph
      flush_list
      flush_table
      @blockquote_buffer << classified.content
    end

    def handle_paragraph_token(classified)
      flush_list
      flush_blockquote
      flush_table
      @paragraph_buffer << classified.content
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
      flush_table
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
  end
end
