#
# Most in game objects are based this clss
# Provides simple x/y movement, status, animation etc.
#
require 'set'
class MyGameObject < Chingu::GameObject
  attr_reader :rect, :height, :width, :energy
  attr_accessor :status, :zorder
  
  def initialize(options)
    super(options.merge({:debug => false}))
    @center_y = 1
    @velocity = 0
    @velocity_x = 0
    @velocity_y = 0
    @status = :default
    @attached_objects = Set.new
  end

  def attach(object)
    @attached_objects << object
    object.status = :attached
  end
  
  def dead?
    @status == :dead
  end
  
  def hit_by(power)
    @energy -= power
    self.die!  if @energy < 0
    #puts "Hit by #{power}, energy: #{@energy}"
  end
  
  def die!
    @status = :dead
    @velocity_y = 0
    @velocity_x = 0

    @attached_objects.each do |attached_object|
      attached_object.status = :default
      attached_object.y = parent.floor_y
    end
    @attached_objects.clear
  end
  
  def done_digging
    if rand(2) == 0
      move_left
    else
      move_right
    end
    @dig_at = rand($window.width)
  end
  
  def move_right
    @velocity_x = @velocity
    @status = :moving
  end
  
  def move_left
    @velocity_x = -@velocity
    @status = :moving
  end
 
 def update
    @x += @velocity_x
    @y += @velocity_y

    @attached_objects.each do |attached_object| 
      attached_object.x = self.x
      attached_object.y = self.y - attached_object.image.height/2 + 4
      attached_object.zorder = self.zorder + 1
      attached_object.update
    end

    self.fade(-1) if @status == :dead

    if defined?(@rect)
      @rect.x = @x
      @rect.y = @y
    end
    
    if defined?(@animation) && @animation
      @image = @animation.next! 
    end
    
    if @velocity_x < 0
      @factor_x = -1
    elsif @velocity_x > 0
      @factor_x = 1
    end
    
    super
  end  
end
