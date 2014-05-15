class Asteroid
  attr_reader :angle, :speed, :x, :y, :width, :height

  def initialize(window)
    @window         = window
    @width          = 33
    @height         = 36
    @frame          = 0
    @idle           = Gosu::Image.load_tiles(@window,
                                             "media/img/asteroid-sprite.png",
                                             @width, @height, true)
    @speed          = 3
    @x              = 0
    @y              = rand(@window.height)
    @angle          = @y < @window.height/2 ? rand(90..120) : rand(60..90)
  end

  def dx; Gosu.offset_x(angle, speed); end
  def dy; Gosu.offset_y(angle, speed); end

  def draw
    @frame += 1
    image = @idle[@frame/10 % @idle.size]

    @x = (@x > @window.width ? 0 : @x)
    @y = ((@y > @window.height || @y < 0) ? 0 : @y)

    @x += dx + Math.cos(Time.now.to_f)
    @y += dy + Math.sin(Time.now.to_f)

    image.draw(@x, @y, 1)
  end
end
