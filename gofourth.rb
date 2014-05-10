require "gosu"
require "pstore"
require_relative "levels"
require_relative "rocket"

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
    @idle_song      = Gosu::Song.new(self, "media/audio/idle.aif")
    @play_song      = Gosu::Song.new(self, "media/audio/play.aif")
    @menu_sample    = Gosu::Sample.new(self, "media/audio/menu.wav")
    @correct_sample = Gosu::Sample.new(self, "media/audio/teleport.wav")
    @wrong_sample   = Gosu::Sample.new(self, "media/audio/gameover.wav")
    @win_sample     = Gosu::Sample.new(self, "media/audio/win.wav")
    @timer          = 0
    @level          = 0
    @score          = 0
    @levels         = get_levels
    @colors         = {
      gold: Gosu::Color.rgba(255, 185, 15, 100),
      faded_gold: Gosu::Color.rgba(255, 185, 15, 30),
      purple: Gosu::Color.rgba(125, 38, 205, 100),
      faded_purple: Gosu::Color.rgba(125, 38, 205, 30),
      green: Gosu::Color.rgba(127, 255, 0, 100),
      faded_green: Gosu::Color.rgba(127, 255, 0, 30),
      red: Gosu::Color.rgba(205, 0, 0, 100),
      faded_red: Gosu::Color.rgba(205, 0, 0, 30),
      danger_red: Gosu::Color.rgb(205, 0, 0),
      white: Gosu::Color.rgb(255,255,255)
    }
    @store.transaction(true) do
      @best_score = @store[:best_score] || 0
    end
  end

  def button_down(id)
    close if id == Gosu::KbEscape 
  end

  def update
    case @stage
    when :start
      @idle_song.play(true)
      if button_down?(Gosu::KbReturn)
        @menu_sample.play
        @stage = :play
      end
      reset_best_score if button_down?(Gosu::KbX)
    when :play
      @play_song.play(true)
      @piece.update
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
      title   = image_from_text(self.caption, 60)
      begin_action  = image_from_text("Press ENTER to Begin", 30)
      reset_action = image_from_text("Best: #{@best_score} - Reset (X)", 25)
      title.draw(self.width/2 - title.width/2, 100, 0)
      begin_action.draw(self.width/2 - begin_action.width/2, 160, 0)
      reset_action.draw(10, self.height - 35, 0)
    when :play
      @timer += 1 if @timer < 500
      draw_quads

      @current_level = @levels[@level]

      draw_problem(@current_level[:problem])
      draw_possible_answers(@current_level[:possible_answers])
      draw_timer
      @piece.draw

      @stage = :answer if @timer == 500
    when :answer
      if check_answer(@current_level[:solution_quad])
        @correct_sample.play
        @level += 1
        @score += (501 - @timer) * @level
        @timer = 0
        if @levels[@level]
          @stage = :play
        else
          @win_sample.play
          @stage = :win
        end
      else
        @wrong_sample.play
        @stage = :over
      end
    when :over
      draw_over_stage
    when :win
      draw_win_stage
    end
  end

  private

  def image_from_text(text, font_size)
    Gosu::Image.from_text(self, text, font, font_size)
  end

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
    @menu_sample.play
    @levels = get_levels
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
    @menu_sample.play
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
    LEVELS.shuffle.sample(10)
  end

  def draw_over_stage
    game_over_text = image_from_text("Game Over!", 60)
    game_over_text.draw(self.width/2 - game_over_text.width/2, self.height/2 - game_over_text.height/2 - 50, 0)
    score_text = image_from_text("Score: #{@score}  Best: #{@best_score}", 30)
    score_text.draw(self.width/2 - score_text.width/2, self.height/2 - game_over_text.height/2 + 10, 0)
    main_action_text  = image_from_text("Try Again (R)  Main Menu (M)", 32)
    main_action_text.draw(self.width/2 - main_action_text.width/2, self.height/2 - game_over_text.height/2 + 60, 0)
  end

  def draw_win_stage
    win_text = image_from_text("You Win!", 60)
    win_text.draw(self.width/2 - win_text.width/2, self.height/2 - win_text.height/2 - 50, 0)
    score_text = image_from_text("Score: #{@score}  Best: #{@best_score}", 30)
    score_text.draw(self.width/2 - score_text.width/2, self.height/2 - win_text.height/2 + 10, 0)
    main_action_text  = image_from_text("Play Again (R)  Main Menu (M)", 32)
    main_action_text.draw(self.width/2 - main_action_text.width/2, self.height/2 - score_text.height/2 + 40, 0)
  end
end

Game.new.show