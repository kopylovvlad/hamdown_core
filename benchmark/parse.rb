#!/usr/bin/env ruby
# frozen_string_literal: true
require 'benchmark/ips'
require 'haml'
require_relative '../lib/hamdown_core/parser'

template = File.read(ARGV[0])
options = Haml::Options.new

Benchmark.ips do |x|
  x.report('Haml::Parser') do
    Haml::Parser.new(template, options).parse
  end

  x.report('HamdownCore::Parser') do
    HamdownCore::Parser.new.call(template)
  end

  x.compare!
end
