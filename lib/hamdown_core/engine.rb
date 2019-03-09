# frozen_string_literal: true
require_relative 'parser'
require_relative 'transformer'
require_relative 'compiler'

module HamdownCore
  module Engine
    def self.call(content)
      ast = HamdownCore::Parser.new.call(content)
      transformed_ast = HamdownCore::Transformer.call(ast)
      puts HamdownCore::Compiler.call(transformed_ast)
    end
  end
end
