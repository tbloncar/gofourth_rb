require "gosu"

LEVELS = [
  {
    problem: "sqrt(5! + 1)",
    possible_answers: [121, 6, 9, 11],
    solution_quad: 4
  },
  {
    problem: "2 * 2 + 3 * 4 - 5",
    possible_answers: [35, 11, -12, 23],
    solution_quad: 2
  },
  {
    problem: "3^2 * 2 - 4",
    possible_answers: [14, 3, 77, -18],
    solution_quad: 1
  },
   {
    problem: "1^32 - 0!",
    possible_answers: [1, 0, -1, 32],
    solution_quad: 2
  },
   {
    problem: "5! / 2! + 3!",
    possible_answers: [72, 3.5, 66, 99],
    solution_quad: 3
  },
 
]

class Game < Gosu::Window
  attr_reader :font

  def initialize
    super(500, 350, false)
    self.caption = "GoFourth"

    @piece_width    = 20
    @header_height  = 60
    @quad_width     = self.width/2
    @quad_height    = (self.height - @header_height)/2
    @move_distance  = 10
    @background     = Gosu::Image.new(self, "media/img/background.jpg", true)
    @font           = "media/font/Abel-Regular.ttf"
    @stage          = :start
    @timer          = 0
    @level          = 0
    @score          = 0
    @levels         = LEVELS.shuffle
    @x, @y          = self.width/2 - @piece_width/2, self.height/2 - @piece_width/2 + @header_height/2
    @colors         = {
      gold: Gosu::Color.rgb(255, 185, 15),
      faded_gold: Gosu::Color.rgba(255, 185, 15, 30),
      purple: Gosu::Color.rgb(125, 38, 205),
      faded_purple: Gosu::Color.rgba(125, 38, 205, 30),
      green: Gosu::Color.rgb(127, 255, 0),
      faded_green: Gosu::Color.rgba(127, 255, 0, 30),
      red: Gosu::Color.rgb(205, 0, 0),
      faded_red: Gosu::Color.rgba(205, 0, 0, 30),
      white: Gosu::Color.rgb(255,255,255)
    }
  end

  def button_down(id)
    close if id == Gosu::KbEscape 
  end

  def update
    case @stage
    when :start
      @stage = :play if button_down?(Gosu::KbReturn)
    when :play
      respond_to_piece_movement
      @timer = 500 if button_down?(Gosu::KbReturn) && @timer > 10
    when :answer
      
    when :over
      if button_down?(Gosu::KbR)
        @levels = LEVELS.shuffle
        @level  = 0
        @score  = 0
        @timer  = 0
        @stage  = :play
      end
    end
  end

  def draw
    @background.draw(0, 0, 0)
    case @stage
    when :start
      title   = image_from_text(self.caption, 60)
      action  = image_from_text("Press ENTER to Begin", 36)
      title.draw(self.width/2 - title.width/2, 100, 0)
      action.draw(self.width/2 - action.width/2, 160, 0)
    when :play
      @timer += 1 if @timer < 500
      draw_quads

      @current_level = @levels[@level]

      draw_problem(@current_level[:problem])
      draw_possible_answers(@current_level[:possible_answers])
      draw_piece
      draw_timer

      @stage = :answer if @timer == 500
    when :answer
      if check_answer(@current_level[:solution_quad])
        @level += 1
        @score += 1
        @timer = 0
        if @levels[@level]
          @stage = :play
        else
          @stage = :win
        end
      else
        @stage = :over
      end
    when :over
      game_over_text = image_from_text("Game Over!", 60)
      game_over_text.draw(self.width/2 - game_over_text.width/2, self.height/2 - game_over_text.height/2 - 50, 0)
      score_text = image_from_text("Score: #{@score}", 30)
      score_text.draw(self.width/2 - score_text.width/2, self.height/2 - game_over_text.height/2 + 10, 0)
      action_text  = image_from_text("Press R to Try Again", 36)
      action_text.draw(self.width/2 - action_text.width/2, self.height/2 - game_over_text.height/2 + 60, 0)
    when :win
      win_text = image_from_text("You Win!", 60)
      win_text.draw(self.width/2 - win_text.width/2, self.height/2 - win_text.height/2 - 50, 0)
      score_text = image_from_text("Score: #{@score}", 30)
      score_text.draw(self.width/2 - score_text.width/2, self.height/2 - win_text.height/2 + 10, 0)
    end
  end

  private

  def image_from_text(text, font_size)
    Gosu::Image.from_text(self, text, font, font_size)
  end

  def respond_to_piece_movement
    d = @piece_width + @move_distance
    if button_down?(Gosu::KbRight)
      @x += (@x > self.width - d ? self.width - @piece_width - @x : @move_distance)
    end
    if button_down?(Gosu::KbLeft)
      @x -= (@x < @move_distance ? @x : @move_distance)
    end
    if button_down?(Gosu::KbDown)
      @y += (@y > self.height - d ? self.height - @piece_width - @y : @move_distance)
    end
    if button_down?(Gosu::KbUp)
      @y -= (@y < @move_distance + @header_height ? @y - @header_height : @move_distance)
    end
  end

  def draw_quads
    draw_quad(0, @header_height, @colors[:faded_gold],
              @quad_width, @header_height, @colors[:faded_gold],
              @quad_width, @quad_height + @header_height, @colors[:faded_gold],
              0, @quad_height + @header_height, @colors[:faded_gold])
    draw_quad(@quad_width, @header_height, @colors[:faded_purple],
              self.width, @header_height, @colors[:faded_purple],
              self.width, @quad_height + @header_height, @colors[:faded_purple],
              @quad_width, @quad_height + @header_height, @colors[:faded_purple])
    draw_quad(0, @header_height + @quad_height, @colors[:faded_green],
              @quad_width, @header_height + @quad_height, @colors[:faded_green],
              @quad_width, self.height, @colors[:green],
              0, self.height, @colors[:faded_green])
    draw_quad(@quad_width, @header_height + @quad_height, @colors[:faded_red],
              self.width, @header_height + @quad_height, @colors[:faded_red],
              self.width, self.height, @colors[:faded_red],
              @quad_width, self.height, @colors[:faded_red])
  end

  def draw_problem(problem)
    problem_font_size = 40
    image_from_text("#{problem} = ?", problem_font_size).draw(10, 5, 0)
  end

  def draw_possible_answers(possible_answers)
    answer_font_size = 40
    possible_answers.each_with_index do |a, i|
      answer_image = image_from_text("#{a}", answer_font_size)
      case i
      when 0
        width   = @quad_width/2 - answer_image.width/2
        height  = (@quad_height/2 - answer_image.height/2) + @header_height
      when 1
        width   = @quad_width/2 - answer_image.width/2 + @quad_width
        height  = @quad_height/2 - answer_image.height/2 + @header_height
      when 2
        width   = @quad_width/2 - answer_image.width/2
        height  = @quad_height/2 - answer_image.height/2 + @quad_height + @header_height
      when 3
        width   = @quad_width/2 - answer_image.width/2 + @quad_width
        height  = @quad_height/2 - answer_image.height/2 + @quad_height + @header_height
      end
      answer_image.draw(width, height, 0)
    end
  end

  def draw_piece
    piece_color = get_piece_color
    draw_quad(@x, @y, piece_color,
              @x + @piece_width, @y, piece_color,
              @x, @y + @piece_width, piece_color,
              @x + @piece_width, @y + @piece_width, piece_color)
  end

  def draw_timer
    timer_font_size = 40
    timer_image = image_from_text("#{500 - @timer}", timer_font_size)
    timer_image.draw(440, 5, 0) if @timer < 400
    timer_image.draw(440, 5, 0, 1, 1, @colors[:red]) if @timer >= 400
  end

  def get_piece_color
    return @colors[:gold] if in_quad_1?
    return @colors[:purple] if in_quad_2?
    return @colors[:green] if in_quad_3?
    return @colors[:red] if in_quad_4?
    @colors[:white]
  end

  def check_answer(fourth_with_correct_answer)
    send("in_quad_#{fourth_with_correct_answer}?")
  end

  def in_quad_1?
    @y < (@quad_height + @header_height - @piece_width/2) && @x < (@quad_width - @piece_width/2)
  end

  def in_quad_2?
    @y < (@quad_height + @header_height - @piece_width/2) && @x >= @quad_width
  end

  def in_quad_3?
    @y >= (@quad_height + @header_height) && @x < (@quad_width - @piece_width/2)
  end

  def in_quad_4?
    @y >= (@quad_height + @header_height) && @x >= @quad_width
  end
end

Game.new.show