class Cavern < Chingu::GameState
  attr_reader :floor_y
  
  def initialize
    super
    @black = Color.new(255,0,0,0)
    @dark_grey = Color.new(255,60,60,60)
    @grey = Color.new(255,100,100,100)
    @light_grey = Color.new(255,140,140,140)
    @dark_gold = Color.new(0xFFD1D359)
    @light_gold = Color.new(0xFFF1F412)
    @ceiling_height = 40
    @floor_y = $window.height - 100   ## 100 pixel thick cave floor
        
#    self.input = {  :g => :spawn_gemstone,
#                    :q => :game_over,
#                    :d => :dig,
#                    :f => :drill,
#                    :m => :spawn_machine,
#                    :space => :spawn_miner,
#                    :left_ctrl => :spawn_stalactite,
#                    :left_mouse_button => :click,
#                    :i => :debug,
#                    :esc => :exit }
                    
    self.input = { :left_mouse_button => :click, :esc => :exit}
    @cursor = Cursor.create
    
    @riches = 100
    @score = 0
    @riches_rect = Rect.new(10, 10, @riches, 20)
    @riches_text = Text.create(:text => "Riches: ", :x => 20, :y => 13, :color => Color.new(0xFF000000), :zorder => 1000)
    @score_text = Text.create(:text => "Score: #{@score}", :x => 150, :y => 13, :color => Color.new(0xFFFFFFFF), :zorder => 1000)                    
  end
  
  def setup
    @riches = 100
    @score = 0    
    @first_dig = true
    @first_drill = true
    @first_gem = true
    @milliseconds = milliseconds()
    game_objects.destroy_if { |o| o.is_a?(Miner) || o.is_a?(Machine) || o.is_a?(Gemstone) || o.is_a?(Stalactite)}
    spawn_miner
    5.times { spawn_stalactite }
  end

  def debug
    game_objects_of_class(Gemstone).each do |gemstone|
      puts "#{gemstone.type} - #{gemstone.status}"
    end
  end
  
  def game_over
    switch_game_state(GameOver.new(:score => @score))
  end
  
  def game_state_age
    ((milliseconds() - @milliseconds)/1000).to_i
  end
  
  def dig;    game_objects_of_class(Miner).first.dig; end
  def drill;  game_objects_of_class(Machine).first.dig; end
  def spawn_miner;    spawn_enemy(Miner);   end
  def spawn_machine;  spawn_enemy(Machine); end  
  def spawn_enemy(klass)
    if rand(2) == 1
      klass.create(:x => 0, :y => @floor_y).move_right
    else
      klass.create(:x => $window.width, :y => @floor_y).move_left
    end
  end
  def spawn_stalactite
    Stalactite.create(:x => rand($window.width), :y => @ceiling_height)
  end
  def spawn_gemstone(x=200, y = @floor_y)
    type = Gemstone.gem_types[rand(Gemstone.gem_types.size)]
    Gemstone.create(:x => x, :y => y, :type => type)
  end

  #
  #
  # CORE OF THE GAME LOGIC
  #
  #
  def update
    ## $window.caption = "The Eternally Grey. game objects: #{game_objects.size} - fps #{$window.fps} - seconds: #{game_state_age}"
    @cursor.x = $window.mouse_x
    @cursor.y = $window.mouse_y
    
    # Increases 1 each 10 second
    value = (game_state_age / 10).to_i    
    #if game_objects_of_class(Miner).size < 20
    if Miner.size < 20
      spawn_miner       if (game_state_age > 20) && rand(7 * (60-value)) == 0
    end
    
    #if game_objects_of_class(Machine).size < 6
    if Machine.size < 20
      spawn_machine     if (game_state_age > 120) && rand(7 * (120-value)) == 0
    end

    #if game_objects_of_class(Stalactite).size < 5
    if Stalactite.size < 5
      spawn_stalactite  if rand(100) == 0
    #elsif game_objects_of_class(Stalactite).size < 10
    elsif Stalactite.size < 10      
      spawn_stalactite  if rand(200) == 0
    #elsif game_objects_of_class(Stalactite).size < 20
    elsif Stalactite.size < 20
      spawn_stalactite  if rand(300) == 0
    end


    game_objects.select { |o| o.outside_window? && o.is_a?(Gemstone) }.each do |gemstone|
      @riches -= gemstone.score
      CavernText.create("They stole my beautiful child, #{gemstone.type}. I raised her for #{gemstone.score} years.")
      @riches_rect.width = @riches
      push_game_state(GameOver.new(:score => @score))   if @riches <= 0
    end
    
    game_objects.destroy_if { |o| (o.outside_window? || o.color.alpha == 0) && o.class != Cursor }
    
    fill_gradient(:from => @dark_gold, :to => @light_gold, :rect => @riches_rect, :zorder => 999)
    @riches_text.text = "Riches: #{@riches}"
    @score_text.text = "Score: #{@score}"
    
    game_objects_of_class(Miner).select {|miner| miner.status != :dead}.each do |miner|
      game_objects_of_class(Gemstone).select { |gemstone| gemstone.status != :attached }.each do |gemstone|
        if miner.rect.collide_rect?(gemstone.rect)
          miner.attach(gemstone)
          CavernText.create("They're stealing my loved ones!")  if @first_gem
          @first_gem = false
        end
      end
    end
    
    #
    # Go through all stalactites
    #
    game_objects_of_class(Stalactite).each do |stalactite|
      # Grow all rocks slowly
      stalactite.grow   if stalactite.status == :default && rand(100) == 0
          
      # Rocks hitting the floor
      if (stalactite.y + stalactite.height) > @floor_y && stalactite.y < @floor_y
        Sample["deep_explosion.wav"].play(0.2)  unless stalactite.status != :dead
        stalactite.status = :dead
        spawn_smoke(stalactite.rect.centerx, @floor_y, stalactite.power/500)
        stalactite.x += 4 - rand(8)
      end
      
      # Rocks hitting miners and vehicles
      game_objects.select { |o| (o.is_a?(Miner) || o.is_a?(Machine)) }.each do |enemy|
        if stalactite.rect.collide_rect?(enemy.rect)
          
          @score += [stalactite.power, enemy.energy].min  if enemy.status != :dead
          enemy.hit_by(stalactite.power)
          2.times { spawn_smoke(stalactite.rect.centerx, @floor_y - enemy.rect.height, stalactite.power/800) }
          enemy.rect.y = @floor_y
          Sample["explosion.wav"].play(0.5)
          
          #game_objects.delete(stalactite)
          stalactite.destroy!
        end
      end
    end
    
    super
  end
  
  def spawn_smoke(x, y, factor)
    x += 10 - rand(20)
    y += 10 - rand(20)
    Particle.create(:x => x, :y => y, :image => Image["particle.png"], :fade_rate => -5, :rotation_rate => 10, :scale_rate => 0.04, :zorder => 100, :mode => :default, :factor => factor)
  end
  
  def click
    game_objects_of_class(Stalactite).each do |stalactite|
      stalactite.activate   if stalactite.rect.collide_point?(@cursor.x, @cursor.y) 
    end
  end
  
  def digg(object)
    if (crack = game_objects_of_class(Crack).select { |crack| crack.x == object.attack_x }.first)
      crack.hit_by(object)
      object.done_digging if crack.finished?
    else
      
      if @first_dig && object.is_a?(Miner)
        CavernText.create("... That hurt.")
        @first_dig = false
      end

      if @first_drill && object.is_a?(Machine)
        CavernText.create("... What is this big evil thing?")
        @first_drill = false
      end

      Crack.create(:x => object.attack_x, :y => @floor_y)
    end
  end
  
  def draw
    fill_gradient(:from => @black, :to => @grey)
    fill_gradient(:from => @black, :to => @grey, :rect => [0, @floor_y, $window.width, 100], :zorder => 10)
    fill_gradient(:from => @dark_grey, :to => @light_grey, :rect => [0, 0, $window.width, @ceiling_height], :zorder => 10)
    super
  end
end
