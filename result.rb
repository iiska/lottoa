class Result
  attr_accessor :round, :date, :numbers, :extra_numbers

  def initialize(opts)
    self.round = opts[:round]
    self.date = opts[:date]
    self.numbers = opts[:numbers]
    self.extra_numbers = opts[:extra_numbers]
  end
end
