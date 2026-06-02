# Mactor

**Ractor-compatible Markdown parser+**

Mactor parses Markdown text into an AST (Abstract Syntax Tree) and renders it to HTML or any custom format. Every data structure is immutable and Ractor-safe by design.

## Installation

Add to your Gemfile:

```ruby
gem "mactor"
```

Or install directly:

```bash
gem install mactor
```

## Usage

### Parse to AST

```ruby
require "mactor"

doc = Mactor.parse("# Hello\n\nThis is **mactor**.")
# => #<data Mactor::Node::Document ...>

doc.children.first
# => #<data Mactor::Node::Heading level=1, ...>
```

### Convert to HTML

```ruby
html = Mactor.to_html("# Hello\n\nThis is **mactor**.")
# => "<h1>Hello</h1>\n<p>This is <strong>mactor</strong>.</p>\n"
```

## Custom Renderers

Inherit from `Mactor::Renderer::Html` and override the methods you need. Unoverridden methods fall back to the default HTML output.

```ruby
require "mactor"

class HighlightRenderer < Mactor::Renderer::Html
  def render_code_block(node)
    "<pre><code>#{highlight(node.content, node.language)}</code></pre>\n"
  end

  def render_heading(node)
    id = render_children(node).downcase.gsub(/\s+/, "-")
    "<h#{node.level} id=\"#{id}\">#{render_children(node)}</h#{node.level}>\n"
  end
end

html = Mactor.render(source, renderer: HighlightRenderer.new)
```

A `config` hash can be passed to the constructor and is automatically frozen:

```ruby
renderer = HighlightRenderer.new(theme: "monokai")
# Access inside render_* methods via @config[:theme]
```

For non-HTML output formats, inherit from `Mactor::Renderer::Base` instead and implement all `render_*` methods.

## Ractor Support

All AST nodes are frozen `Data` objects, making them safe to share across Ractors without copying.

```ruby
require "mactor"

sources = ["# Hello", "**bold**", "- foo\n- bar"]

results = sources
  .map { |src| Ractor.new(src) { |s| Mactor.to_html(s) } }
  .map(&:value)

# => [
#   "<h1>Hello</h1>\n",
#   "<p><strong>bold</strong></p>\n",
#   "<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>\n"
# ]
```

## Supported Markdown Elements (v1)

### Block elements

| Syntax | Node |
|---|---|
| `#` – `######` | `Node::Heading` (level 1–6) |
| Blank-line-separated text | `Node::Paragraph` |
| ` ``` ` … ` ``` ` | `Node::CodeBlock` (optional language tag) |
| `- ` / `* ` / `+ ` | `Node::List` (ordered: false) |
| `1. ` `2. ` … | `Node::List` (ordered: true) |
| `> ` | `Node::Blockquote` |
| `---` / `***` / `___` (spaces allowed) | `Node::ThematicBreak` |

### Inline elements

| Syntax | Node |
|---|---|
| `**text**` | `Node::Strong` |
| `*text*` | `Node::Emphasis` |
| `` `code` `` | `Node::InlineCode` |
| `[text](url)` | `Node::Link` |
| `![alt](url)` | `Node::Image` |
| Plain text | `Node::Text` |

## Roadmap

Mactor is working toward full CommonMark compliance incrementally.

- [ ] CommonMark edge cases (setext headings, lazy continuation lines, etc.)
- [ ] Nested inline elements (`**_bold italic_**`)
- [ ] Link and image `title` attribute
- [ ] Nested block elements (lists inside blockquotes, etc.)
- [ ] Tables (GFM extension)
- [ ] Strikethrough and task lists (GFM extension)
- [ ] HTML renderer options (custom classes, id attributes, etc.)

## License

[MIT License](LICENSE.txt)
