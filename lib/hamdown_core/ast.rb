# frozen_string_literal: true

module HamdownCore
  module Ast
    module HasChildren
      def initialize(*)
        super
        self.children ||= []
      end

      def <<(ast)
        self.children << ast
      end

      def to_h
        super.merge(children: children.map(&:to_h))
      end
    end

    Root = Struct.new(:children) do
      include HasChildren

      def to_h
        super.merge(type: 'root')
      end
    end

    Doctype = Struct.new(:doctype, :filename, :lineno) do
      def to_h
        super.merge(type: 'doctype')
      end
    end

    Element = Struct.new(
      :children,
      :tag_name,
      :static_class,
      :static_id,
      :old_attributes,
      :new_attributes,
      :oneline_child,
      :self_closing,
      :nuke_inner_whitespace,
      :nuke_outer_whitespace,
      :object_ref,
      :filename,
      :lineno,
    ) do
      include HasChildren

      def initialize(*)
        super
        self.static_class ||= ''
        self.static_id ||= ''
        self.self_closing ||= false
        self.nuke_inner_whitespace ||= false
        self.nuke_outer_whitespace ||= false
      end

      def to_h
        super.merge(
          type: 'element',
          oneline_child: oneline_child && oneline_child.to_h,
        )
      end

      # XXX: For compatibility
      def attributes
        attrs = old_attributes || ''
        if new_attributes
          if attrs.empty?
            attrs = new_attributes
          else
            attrs += ", #{new_attributes}"
          end
        end
        attrs
      end
    end

    Script = Struct.new(
      :children,
      :script,
      :keyword,
      :escape_html,
      :preserve,
      :filename,
      :lineno,
    ) do
      include HasChildren

      def initialize(*)
        super
        if escape_html.nil?
          self.escape_html = true
        end
        if preserve.nil?
          self.preserve = false
        end
      end

      def to_h
        super.merge(type: 'script')
      end
    end

    SilentScript = Struct.new(:children, :script, :keyword, :filename, :lineno) do
      include HasChildren

      def to_h
        super.merge(type: 'silent_script')
      end
    end

    HtmlComment = Struct.new(:children, :comment, :conditional, :filename, :lineno) do
      include HasChildren

      def initialize(*)
        super
        self.comment ||= ''
        self.conditional ||= ''
      end

      def to_h
        super.merge(type: 'html_comment')
      end
    end

    HamlComment = Struct.new(:children, :filename, :lineno) do
      include HasChildren

      def to_h
        super.merge(type: 'haml_comment')
      end
    end

    BaseText = Struct.new(:text, :escape_html, :filename, :lineno) do
      def initialize(*)
        super
        if escape_html.nil?
          self.escape_html = true
        end
      end

      def to_h
        super.merge(type: 'text')
      end

      def markdownable?
        true
      end
    end

    class Text < BaseText; end

    # markdown
    class MdHeader < Text; end
    class MdList < Text; end
    class MdQuote < Text; end
    class MdImageTitle < Text; end
    class MdImage < Text; end
    class MdLinkTitle < Text; end
    class MdLink < Text; end

    # html
    HtmlList = Struct.new(:children, :text, :filename, :lineno) do
      include HasChildren

      def to_h
        super.merge(type: 'html_list')
      end
    end
    class HtmlOlList < HtmlList
      def ol_list?
        true
      end
      def html_list?
        true
      end
    end
    class HtmlUlList < HtmlList
      def ol_list?
        false
      end
      def html_list?
        true
      end
    end

    class HtmlListItem < BaseText
      def html_list_item?
        true
      end
      def markdownable?
        false
      end
      def to_ol_list_item!
        node = HtmlOlListItem.new
        node.filename = filename
        node.lineno = lineno
        node.text = text
        node
      end
      def to_ul_list_item!
        node = HtmlUlListItem.new
        node.filename = filename
        node.lineno = lineno
        node.text = text
        node
      end
    end
    class HtmlOlListItem < HtmlListItem
      def text
        str = super.gsub('<li>', '').gsub('</li>', '')
        "1. #{str}"
      end
    end
    class HtmlUlListItem < HtmlListItem
      def text
        str = super.gsub('<li>', '').gsub('</li>', '')
        "* #{str}"
      end
    end

    class HtmlListEnd < BaseText
      def markdownable?
        false
      end
    end

    Filter = Struct.new(:name, :texts, :filename, :lineno) do
      def initialize(*)
        super
        self.texts ||= []
      end

      def to_h
        super.merge(type: 'filter')
      end
    end

    Empty = Struct.new(:filename, :lineno) do
      def to_h
        super.merge(type: 'empty')
      end
    end
  end
end
