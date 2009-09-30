#
# The Eternally Grey
# 
# LD15 Entry by ippa @ freenode (#gosu / #rubygame)
#
$stderr.sync = $stdout.sync = true
ROOT_PATH = File.dirname(File.expand_path(__FILE__))

require 'gosu'
require '../chingu/lib/chingu'

include Gosu
include Chingu
require_all "#{ROOT_PATH}/src"


class Game < Chingu::Window
  def initialize
    super(1000,700)
    self.caption = "The Eternally Grey."
    
    switch_game_state(Intro.new)
  end
end


Game.new.show