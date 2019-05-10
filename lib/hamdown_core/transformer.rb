# frozen_string_literal: true

module HamdownCore
  module Transformer
    class << self
      def call(ast)
        transform(ast)
      end

      private

      def transform(root_node)
        collected_nodes = []
        new_root_node = root_node.clone
        new_root_node.children = []
        root_node.children.each do |node|
          if node.respond_to?(:markdownable?) && node.markdownable?
            collected_nodes << node
            next
          end

          if collected_nodes.size > 0
            filter = create_filter(collected_nodes)
            collected_nodes = []
            new_root_node << filter
          end

          if node.respond_to?(:children) && node.children.size > 0
            node = transform(node)
          end

          if node.respond_to?(:html_list?) and node.html_list?
            filter = if node.ol_list?
              create_filter(node.children.map(&:to_ol_list_item!))
            else
              create_filter(node.children.map(&:to_ul_list_item!))
            end
            node = filter
          end

          new_root_node << node
        end

        if collected_nodes.size > 0
          filter = create_filter(collected_nodes)
          collected_nodes = []
          new_root_node << filter
        end
        new_root_node
      end

      def create_filter(nodes)
        filter = HamdownCore::Ast::Filter.new
        filter.name = 'markdown'
        nodes.each do |collected_node|
          filter.texts << collected_node.text
        end
        filter
      end
    end
  end
end
