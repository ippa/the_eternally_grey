#
# LD15 Entry
#
$stderr.sync = $stdout.sync = true
ROOT_PATH = File.dirname(File.expand_path(__FILE__))
$:.unshift(File.join(ROOT_PATH, "lib" ))

require 'rubygems'
require 'chingu'
require 'gosu'
require 'singleton'
require File.join(ROOT_PATH, "src", "core_extensions")

include Gosu

class Game < Chingu::Window
  def initialize
    super(1000,700)
    caption = "The Eternally Grey"
    
    push_game_state(Chingu::GameStates::FadeTo.new(Cavern.new))
    push_game_state(Chingu::GameStates::FadeTo.new(Cavern.new))
    push_game_state(Intro.new)
  end
end


class Menu < Chingu::GameState
  def initialize
    
  end
end

class Intro < Chingu::GameState
  def initialize
    super
    
    @strings = [
      "...mmmnmnnm...hmmm..",    
      "...I'm so tired...",
      "why am I awake? what am I?",
      "...wait, what is this...",
      "...something, a feeling ... ",
      "...I haven't felt in ages...",
    ].reverse
    
    self.input = { :space => :pop_game_state }
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

class Cavern < Chingu::GameState
  def initialize
    super
    @black = Color.new(255,0,0,0)
    @dark_grey = Color.new(255,60,60,60)
    @grey = Color.new(255,100,100,100)
    @light_grey = Color.new(255,140,140,140)
    @ceiling_height = 40
    @floor_y = $window.height - 100   ## 100 pixel thick cave floor
    @cursor = Cursor.new
    
    self.input = {  :g => :spawn_gemstone, 
                    :d => :dig, 
                    :space => :spawn_miner, 
                    :left_ctrl => :spawn_stalactite, 
                    :left_mouse_button => :click }
  end
  
  def dig
    game_objects_of_class(Miner).first.dig
  end
  def spawn_gemstone(x=200, y = @floor_y)
    Gemstone.new(:x => x, :y => y)
  end
  def spawn_miner
    Miner.new(:x => 100, :y => @floor_y)
  end
  def spawn_stalactite
    Stalactite.new(:x => 100 + rand(400)*2, :y => @ceiling_height)
  end
  def spawn_smoke_from(object)
    x = object.rect.centerx + 10 - rand(20)
    y = @floor_y + 10 - rand(20)
    factor = object.power / 1000
    Particle.new(:x => x, :y => y, :image => Image["particle.png"], :fade => -5, :rotation => 10, :zoom => 0.04, :zorder => 100, :mode => :default, :factor => factor)
  end
  
  def click
    game_objects_of_class(Stalactite).each do |stalactite|
      stalactite.activate   if stalactite.rect.collide_point?(@cursor.x, @cursor.y)      
    end
  end
  
  def pickaxe_hit(object)
    Sample["hack.wav"].play(0.2)
    if (crack = game_objects_of_class(Crack).first { |crack| crack.x == object.x })
      crack.advance_crack
    else
      Crack.new(:x => object.x, :y => @floor_y)
    end
  end
  
  def update(time)
    $window.caption = "The Eternally Grey. game objects: #{game_objects.size} - fps #{$window.fps}"
    @cursor.x = $window.mouse_x
    @cursor.y = $window.mouse_y
    
    spawn_stalactite  if rand(100) == 0
    
    game_objects.reject! { |o| (o.outside_window? || o.color.alpha == 0) && o.class != Cursor }
    

    game_objects_of_class(Stalactite).each do |stalactite|
      #
      # Grow them all
      #
      stalactite.grow   if stalactite.status == :default && rand(80) == 0
      
    
      #
      # Rocks hitting the floor
      #
      if (stalactite.y + stalactite.height) > @floor_y && stalactite.y < @floor_y
        Sample["deep_explosion.wav"].play(0.2)  if stalactite.status != :dead
        stalactite.status = :dead
        spawn_smoke_from(stalactite)
        stalactite.x += 4 - rand(8)
      end
      
      #
      # Rocks hitting miners and vehicles
      #
      game_objects_of_class(Miner).each do |miner|
        miner.dig if rand(100) == 1
        if stalactite.rect.collide_rect?(miner.rect)
        end
      end
      
      #
      #
      #

    end
    
    super
  end
  
  def draw
    fill_gradient(:from => @black, :to => @grey)
    fill_gradient(:from => @black, :to => @grey, :rect => [0, @floor_y, $window.width, 100], :zorder => 10)
    fill_gradient(:from => @dark_grey, :to => @light_grey, :rect => [0, 0, $window.width, @ceiling_height], :zorder => 10)
    super
  end
