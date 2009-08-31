class Gemstone < MyGameObject
  attr_reader :rect, :type, :score, :weight, :status

  gemtype = Struct.new(:name, :score, :weight, :color)
  @@gem_types = Hash.new
  @@gem_types[:emerald] = gemtype.new(:emerald, 10, 10, Color.new(0xFF00FF00))
  @@gem_types[:ruby] = gemtype.new(:ruby, 15, 20, Color.new(0xFFFF0000))
  @@gem_types[:topaz] = gemtype.new(:topaz, 20, 30, Color.new(0xFFB73C23))
  @@gem_types[:opal] =  gemtype.new(:opal, 30, 40, Color.new(0xFFB73C23))
  @@gem_types[:diamond] = gemtype.new(:diamond, 50, 50, Color.new(0xFFF8AFFF))

  def self.gem_types
    @@gem_types.keys
  end
  
  def initialize(options)
    super
    @type = options[:type] || :emerald
    
    @color = @@gem_types[@type].color
    @score = @@gem_types[@type].score
    @weight = @@gem_types[@type].weight
    
    @center_x = 0.5
    @center_y = 1.0
    @image = Image["gem.png"]
    @rect = Rect.new(@x, @y, @image.width, @image.height)
    @status = :default
  end  
end

class Stalactite < MyGameObject
  def initialize(opions)
    super
    @color = Color.new(255,150,150,150)
    @width = 2
    @height = 4

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


class CavernText < Chingu::Text
  def initialize(text = "no-text :/")
    super(:text => text, :x => 100, :y => 200)
  end
  
  def update(time)
    self.zoom(0.005)
    self.fade(-1)     #  if ($window.ticks % 2) == 0
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
