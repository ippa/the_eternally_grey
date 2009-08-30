#
# The Eternally Grey
# 
# LD15 Entry by ippa @ freenode (#gosu / #rubygame)
#
$stderr.sync = $stdout.sync = true
ROOT_PATH = File.dirname(File.expand_path(__FILE__))

require 'rubygems'
require 'chingu'
require 'gosu'
include Gosu

%w{my_game_object enemies cave_objects core_extensions game_over_state intro_state menu_state cavern_state}.each do |file|
  require File.join(ROOT_PATH, "src", file)
end


class Game < Chingu::Window
  def initialize
    super(1000,700)
    caption = "The Eternally Grey."
    
    switch_game_state(Intro.new)
  end
end


Game.new.show