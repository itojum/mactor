# frozen_string_literal: true

require "mactor/renderer/base"

module Mactor
  module Renderer
    class Html < Base
      def render_document(node)
        render_children(node)
      end

      def render_heading(node)
        "<h#{node.level}>#{render_children(node)}</h#{node.level}>\n"
      end

      def render_paragraph(node)
        "<p>#{render_children(node)}</p>\n"
      end

      def render_code_block(node)
        lang_attr = node.language ? " class=\"language-#{node.language}\"" : ""
        "<pre><code#{lang_attr}>#{h(node.content)}</code></pre>\n"
      end

      def render_list(node)
        tag = node.ordered ? "ol" : "ul"
        "<#{tag}>\n#{render_children(node)}</#{tag}>\n"
      end

      def render_list_item(node)
        return "<li>#{render_children(node)}</li>\n" if node.checked.nil?

        checkbox = node.checked ? "<input type=\"checkbox\" disabled checked>" : "<input type=\"checkbox\" disabled>"
        "<li>#{checkbox} #{render_children(node)}</li>\n"
      end

      def render_blockquote(node)
        "<blockquote>#{render_children(node)}</blockquote>\n"
      end

      def render_thematic_break(_node)
        "<hr>\n"
      end

      def render_text(node)
        h(node.content)
      end

      def render_strong(node)
        "<strong>#{render_children(node)}</strong>"
      end

      def render_emphasis(node)
        "<em>#{render_children(node)}</em>"
      end

      def render_inline_code(node)
        "<code>#{h(node.content)}</code>"
      end

      def render_link(node)
        title_attr = ""
        title_attr = " title=\"#{h(node.title)}\"" if node.title
        "<a href=\"#{h(node.href)}\"#{title_attr}>#{render_children(node)}</a>"
      end

      def render_image(node)
        title_attr = ""
        title_attr = " title=\"#{h(node.title)}\"" if node.title
        "<img src=\"#{h(node.src)}\" alt=\"#{h(node.alt)}\"#{title_attr}>"
      end

      def render_table(node)
        "<table>\n#{render_children(node)}</table>\n"
      end

      def render_table_head(node)
        "<thead>\n#{render_children(node)}</thead>\n"
      end

      def render_table_body(node)
        "<tbody>\n#{render_children(node)}</tbody>\n"
      end

      def render_table_row(node)
        "<tr>\n#{render_children(node)}</tr>\n"
      end

      def render_table_cell(node)
        tag = node.header ? "th" : "td"
        align_attr = node.align ? " style=\"text-align: #{node.align}\"" : ""
        "<#{tag}#{align_attr}>#{render_children(node)}</#{tag}>\n"
      end

      ESCAPE = { "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", '"' => "&quot;" }.freeze

      private

      def render_children(node)
        node.children.map { |child| render(child) }.join
      end

      def h(str)
        str.gsub(/[&<>"]/, ESCAPE)
      end
    end
  end
end
