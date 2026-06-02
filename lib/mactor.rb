# frozen_string_literal: true

require_relative "mactor/version"
require_relative "mactor/lexer"
require_relative "mactor/parser"
require_relative "mactor/renderer/html"

module Mactor
  class Error < StandardError; end

  module_function

  def parse(source)
    Parser.new(Lexer.new(source).tokenize).parse
  end

  def to_html(source)
    render(source, renderer: Renderer::Html.new)
  end

  def render(source, renderer:)
    renderer.render(parse(source))
  end
end
