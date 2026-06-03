# frozen_string_literal: true

require "mactor/token"

module Mactor
  class InlineLexer
    PATTERNS = [
      [:image,       /!\[(.+?)\]\((.+?)\)/],
      [:link,        /\[(.+?)\]\((.+?)\)/],
      [:strong,      /\*\*(.+?)\*\*/],
      [:emphasis,    /\*(.+?)\*/],
      [:inline_code, /(`+)(.+?)\1/]
    ].map(&:freeze).freeze

    def initialize(source)
      @source = source
    end

    def tokenize
      return [] if @source.empty?

      tokens = []
      remaining = @source

      until remaining.empty?
        earliest_pos = remaining.length
        earliest_match = nil
        earliest_type = nil

        PATTERNS.each do |type, pattern|
          m = remaining.match(pattern)
          next unless m && m.begin(0) < earliest_pos

          earliest_pos = m.begin(0)
          earliest_match = m
          earliest_type = type
        end

        if earliest_match
          tokens << Token::Text.new(content: remaining[0, earliest_pos]) if earliest_pos.positive?
          tokens << build_token(earliest_type, earliest_match)
          remaining = remaining[earliest_match.end(0)..]
        else
          tokens << Token::Text.new(content: remaining)
          break
        end
      end

      tokens
    end

    private

    def build_token(type, match)
      case type
      when :image       then Token::Image.new(alt: match[1], url: match[2])
      when :link        then Token::Link.new(text: match[1], url: match[2])
      when :strong      then Token::Strong.new(content: match[1])
      when :emphasis    then Token::Emphasis.new(content: match[1])
      when :inline_code
        content = match[2]
        content = content[1..-2] if content.start_with?(" ") && content.end_with?(" ") && content.strip.length.positive?
        Token::InlineCode.new(content: content)
      end
    end
  end
end
