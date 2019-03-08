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

          strings << str
        end
      end
      strings
    end
  end
end