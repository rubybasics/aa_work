require './pieces'
require 'colorize'
require './checker_errors.rb'
class Board
  attr_accessor :cursor
  
  def initialize(board = nil)
    if board.nil?
      @board = build_game_board 
    else
      @board = board
    end

    @cursor = [0,0]
  end
  
  def dup
    dup_game_board = Array.new(8){Array.new(8)}
    dup_game_board.each_with_index do |row, row_index|
      row.each_with_index do |item, col_index|
        piece = @board[row_index][col_index] 
        if piece
          dup_game_board[row_index][col_index] = piece.class.new(piece.color)
        end
      end
    end
    
    Board.new(dup_game_board)
  end
  
  def build_game_board
    @board = Array.new(8){Array.new(8)}
    add_color_pieces(:white)
    add_color_pieces(:black)
    #create and place the pieces on the squares
  end
  
  def move_cursor(dir)
    case dir
    when :up
      @cursor[1] -= 1 unless @cursor[1] == 0
    when :down
      @cursor[1] += 1 unless @cursor[1] == 7
    when :left
      @cursor[0] -= 1 unless @cursor[0] == 0
    when :right
      @cursor[0] += 1 unless @cursor[0] == 7
    end
  end
  
  def display
    display_string = "  0 1 2 3 4 5 6 7\n"
    color = [:white, :black]
    string_builder = Proc.new do |row_idx, col_idx, piece|
      
      display_string << "#{row_idx} " if col_idx.zero?

      square = "  " #empty space
      
      if([row_idx, col_idx] == @cursor)
        square = "\u261d ".green
      else
        if dark_square?(row_idx, col_idx)
          square = piece.mark if piece
        end
      end
      
      if dark_square?(row_idx, col_idx)
        display_string << square.on_blue
      else
        display_string << square.on_magenta
      end
      
      display_string << "\n" if col_idx == 7
    end
    do_for_every_square(&string_builder)
    puts display_string
  end
  
  def play_sequence(sequence, color)
      execute_sequence_raw(sequence, color)
  end
  
  def execute_sequence_raw(sequence, color, board = self)
    sequence.each_index do |index|
      break if index == sequence.length - 1
      
      move_type = get_move_type(sequence[index], sequence[index + 1])
      piece = get_piece(sequence[index])
      raise InvalidSequenceError.new unless piece
      raise WrongColorError.new if piece.color != color
      
      if move_type == :slide
        if(index == 0) #only the first may be a slide
          board.slide(sequence[index], sequence[index + 1])
          raise InvalidSequenceError.new if sequence.length > 2
          return
        else
          raise InvalidSequenceError.new
        end
      elsif move_type == :jump
        board.jump(sequence[index], sequence[index + 1])
      end
    end
  end
  
  def sequence_valid?(sequence, color)
      execute_sequence_raw(sequence, color, self.dup)
  end
    

  def dark_square?(row_idx, col_idx)
    (row_idx.even? && col_idx.odd?)||(row_idx.odd? && col_idx.even?)
  end
  
  def jump(start_loc, end_loc)
    jumps = get_piece(start_loc).get_valid_jumps(self)
    puts "jump from #{start_loc.inspect} to #{end_loc.inspect}" 
    puts "my valid jumps #{jumps}" 
    raise InvalidJumpError.new unless jumps.include?(end_loc)
    
    victim_location = get_jump_victim_loc(start_loc, end_loc)
    puts "victim at #{victim_location.inspect}"
    @board[victim_location[0]][victim_location[1]] = nil
    
    move_raw(start_loc, end_loc)
  end
  
  def slide(start_loc, end_loc)
    piece_to_slide = get_piece(start_loc)
    puts "slide from #{start_loc.inspect} to #{end_loc.inspect}"
    raise PendingJumpsError.new if has_forced_jumps?(piece_to_slide.color)
    
    slides = piece_to_slide.get_valid_slides(self)
    puts "valid slides #{slides.inspect}"
    if slides.include? end_loc
      move_raw(start_loc, end_loc) 
    else
      raise InvalidSlideError.new
    end
  end
  
  def get_loc(piece_to_find)
    location = nil
    piece_finder = Proc.new do |row_idx, col_idx, piece|
      if piece.object_id == piece_to_find.object_id
        location = [row_idx, col_idx]
      end
    end
    do_for_every_square(&piece_finder)
    location
  end
  
  def has_forced_jumps?(color)
    !forced_jumps_for_color(color).empty?
  end
  
  def forced_jumps_for_color(color)
    team = get_entire_color(color)
    jumps = []
    jumps.tap do |forced_jumps| #in form [[start_loc, end_loc]]
      team.each do |piece|
      
        piece_jumps = piece.get_valid_jumps(self)
      
        next if piece_jumps.count.zero?
        
        piece_jumps.each do |dest|
          forced_jumps << [get_loc(piece), dest]
        end
      end
    end
  end
  
  
  def get_piece(location)
    @board[location[0]][location[1]]
  end
  
  def move_raw(start_loc, end_loc)
    piece_to_move = get_piece(start_loc)
    @board[start_loc[0]][start_loc[1]] = nil
    @board[end_loc[0]][end_loc[1]] = piece_to_move
    promote_piece(piece_to_move)
  end
  
  private
  
  def promote_piece(piece)
    piece_pos = get_loc(piece)
    
    king_row = piece.color == :black ? 0 : 7
    if get_loc(piece)[0] == king_row
      puts "HAIL TO THE KING!!!"
      @board[piece_pos[0]][piece_pos[1]] = King.new(piece.color)
    end
  end
  
  def get_move_type(start_loc, end_loc)
    distance = (start_loc[0] - end_loc[0]).abs
    if(distance == 1)
      :slide
    elsif(distance == 2)
      :jump
    else
      raise InvalidSequenceError
    end
  end
  
   
  def get_entire_color(color)
    @board.flatten.compact.select do |piece|
      piece.color == color
    end
  end
  
  def do_for_every_square(&prc)
    @board.each_with_index do |row, row_index|
      row.each_with_index do |square, col_index|
        prc.call(row_index, col_index, square)
      end
    end
  end
  
  def add_color_pieces(color)
    rows_of_pieces = color == :white ? (0..2) : (5..7)
    
    piece_setter = Proc.new do |row_idx, col_idx, square|
      if(dark_square?(row_idx, col_idx) && rows_of_pieces.include?(row_idx))
        @board[row_idx][col_idx] = Piece.new(color)
      end
      
    end
    
    do_for_every_square &piece_setter
  end
  
  def get_jump_victim_loc(jump_start, jump_end)
    row = (jump_start[0] + jump_end[0]) / 2
    col = (jump_start[1] + jump_end[1]) / 2
    [row, col]
  end
  
end