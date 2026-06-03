# frozen_string_literal: true

module Mactor
  module Token
    class << self
      private

      def define_token(*attrs)
        Data.define(*attrs) { include Mactor::Token }
      end
    end

    Heading = define_token(:level, :content)
    Paragraph = define_token(:content)
    Blank = define_token
    CodeFence = define_token(:language)
    CodeBlock = define_token(:language, :content)
    ListItem  = define_token(:marker, :content)
    List = define_token(:ordered, :items)
    ThematicBreak = define_token
    Blockquote = define_token(:content)
    TableLine = define_token(:raw)
    Table = define_token(:headers, :aligns, :rows)

    Text = define_token(:content)
    Strong = define_token(:content)
    Emphasis = define_token(:content)
    InlineCode = define_token(:content)
    Link = define_token(:text, :url)
    Image = define_token(:alt, :url)
  end
end
