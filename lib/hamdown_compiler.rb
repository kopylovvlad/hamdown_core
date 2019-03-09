# frozen_string_literal: true

module HamdownCompiler
  class << self
    def call(ast_root)
      strings = []
      strings = render_strings(ast_root.children, 0)
      strings.join("\n")
    end

    private

    def render_strings(ast_nodes, space_deep = 0)
      strings = []
      ast_nodes.each do |node|
        case node
        when HamdownParser::Ast::Filter
          str = (' ' * space_deep)
          str += ":#{node.name}"
          strings << str
          node.texts.each do |row|
            row = (' ' * (space_deep + 2)) + row
            strings << row
          end
        when HamdownParser::Ast::SilentScript
          str = (' ' * space_deep)
          str += "- #{node.script}"
          strings << str
        when HamdownParser::Ast::Script
          str = (' ' * space_deep)
          if node.escape_html == true
            str += "= #{node.script}"
          else
            str += "!= #{node.script}"
          end
          strings << str
        when HamdownParser::Ast::Text
          strings << (' ' * space_deep + "#{node.text}")
        when HamdownParser::Ast::HtmlComment
          # ready
          strings << (' ' * space_deep + "/ #{node.comment}")
        when HamdownParser::Ast::Empty
          # NODE: or add spaces?
          strings << ''
        when HamdownParser::Ast::Element
          # ready
          str = (' ' * space_deep)

          str += "%#{node.tag_name}"

          if node.static_id.size > 0
            str += "##{node.static_id}"
          end

          if node.static_class.size > 0
            str += ".#{node.static_class.gsub(' ', '.')}"
          end

          if !node.new_attributes.nil?
            props = []
            node.new_attributes.split(',').each do |str|
              l,r = str.split(' => ')
              l.gsub!("\"", '')
              r.gsub!("\"", "'")
              props << "#{l}=#{r}"
            end
            str += "(#{props.join(' ')})"
          end

          if !node.old_attributes.nil?
            str += "{#{node.old_attributes}}"
          end

          if !node.oneline_child.nil?
            substr = render_strings([node.oneline_child]).first
            unless substr.start_with?('=')
              substr = " #{substr}"
            end
            str += substr
          end

          strings << str
        end

        if node.respond_to?(:children) && node.children.size > 0
          render_strings(node.children, space_deep + 2).each do |str|
            strings << str
          end
        end
      end
      strings
    end
  end
end