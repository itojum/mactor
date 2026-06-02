# frozen_string_literal: true

require "mactor/node"

module Mactor
  module Renderer
    class Base
      def initialize(config = {})
        @config = config.freeze
      end

      def render(node)
        send(dispatch(node), node)
      end

      def render_document(node) = raise NotImplementedError, "#{self.class}#render_document"
      def render_heading(node) = raise NotImplementedError, "#{self.class}#render_heading"
      def render_paragraph(node) = raise NotImplementedError, "#{self.class}#render_paragraph"
      def render_code_block(node) = raise NotImplementedError, "#{self.class}#render_code_block"
      def render_list(node) = raise NotImplementedError, "#{self.class}#render_list"
      def render_list_item(node) = raise NotImplementedError, "#{self.class}#render_list_item"
      def render_blockquote(node) = raise NotImplementedError, "#{self.class}#render_blockquote"
      def render_thematic_break(node) = raise NotImplementedError, "#{self.class}#render_thematic_break"
      def render_text(node) = raise NotImplementedError, "#{self.class}#render_text"
      def render_strong(node) = raise NotImplementedError, "#{self.class}#render_strong"
      def render_emphasis(node) = raise NotImplementedError, "#{self.class}#render_emphasis"
      def render_inline_code(node) = raise NotImplementedError, "#{self.class}#render_inline_code"
      def render_link(node) = raise NotImplementedError, "#{self.class}#render_link"
      def render_image(node) = raise NotImplementedError, "#{self.class}#render_image"

      private

      def dispatch(node)
        snake = node.class.name.split("::").last
                    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                    .downcase
        :"render_#{snake}"
      end
    end
  end
end
