require "irb/completion"
require 'irb/ext/save-history'
require 'pp'
require 'yaml'

ARGV.concat [ "--readline", "--prompt-mode", "simple" ]

IRB.conf[:SAVE_HISTORY] = 10000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"
IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:AUTO_INDENT]  = true

def vim(x)
  IO.popen( 'vim -', 'w') do |io|
    io.puts x.to_yaml
  end
end

def less(x)
  IO.popen( 'less -', 'w') do |io|
    io.puts x.to_yaml
  end
end
