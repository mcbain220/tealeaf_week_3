require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do

  def deck_create

    deck_suits = ["hearts", "spades", "diamonds", "clubs"]

    deck_values = { "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, 
                  "7" => 7, "8" => 8, "9" => 9, "10" => 10, "jack" => 10, 
                  "queen" => 10, "king" => 10, "ace" => 11 }
               
    single_deck = []

    deck_values.each do | key, val |
      deck_suits.each do | suit |
        single_deck << [(suit + "_" + key), val]
      end
    end
    single_deck
  end

  def shuffle(deck)
    3.times {deck.shuffle!}
  end

  def initial_deal(deck, player, dealer)
    2.times do
      player << deck.shift
      dealer << deck.shift
    end
  end

  def hand_value(cards)
    value = 0
    val_arr = []
    cards.each do |sub_array|
        val_arr << sub_array.last
        val_arr.sort!
      end
    val_arr.each do |val|
      if val == 11 && value > 10
        value += 1  
      else
        value += val
      end
    end
    return value
  end
  
  def get_cards(cards)
    cards_array = []
    cards.each do |sub_array|
      cards_array << sub_array.first
    end
    # cards_array.join(" / ")  <--- was originally returning the hand in text form.
    cards_array
  end
      

  def hand_display(cards)
    "#{get_cards(cards)} or #{hand_value(cards)}"
  end

end

get '/' do
  erb :home
end

post '/set_name' do
  if session[:player_name].is_a?(String)
    session[:player_balance] = 1000
    session[:game_deck] = []
    redirect '/player'
  else
    session[:player_name] = params[:player_name]    #this sets the variable into the cookie for cheap persistence
    session[:player_balance] = 1000
    session[:game_deck] = []
    redirect '/player'
  end
end

get '/player' do
  erb :player
end

post '/player' do 
  session[:player_bet] = 0
   
  if params[:player_bet].to_i.is_a?(Integer) && params[:player_bet].to_i > 0 && params[:player_bet].to_i <= session[:player_balance]
    session[:player_bet] = params[:player_bet].to_i
    redirect '/initial_game'
  else
    redirect '/player_bet_error'
  end
end

get '/player_bet_error' do
  @error = "Your bet does not make sense.  Try again!"
  erb :player
end
  
get '/initial_game' do
  if session[:game_deck].length < 20
      session[:game_deck] = deck_create
      shuffle(session[:game_deck])
  end

  session[:dealer_cards] = []
  session[:player_cards] = [] 
  session[:player_stay] = 0
  session[:dealer_stay] = 0
  @resolution = nil
  @update = nil
  initial_deal(session[:game_deck], session[:player_cards], session[:dealer_cards])
  redirect '/game'
end

get '/game' do
  hand_value(session[:player_cards])
  hand_value(session[:dealer_cards])

  if hand_value(session[:player_cards]) <= 21
    erb :game
  else
    session[:player_stay] = 1
    redirect '/dealer_decision'
  end
end

post '/player_decision' do
  # binding.pry
  if params[:hit] == "Hit"
    session[:player_cards] << session[:game_deck].shift
    params[:hit] = nil
    redirect '/game'
  else
    session[:player_stay] = 1
    redirect '/dealer_decision'
  end
end

get '/dealer_decision' do
  erb :game
  
  if hand_value(session[:player_cards]) > 21
    session[:dealer_stay] = 1
    erb :game
  else
    while hand_value(session[:dealer_cards]) < 17
      session[:dealer_cards] << session[:game_deck].shift
      erb :game
    end
  end
  
  session[:dealer_stay] = 1
  redirect '/game_resolution' 
end
    
get '/game_resolution' do
  if hand_value(session[:player_cards]) == 21 && session[:player_cards].length == 2
    @resolution = "BLACKJACK! You win 2x your bet!"
    session[:player_balance] += session[:player_bet] * 2
    @update = "You've won #{session[:player_bet] * 2} - your new balance is: #{session[:player_balance]}"
  elsif hand_value(session[:player_cards]) > 21
    @resolution = "You've busted!  Dealer wins."
    session[:player_balance] -= session[:player_bet]
    @update = "Your new balance is #{session[:player_balance]}."
  elsif hand_value(session[:dealer_cards]) > 21
    @resolution = "Dealer has busted.  You win!"
    session[:player_balance] += session[:player_bet]
    @update = "Your new balance is #{session[:player_balance]}."
  elsif hand_value(session[:dealer_cards]) > hand_value(session[:player_cards])
    @resolution = "Dealer wins!"
    session[:player_balance] -= session[:player_bet]
    @update = "Your new balance is #{session[:player_balance]}."
  elsif hand_value(session[:player_cards]) > hand_value(session[:dealer_cards])
    @resolution = "Player wins!"
    session[:player_balance] += session[:player_bet]
    @update = "Your new balance is #{session[:player_balance]}."
  else
    @resolution = "It's a push!"    
  end
  erb :game
end
  
    



