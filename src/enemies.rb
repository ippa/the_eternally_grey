class Miner < MyGameObject  
  def initialize(options)
    super
    @height = 32
    @width = 32
    @energy = 50
    
    @dig_at = options[:dig_at] || rand($window.width) ##$window.width/2 + 100 - rand(200)
    
    @animations = Hash.new
    @animations[:full] = Animation.new(:file => media_path("miner.png"), :height => @height, :width => @width, :delay => 70)
    @animations[:stopped] = @animations[:full].new_from_frames(0..1)
    @animations[:moving] = @animations[:full].new_from_frames(0..3)
    @animations[:dead] = Animation.new(:file => media_path("miner_dying.png"), :height => @height, :width => @width, :delay => 70, :loop => false, :bounce => false)
    @animations[:digging] = Animation.new(:file => media_path("miner_digging.png"), :height => @height, :width => @width, :delay => 400)
    @animations[:digging].on_frame(1) do
      self.parent.digg(self)
      Sample["hack.wav"].play(0.4)
    end
    
    @rect = Rect.new(@x,@y,@height,@width)
    @status = :stopped
    @zorder = 100
    @velocity = 0.5
    
    @animation = @animations[@status]
    @image = @animation.frames.first
  end
    
  #
  # X of the attack (our pickaxe / drill)
  #
  def attack_x
    @x + ((@factor_x > 0) ? 10 : -10)
  end
    
  def dig
    @status = :digging
    @velocity_x = 0
    @velocity_y = 0
  end

  def update(time)
    @animation = @animations[@status]
    
    # Start digging if, Not already digging, on the right place.. and not carrying anything!
    self.dig    if @status != :digging && @x == @dig_at && @attached_objects.empty?
  
    super
  end  
end


class Machine < MyGameObject
  def initialize(options)
    super
    @dig_at = options[:dig_at] || rand($window.width) ##$window.width/2 + 100 - rand(200)
    
    @energy = 1000
    @width = 58
    @height = 45
    
    @animations = Hash.new
    @animations[:full] = Animation.new(:file => media_path("machine.png"), :width => @width, :height => @height, :delay => 80)
    @animations[:moving] = @animations[:full].new_from_frames(0..1)
    @animations[:stopped] = @animations[:full].new_from_frames(0..0)
    @animations[:dead] = Animation.new(:file => media_path("machine_dying.png"), :height => @height, :width => @width, :delay => 70, :loop => false, :bounce => false)
    @animations[:digging] = Animation.new(:file => media_path("machine_digging.png"), :width => @width, :height => @height, :delay => 300)
    @animations[:digging].on_frame(1) do
      self.parent.digg(self)
    end
    
    @image = @animations[:full].frames.first
    @rect = Rect.new(@x,@y,@width,@height)
    @status = :stopped
    @zorder = 99
    @velocity = 0.5
    move_left
  end
  
  def attack_x
    @x + ((@factor_x > 0) ? 24 : -24)
  end
  
  def dig
    Sample["drill.wav"].play(0.5)
    @status = :digging
    @velocity_x = 0
    @velocity_y = 0
  end
  
  def update(time)
    @animation = @animations[@status]
    
    # Start digging if, Not already digging, on the right place.. and not carrying anything!
    self.dig    if @status != :digging && @x == @dig_at && @attached_objects.empty?
    
    super
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
  
  def dead?
    @status == :dead
  end
  
  def hit_by(object)
    if @status == :active
      @image = @animation.next!
      
      if @image == @animation.frames.last
        @status = :finished
        self.parent.spawn_gemstone(object.attack_x, self.y)
      end
      
    end
  end

  def update(time)
    if finished?
      self.fade(-1)
    end
  end
  
  def finished?
    @status == :finished
  end  
end
