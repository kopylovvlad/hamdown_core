# frozen_string_literal: true
require 'optparse'
require_relative 'version'

module HamdownCore
  module Cli
    def self.call(argv)
      file_name = OptionParser.new.tap do |parser|
        parser.version = VERSION
      end.parse!(argv).first

      if file_name.nil? || file_name.size == 0
        puts 'Error: No file.'
        puts 'Use it like: "exe/hamdown_core path_to/file.hd > output.html"'
        return nil
      end

      content = File.open(file_name, 'r').read
      output = Engine.call(content)
      puts output
    end
  end
end
