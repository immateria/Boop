require 'json'
require 'open-uri'

data = JSON.parse(ENV['BOOP_STATE'] || '{}')
MODULE_EXT = ENV['BOOP_MODULE_EXT'] || '.rb'
SCRIPT_DIR = ENV['BOOP_SCRIPT_DIR'] || ''
LIB_DIR = ENV['BOOP_LIB_DIR'] || ''

module Kernel
  alias_method :_boop_native_require, :require
  def boop_require(path)
    mod = path
    mod += MODULE_EXT unless mod.end_with?(MODULE_EXT)
    full = if mod.start_with?('@boop/')
             File.join(LIB_DIR, mod[6..-1])
           else
             File.join(SCRIPT_DIR, mod)
           end
    if File.exist?(full)
      load full
      true
    else
      _boop_native_require(path)
    end
  end
  module_function :boop_require
end

class State
  attr_accessor :text, :fullText, :selection
  def initialize(hash)
    @text = hash['text']
    @fullText = hash['fullText']
    @selection = hash['selection']
    @network = hash['network']
    @inserts = []
    @messages = []
  end
  def post_info(msg)
    @messages << { 'type' => 'info', 'message' => msg }
  end
  def post_error(msg)
    @messages << { 'type' => 'error', 'message' => msg }
  end
  def insert(val)
    @inserts << val
  end
  def fetch(url, method=nil, body=nil)
    unless @network
      post_error('Network permission required')
      return nil
    end
    begin
      cmd = ['curl', '-sL']
      cmd += ['-X', method] if method && method != 'GET'
      cmd += ['--data', body.to_s] if body
      cmd << url
      IO.popen(cmd, 'r', &:read)
    rescue
      post_error('Failed to fetch')
      nil
    end
  end
  def to_h
    {
      'text' => @text,
      'fullText' => @fullText,
      'selection' => @selection,
      'inserts' => @inserts,
      'messages' => @messages
    }
  end
end

script_path = ARGV.shift

state = State.new(data)
load script_path
if defined?(main)
  main(state)
end

puts JSON.generate(state.to_h)
