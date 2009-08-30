class Intro < Chingu::GameState
  def initialize
    super
    
    @strings = [
      "...mmmnmnnm...hmmm....I'm so tired...",
      "why am I awake? what am I?",
      "...wait, what is this...",
      "...something, a feeling ... ",
      "...I haven't felt in ages...",
    ].reverse
    
    self.input = { :space => :start_game }
  end
  
  def start_game
    switch_game_state(Cavern.new)
  end
  
  def update(time)    
    game_objects.reject! { |object| object.color.alpha == 0}
    
    if game_objects.size == 0
      if string = @strings.pop
        @text = Text.new(:text => string, :x => 100, :y => 200)
      else
        pop_game_state
      end
    end
    @text.zoom(0.005)
    @text.fade(-1)  if ($window.ticks % 2) == 0
  end
  
  def setup
    Song["the_eternally_grey_1.ogg"].play(true)
  end
  
  def finalize
    Song.current_song.stop
  end
end
