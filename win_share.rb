# -*- coding: utf-8 -*-
class WinShare
  # {"7" => n €,
  #  "6+1" => n €}

  def initialize(wins)
    @wins = wins
  end

  def money?(nums,extra)
    if nums == 6 && extra == 1
      w = "6+1"
    else
      w = nums.to_s
    end
    # Cost of a round is 0.80€
    (@wins[w] ? @wins[w] : 0.0) - 0.80
  end
end
