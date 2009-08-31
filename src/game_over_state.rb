class GameOver < Chingu::GameState
  def initialize(options)
    super
    @score = options[:score]
    @text = Chingu::Text.new(:text => "GAME OVER - They stole all your riches. Score: #{@score}.", :x => 200, :y => 200, :size => 30, :zorder => 1000)
    @text2 = Chingu::Text.new(:text => "ESC: quit  SPACE: try again",:x => 400, :y => 300, :size => 20, :zorder => 1000)
    self.input = { :esc => :exit, :space => :play_again }
  end
  
  def play_again
    switch_game_state(Cavern.new)
  end

#  def draw
#    previous_game_state.draw
#    super
#  end
end
