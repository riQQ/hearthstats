class UniqueDeckType < ActiveRecord::Base
  attr_accessible :match_string, :archtype_id, :name, :klass_id

  ARCHTYPES = {
    1 => "Aggro",
    2 => "Control",
    3 => "Combo",
    4 => "Midrange",
    5 => "Other"
  }
  ### ASSOCIATIONS:

  has_many :unique_decks

  ### CLASS METHODS:

  def self.get_type_popularity(time_ago)
    arche = {}
    Match.where{created_at >= time_ago.hours.ago}.preload(:deck).preload(:unique_deck).find_each do |match|
      next if match.try(:deck).try(:unique_deck).try(:unique_deck_type_id).nil?
      match_arch = arche[match.try(:deck).try(:unique_deck).try(:unique_deck_type).try(:name)]
      if match_arch.nil?
        arche[match.try(:deck).try(:unique_deck).try(:unique_deck_type).try(:name)] = 1
      else
        arche[match.try(:deck).try(:unique_deck).try(:unique_deck_type).try(:name)] += 1
      end
    end
    arche.reject {|name, count| count < 10 || name == nil}
    tot = arche.values.sum
    arche.update(arche){|type, wins| wins.to_f/tot * 100 }
  end

  def self.find_type(klass_id, cardstring)
    klass_types = where(klass_id: klass_id)
    return nil if klass_types.count == 0
    klass_types.each do |deck_type|
      return deck_type.id if match_type(cardstring, deck_type)
    end
  end


  def self.match_type(cardstring, deck_type)
    return nil if deck_type.match_string.nil?
    match_array = deck_type.match_string.split(",")
    matched = true
    match_array.each do |card_id|
      has_card = cardstring.include? card_id
      if !has_card
        matched = false and return
      end
    end

    matched
  end

  def self.find_from_log(args)
    user = args[:user]
    return if args[:log].nil?
    logfile = JSON.parse args[:log]
    if logfile["firstPlayerName"] == user
      playerid = logfile["firstPlayer"] 
    else
      playerid = logfile["secondPlayer"]
    end
    card_array = []
    logfile["turns"][0]["actions"].each do |card|
      if card["player"] == playerid
        card_array << Card.find_by_name(card["card"]).try(:id) unless card["card"].blank?
      end
    end
    opp_cardstring = card_array.join(",")
    self.find_type(args[:klass_id], opp_cardstring)

  end
end
