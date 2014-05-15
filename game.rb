require "gosu"
require "pstore"

require_relative "levels"
require_relative "rocket"
require_relative "asteroid"

class Game < Gosu::Window
  attr_reader :font, :header_height, :quad_width, :quad_height

  def initialize
    super(500, 350, false)
    self.caption = "GoFourth"

    @header_height  = 60
    @quad_width     = self.width/2
    @quad_height    = (self.height - @header_height)/2
    @piece          = Rocket.new(self)
    @background     = Gosu::Image.new(self, "media/img/background.jpg", true)
    @font           = "media/font/Abel-Regular.ttf"
    @stage          = :start
    @store          = PStore.new("scores.pstore") || 0
    @volume         = 1
    @adventure      = 1
    @idle_song      = Gosu::Song.new(self, "media/audio/idle.aif")
    @play_song      = Gosu::Song.new(self, "media/audio/play.aif")
    @menu_sample    = Gosu::Sample.new(self, "media/audio/menu.wav")
    @correct_sample = Gosu::Sample.new(self, "media/audio/teleport.wav")
    @wrong_sample   = Gosu::Sample.new(self, "media/audio/gameover.wav")
    @win_sample     = Gosu::Sample.new(self, "media/audio/win.wav")
    @explode_sample = Gosu::Sample.new(self, "media/audio/explosion.wav")
    @timer          = 0
    @level          = 0
    @score          = 0
    @colors         = {
      gold: Gosu::Color.rgba(255, 185, 15, 100),
      faded_gold: Gosu::Color.rgba(255, 185, 15, 30),
      active_gold: Gosu::Color.rgb(255, 185, 15),
      purple: Gosu::Color.rgba(125, 38, 205, 100),
      faded_purple: Gosu::Color.rgba(125, 38, 205, 30),
      green: Gosu::Color.rgba(127, 255, 0, 100),
      faded_green: Gosu::Color.rgba(127, 255, 0, 30),
      red: Gosu::Color.rgba(205, 0, 0, 100),
      faded_red: Gosu::Color.rgba(205, 0, 0, 30),
      danger_red: Gosu::Color.rgb(205, 0, 0),
      white: Gosu::Color.rgb(255,255,255)
    }
    @asteroids      = []
    @store.transaction(true) do
      @best_score = @store[:best_score] || 0
    end
  end

  def button_down(id)
    close if id == Gosu::KbEscape 
    if id == Gosu::KbS
      @volume = (@volume - 1).abs
      if (song = Gosu::Song.current_song)
        song.volume = @volume
      end
    end
    case @stage
    when :start
      reset_best_score if id == Gosu::KbX
      if id == Gosu::KbReturn
        @menu_sample.play(@volume)
        @stage = :choose
      end
      if id == Gosu::KbC
        @menu_sample.play(@volume)
        @stage = :credits
      end
    when :credits
      go_to_main_menu if id == Gosu::KbM
    when :choose
      if id == Gosu::KbDown 
        @menu_sample.play(@volume)
        @adventure += 1 unless @adventure == LEVELS.keys.count
      end
      if id == Gosu::KbUp
        @menu_sample.play(@volume)
        @adventure -= 1 unless @adventure == 1
      end
      begin_play if id == Gosu::KbReturn
      go_to_main_menu if id == Gosu::KbM
    end
  end

  def update
    case @stage
    when :start
      @idle_song.play(true) unless @volume == 0
    when :play
      @play_song.play(true) unless @volume == 0
      @piece.update
      @asteroids[@level] ||= []
      unless @asteroids[@level].any?
        @level.times do |i|
          unless @asteroids[@level].size == 5
            asteroid = Asteroid.new(self)
            @asteroids[@level] << asteroid
          end
        end
      end
      @asteroids[@level].each { |a|
        if @piece.intersects_with?(a)
          @asteroids[@level] = []
          if @piece.intersects_with?(a) 
            @explode_sample.play(@volume)
            @stage = :over
            @wrong_sample.play(@volume)
          end
        end
      }
      if button_down?(Gosu::KbReturn) && @timer > 10
        @stage = :answer
      end
    when :answer
      
    when :over
      @play_song.stop
      possibly_set_best_score
      restart if button_down?(Gosu::KbR)
      go_to_main_menu if button_down?(Gosu::KbM)
    when :win
      @play_song.stop
      possibly_set_best_score
      restart if button_down?(Gosu::KbR)
      go_to_main_menu if button_down?(Gosu::KbM)
    end
  end

  def draw
    @background.draw(0, 0, 0)
    case @stage
    when :start

      draw_text_centered(self.caption, 60, 100)
      draw_text_centered("Press ENTER to Begin", 30, 160)

      reset_action = image_from_text("Best: #{@best_score} - Reset (X)", 25)
      reset_action.draw(10, self.height - 35, 0)

      other_actions = image_from_text("Sound (S) - Credits (C)", 25)
      other_actions.draw(self.width - 10 - other_actions.width, self.height - 35, 0)

    when :credits

      draw_text_centered("Credits", 40, 30)
      draw_text_centered("developed by shad3 (on the shoulders of giants)", 24, 100)
      draw_text_centered("sound samples by fins / music by unknown", 24, 130)
      draw_back_action

    when :choose

      a1color = a2color = a3color = a4color = @colors[:white]
      case @adventure
      when 1 then a1color = @colors[:active_gold]
      when 2 then a2color = @colors[:active_gold]
      when 3 then a3color = @colors[:active_gold]
      when 4 then a4color = @colors[:active_gold]
      end

      draw_text_centered("Choose Your Adventure", 40, 30)
      draw_text_centered("1. Mathematics", 28, 85, a1color)
      draw_text_centered("2. U.S. Presidents", 28, 125, a2color)
      draw_text_centered("3. English Grammar", 28, 165, a3color)
      draw_text_centered("4. Vehicles", 28, 205, a4color)
      draw_text_centered("Press ENTER to Continue", 30, 260)
      draw_back_action

    when :play

      @timer += 1 if @timer < 500
      draw_quads

      @current_level = @levels[@level]

      draw_problem(@current_level[:problem])
      draw_possible_answers(@current_level[:possible_answers])
      draw_timer
      @piece.draw
      @asteroids[@level].each { |a| a.draw }

      @stage = :answer if @timer == 500

    when :answer

      @asteroids[@level] = []
      if check_answer(@current_level[:solution_quad])
        @correct_sample.play(@volume)
        @level += 1
        @score += (501 - @timer) * @level
        @timer = 0
        if @levels[@level]
          @stage = :play
        else
          @win_sample.play(@volume)
          @stage = :win
        end
      else
        @wrong_sample.play(@volume)
        @stage = :over
      end

    when :over
      draw_over_stage
    when :win
      draw_win_stage
    end
  end

  private

  def draw_quads
    quad_1_color = @piece.in_quad_1? ? @colors[:gold] : @colors[:faded_gold]
    draw_quad(0, @header_height, quad_1_color,
              @quad_width, @header_height, quad_1_color,
              @quad_width, @quad_height + @header_height, quad_1_color,
              0, @quad_height + @header_height, quad_1_color)

    quad_2_color = @piece.in_quad_2? ? @colors[:purple] : @colors[:faded_purple]
    draw_quad(@quad_width, @header_height, quad_2_color,
              self.width, @header_height, quad_2_color,
              self.width, @quad_height + @header_height, quad_2_color,
              @quad_width, @quad_height + @header_height, quad_2_color)

    quad_3_color = @piece.in_quad_3? ? @colors[:green] : @colors[:faded_green]
    draw_quad(0, @header_height + @quad_height, quad_3_color,
              @quad_width, @header_height + @quad_height, quad_3_color,
              @quad_width, self.height, quad_3_color,
              0, self.height, quad_3_color)

    quad_4_color = @piece.in_quad_4? ? @colors[:red] : @colors[:faded_red]
    draw_quad(@quad_width, @header_height + @quad_height, quad_4_color,
              self.width, @header_height + @quad_height, quad_4_color,
              self.width, self.height, quad_4_color,
              @quad_width, self.height, quad_4_color)
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
    timer_image.draw(440, 5, 0, 1, 1, @colors[:danger_red]) if @timer >= 400
  end

  def get_piece_color
    return @colors[:gold] if in_quad_1?
    return @colors[:purple] if in_quad_2?
    return @colors[:green] if in_quad_3?
    return @colors[:red] if in_quad_4?
    @colors[:white]
  end

  def check_answer(fourth_with_correct_answer)
    @piece.send("in_quad_#{fourth_with_correct_answer}?")
  end

  def reset
    @menu_sample.play(@volume)
    get_levels
    @level  = 0
    @score  = 0
    @timer  = 0
    @piece.reset_position
  end

  def restart
    reset
    @stage  = :play
  end

  def possibly_set_best_score
    if @score > @best_score
      @best_score = @score
      @store.transaction do
        @store[:best_score] = @best_score
      end
    end
  end

  def reset_best_score
    @menu_sample.play(@volume)
    @store.transaction do
      @store[:best_score] = 0
      @best_score = 0
    end
  end

  def go_to_main_menu
    reset
    @stage = :start
  end

  def get_levels
    adventure_name = case @adventure
    when 1 then :mathematics
    when 2 then :presidents
    when 3 then :grammar
    when 4 then :vehicles
    end

    @levels = LEVELS[adventure_name].sample(10)
  end

  def begin_play
    get_levels
    @stage = :play
  end

  def draw_over_stage
    draw_text_centered("Game Over!", 60, 100)
    draw_text_centered("Score: #{@score}  Best: #{@best_score}", 30, 160)
    draw_text_centered("Try Again (R)  Main Menu (M)", 32, 200)
  end

  def draw_win_stage
    draw_text_centered("You Win!", 60, 100)
    draw_text_centered("Score: #{@score}  Best: #{@best_score}", 30, 160)
    draw_text_centered("Play Again (R)  Main Menu (M)", 32, 200)
  end

  def draw_back_action
    ba = image_from_text("Back to Menu (M)", 25)
    ba.draw(10, self.height - 35, 0)
  end

  def draw_text_centered(text, font_size, height, color = @colors[:white])
    i = image_from_text(text, font_size)
    i.draw(self.width/2 - i.width/2, height, 0, 1, 1, color)
  end

  def image_from_text(text, font_size)
    Gosu::Image.from_text(self, text, font, font_size)
  end
end

Game.new.show