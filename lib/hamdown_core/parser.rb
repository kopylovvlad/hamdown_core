# frozen_string_literal: true
require_relative 'ast'
require_relative 'element_parser'
require_relative 'error'
require_relative 'filter_parser'
require_relative 'indent_tracker'
require_relative 'line_parser'
require_relative 'ruby_multiline'
require_relative 'script_parser'
require_relative 'utils'

module HamdownCore
  class Parser
    def initialize(options = {})
      @filename = options[:filename]
    end

    def call(template_str)
      @ast = Ast::Root.new
      @stack = []
      @line_parser = LineParser.new(@filename, template_str)
      @indent_tracker = IndentTracker.new(on_enter: method(:indent_enter), on_leave: method(:indent_leave))
      @filter_parser = FilterParser.new(@indent_tracker)

      while @line_parser.has_next?
        in_filter = !@ast.is_a?(Ast::HamlComment) && @filter_parser.enabled?
        line = @line_parser.next_line(in_filter: in_filter)
        if in_filter
          ast = @filter_parser.append(line)
          if ast
            @ast << ast
          end
        end
        unless @filter_parser.enabled?
          line_count = line.count("\n")
          line.delete!("\n")
          parse_line(line)
          line_count.times do
            @ast << create_node(Ast::Empty)
          end
        end
      end

      ast = @filter_parser.finish
      if ast
        @ast << ast
      end
      @indent_tracker.finish
      @ast
    rescue Error => e
      if @filename && e.lineno
        e.backtrace.unshift "#{@filename}:#{e.lineno}"
      end
      raise e
    end

    private

    DOCTYPE_PREFIX = '!'
    ELEMENT_PREFIX = '%'
    COMMENT_PREFIX = '/'
    SILENT_SCRIPT_PREFIX = '-'
    DIV_ID_PREFIX = '#'
    DIV_CLASS_PREFIX = '.'
    FILTER_PREFIX = ':'
    ESCAPE_PREFIX = '\\'

    MARKDOWN = {
      'headers' => /^\#{1,6} .+$/,
      'list_item' => /((^[\d{1,3}|\*|\+]\.? .*\n?)+)/, # not nesting
      'quotes' => /((^>{1,4} .+\n?)+)/,
      'image' => /^!\[[^\[\]]*?\]\([^\s]*?\)/,
      'image_title' => /^!\[[^\[\]]*?\]\([^\s]*\s\".*\"\)/,
      'link' => /^[^!]\[[^\[\]]*?\]\([^\s]*?\)/,
      'link_with_title' => /^[^!]\[[^\[\]]*?\]\([^\s]*\s\".*\"\)/
      # codeblock # nesting within plain text is illegal
    }

    HTML = {
      'list_ol_root' => /^ *<ol>/,
      'list_ul_root' => /^ *<ul>/,
      'list_end' => /^ *<\/(ul|ol)>/,
      'list_item' => /^ *<li>.*<\/li>$/
    }

    def parse_line(line)
      text, indent = @indent_tracker.process(line, @line_parser.lineno)

      if text.empty?
        @ast << create_node(Ast::Empty)
        return
      end

      if @ast.is_a?(Ast::HamlComment)
        @ast << create_node(Ast::Text) { |t| t.text = text }
        return
      end

      case text
      when MARKDOWN['headers']
        parse_md_header(text)
      when MARKDOWN['list_item']
        parse_md_list(text)
      when MARKDOWN['quotes']
        parse_md_quote(text)
      when MARKDOWN['image']
        parse_md_image(text)
      when MARKDOWN['image_title']
        parse_md_image(text, true)
      when MARKDOWN['link']
        parse_md_link(text)
      when MARKDOWN['link_title']
        parse_md_link(text, true)
      when HTML['list_ol_root']
        parse_html_list(text, :ol)
      when HTML['list_ul_root']
        parse_html_list(text, :ul)
      when HTML['list_end']
        parse_html_list_end(text)
      when HTML['list_item']
        parse_html_list_item(text)
      else
        std_parse_line(text, indent)
      end
    end

    def std_parse_line(text, indent)
      case text[0]
      when ESCAPE_PREFIX
        parse_plain(text[1..-1])
      when ELEMENT_PREFIX
        parse_element(text)
      when DOCTYPE_PREFIX
        if text.start_with?('!!!')
          parse_doctype(text)
        else
          parse_script(text)
        end
      when COMMENT_PREFIX
        parse_comment(text)
      when SILENT_SCRIPT_PREFIX
        parse_silent_script(text)
      when DIV_ID_PREFIX, DIV_CLASS_PREFIX
        if text.start_with?('#{')
          parse_script(text)
        else
          parse_line("#{indent}%div#{text}")
        end
      when FILTER_PREFIX
        parse_filter(text)
      else
        parse_script(text)
      end
    end

    def parse_doctype(text)
      @ast << create_node(Ast::Doctype) { |d| d.doctype = text[3..-1].strip }
    end

    def parse_comment(text)
      text = text[1, text.size - 1].strip
      comment = create_node(Ast::HtmlComment)
      comment.comment = text
      if text[0] == '['
        comment.conditional, rest = parse_conditional_comment(text)
        text.replace(rest)
      end
      @ast << comment
    end

    CONDITIONAL_COMMENT_REGEX = /[\[\]]/o

    def parse_conditional_comment(text)
      s = StringScanner.new(text[1..-1])
      depth = Utils.balance(s, '[', ']')
      if depth == 0
        [s.pre_match, s.rest.lstrip]
      else
        syntax_error!('Unmatched brackets in conditional comment')
      end
    end

    def parse_plain(text)
      @ast << create_node(Ast::Text) { |t| t.text = text }
    end

    def parse_md_header(text)
      @ast << create_node(Ast::MdHeader) { |t| t.text = text }
    end

    def parse_md_list(text)
      @ast << create_node(Ast::MdList) { |t| t.text = text }
    end

    def parse_html_list(text, type)
      if type == :ol
        @ast << create_node(Ast::HtmlOlList) { |t| t.text = text }
      elsif type == :ul
        @ast << create_node(Ast::HtmlUlList) { |t| t.text = text }
      else
        raise 'undefined html list type'
      end
    end

    def parse_html_list_item(text)
      @ast << create_node(Ast::HtmlListItem) { |t| t.text = text }
    end

    def parse_html_list_end(text)
      @ast << create_node(Ast::HtmlListEnd) { |t| t.text = text }
    end

    def parse_md_quote(text)
      @ast << create_node(Ast::MdQuote) { |t| t.text = text }
    end

    def parse_md_image(text, title = false)
      if title == true
        @ast << create_node(Ast::MdImageTitle) { |t| t.text = text }
      else
        @ast << create_node(Ast::MdImage) { |t| t.text = text }
      end
    end

    def parse_md_link(text, title = false)
      if title == true
        @ast << create_node(Ast::MdLinkTitle) { |t| t.text = text }
      else
        @ast << create_node(Ast::MdLink) { |t| t.text = text }
      end
    end

    def parse_element(text)
      @ast << ElementParser.new(@line_parser).parse(text)
    end

    def parse_script(text)
      node = ScriptParser.new(@line_parser).parse(text)
      if node.is_a?(Ast::Script)
        node.keyword = block_keyword(node.script)
      end
      @ast << node
    end

    def parse_silent_script(text)
      if text.start_with?('-#')
        @ast << create_node(Ast::HamlComment)
        return
      end
      node = create_node(Ast::SilentScript)
      script = text[/\A- *(.*)\z/, 1]
      node.script = [script, *RubyMultiline.read(@line_parser, script)].join("\n")
      node.keyword = block_keyword(node.script)
      @ast << node
    end

    def parse_filter(text)
      filter_name = text[/\A#{FILTER_PREFIX}(\w+)\z/, 1]
      unless filter_name
        syntax_error!("Invalid filter name: #{text}")
      end
      @filter_parser.start(filter_name, @line_parser.filename, @line_parser.lineno)
    end

    def indent_enter(_, _text)
      empty_lines = []
      while @ast.children.last.is_a?(Ast::Empty)
        empty_lines << @ast.children.pop
      end
      @stack.push(@ast)
      @ast = @ast.children.last
      case @ast
      when Ast::Text
        syntax_error!('nesting within plain text is illegal')
      when Ast::Doctype
        syntax_error!('nesting within a header command is illegal')
      when nil
        syntax_error!('Indenting at the beginning of the document is illegal')
      end
      @ast.children = empty_lines
      if @ast.is_a?(Ast::Element) && @ast.self_closing
        syntax_error!('Illegal nesting: nesting within a self-closing tag is illegal')
      end
      if @ast.is_a?(Ast::HtmlComment) && !@ast.comment.empty?
        syntax_error!('Illegal nesting: nesting within a html comment that already has content is illegal.')
      end
      if @ast.is_a?(Ast::HamlComment)
        @indent_tracker.enter_comment!
      else
        @indent_tracker.check_indent_level!(@line_parser.lineno)
      end
      nil
    end

    def indent_leave(_indent_level, _text)
      parent_ast = @stack.pop
      @ast = parent_ast
      nil
    end

    MID_BLOCK_KEYWORDS = %w[else elsif rescue ensure end when].freeze
    START_BLOCK_KEYWORDS = %w[if begin case unless].freeze
    # Try to parse assignments to block starters as best as possible
    START_BLOCK_KEYWORD_REGEX = /(?:\w+(?:,\s*\w+)*\s*=\s*)?(#{Regexp.union(START_BLOCK_KEYWORDS)})/
    BLOCK_KEYWORD_REGEX = /^-?\s*(?:(#{Regexp.union(MID_BLOCK_KEYWORDS)})|#{START_BLOCK_KEYWORD_REGEX.source})\b/

    def block_keyword(text)
      m = text.match(BLOCK_KEYWORD_REGEX)
      if m
        m[1] || m[2]
      end
    end

    def syntax_error!(message)
      raise Error.new(message, @line_parser.lineno)
    end

    def create_node(klass, &block)
      klass.new.tap do |node|
        node.filename = @line_parser.filename
        node.lineno = @line_parser.lineno
        if block
          yield(node)
        end
      end
    end
  end
end
