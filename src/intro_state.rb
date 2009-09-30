class Intro < Chingu::GameState
  
  def initialize
    super
    
    @strings = [
      "...mmmnmnnm...hmmm....I'm so tired...",
      "why am I awake? what am I?",
      "...wait, what is this...",
      "...something, a feeling ... I haven't felt in ages..."
    ].reverse
    
    self.input = { :space => Cavern, :esc => :exit }
  end
  
  def setup
    Song["the_eternally_grey_1.ogg"].play(true)
  end  
  
  def update    
    game_objects.destroy_if { |object| object.color.alpha == 0}
    
    if game_objects.size == 0
      if string = @strings.pop
        @text = Chingu::Text.create(:text => string, :x => 100, :y => 200)
      else
        switch_game_state(Cavern.new)
      end
    end
    @text.factor_x += 0.005
    @text.factor_y += 0.005
    if ($window.ticks % 2) == 0
      @text.color.alpha -= 1  if @text.color.alpha > 0
    end
  end
end
