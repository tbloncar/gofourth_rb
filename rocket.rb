class Rocket
  attr_reader :width, :height, :x, :y

  def initialize(window)
    @window         = window
    @width          = 49
    @height         = 49
    @idle           = Gosu::Image.load_tiles(@window,
                                             "media/img/rocket-sprites.png",
                                             @width, @height, true)
    @move_distance  = 10 
    @direction      = :up
    @x, @y          = @window.width/2 - @width/2, @window.height/2 - @height/2 + @window.header_height/2
  end

  def update
    respond_to_movement
  end

  def draw
    set_image 
    @image.draw(@x, @y, 1, 1, 1)
  end

  def in_quad_1?
    @y < (@window.quad_height + @window.header_height - @width/2) && 
      @x < (@window.quad_width - @width/2)
  end

  def in_quad_2?
    @y < (@window.quad_height + @window.header_height - @width/2) &&
      @x >= @window.quad_width
  end

  def in_quad_3?
    @y >= (@window.quad_height + @window.header_height) &&
      @x < (@window.quad_width - @width/2)
  end

  def in_quad_4?
    @y >= (@window.quad_height + @window.header_height) &&
      @x >= @window.quad_width
  end

  def reset_position
    @x, @y = @window.width/2 - @width/2, @window.height/2 - @height/2 + @window.header_height/2
    @direction = :up
  end

  def intersects_with?(o)
    self.x < (o.x + o.width) &&
      (self.x + self.width) > o.x &&
      self.y < (o.y + o.height) &&
      (self.y + self.height) > o.y
  end

  private

  def respond_to_movement
    wd = @width + @move_distance
    hd = @height + @move_distance
    if @window.button_down?(Gosu::KbRight)
      @direction = :right
      @x += (@x > @window.width - wd ? @window.width - @width - @x : @move_distance)
    end
    if @window.button_down?(Gosu::KbLeft)
      @direction = :left
      @x -= (@x < @move_distance ? @x : @move_distance)
    end
    if @window.button_down?(Gosu::KbDown)
      @direction = :down
      @y += (@y > @window.height - hd ? @window.height - @width - @y : @move_distance)
    end
    if @window.button_down?(Gosu::KbUp)
      @direction = :up
      @y -= (@y < @move_distance + @window.header_height ? @y - @window.header_height : @move_distance)
    end
  end

  def set_image
    @image = case @direction
    when :up then @idle[0]
    when :down then @idle[1]
    when :right then @idle[2]
    when :left then @idle[3]
    end
  end
end