end


class Cursor < Chingu::GameObject
  def initialize
    super
    @center_x = 0
    @center_y = 0
    @zorder = 999
    @image = Image["cursor.png"]
  end
end

class Gemstone < Chingu::GameObject
  attr_reader :rect
  def initialize(options)
    super
    @image = Image["gem.png"]
    @rect = Rect.new(@x, @y, @image.width, @image.height)
  end
end


class Crack < Chingu::GameObject
  attr_reader :status
  
  def initialize(options)
    super
    @animation = Animation.new(:file => media_path("crack.png"), :width => 39, :height => 22, :zorder => 110, :loop => false, :bounce => false, :delay => 0)
    @image = @animation.frames.first
    @center_x = 0.5
    @center_y = 0
    @zorder = 100
    @status = :active
  end
  
  def advance_crack
    if @status == :active
      @image = @animation.next!
      if @image == @animation.frames.last
        @status = :dead
        self.parent.spawn_gemstone(self.x+10, self.y)
      end
    end
  end

  def draw
    @image.draw_rot((@x+10).to_i, @y.to_i, @zorder, @angle, @center_x, @center_y, @factor_x, @factor_y, @color, @mode)
  end
  
end

  
class MyGameObject < Chingu::GameObject
  attr_reader :rect,:height,:width
  attr_accessor :status
  def initialize(options)
    super
    @center_y = 1
    @velocity = 0
    @velocity_x = 0
    @velocity_y = 0
    @status = :default
  end
  
  def move_right
    @velocity_x = @velocity
    @status = :moving
  end
  
  def move_left
    @velocity_x = -@velocity
    @status = :moving
  end
 
 def update(time)
    @x += @velocity_x
    @y += @velocity_y
    @image = @animation.next! if @animation
    @factor_x = (@velocity_x < 0) ? -1 : 1
    super
  end
end


class Miner < MyGameObject
  def initialize(options)
    super
    @animations = Hash.new
    @animations[:full] = Animation.new(:file => media_path("miner.png"), :height => 32, :width => 32, :delay => 70)
    @animations[:stopped] = @animations[:full].new_from_frames(0..1)
    @animations[:moving] = @animations[:full].new_from_frames(0..3)

    @animations[:digging] = Animation.new(:file => media_path("miner_digging.png"), :height => 32, :width => 32, :delay => 300)
    @animations[:digging].on_frame(1) do
      self.parent.pickaxe_hit(self)
    end
    
  
    @rect = Rect.new(0,0,32,32)
    @status = :stopped
    @zorder = 100
    @velocity = 0.5
    move_right
  end
  
  def dig
    @status = :digging
    @velocity_x = 0
    @velocity_y = 0
  end
  
  def update(time)
    @animation = @animations[@status]
    super
  end
end


class Stalactite < MyGameObject
  def initialize(opions)
    super
    @color = Color.new(255,150,150,150)
    @width = 1
    @height = 2

    @velocity = 5
    @zorder = 5
    @rect = Rect.new(@x, @y, @width, @height)
    @status = :default
  end
  
  def power
    @height * @width / 2
  end
  
  def grow
    @width  += 1  if @width  < 40
    @height += 2  if @height < 100
    @rect.width  = @width
    @rect.height = @height
  end
    
  def activate
    @velocity_y = @velocity
    @status = :moving
  end
    
  def draw    
    $window.draw_triangle(  @x, @y, @color, 
                            @x+@width, @y, @color, 
                            @x+@width/2, @y+@height, @color, @zorder, @mode)
    
  end
end

Game.new.show