#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'net/http'
require 'net/https'
require 'hpricot'
require 'uri'


class Result
  attr_accessor :round, :date, :numbers, :extra_numbers

  def initialize(opts)
    self.round = opts[:round]
    self.date = opts[:date]
    self.numbers = opts[:numbers]
    self.extra_numbers = opts[:extra_numbers]
  end
end

class LottoParser
  attr :results, true
  attr :year

  def initialize(year)
    @year = year
    self.results = []

    @url = URI.parse('https://www.veikkaus.fi/tuloshaku')
    @http = Net::HTTP.new(@url.host, @url.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    self.create_results(self.initial_results_page)
  end

  def initial_results_page
    req = Net::HTTP::Post.new(@url.path)
    req.set_form_data({ 'Z_ACTION' => 'Hae+tulokset',
                        'game' => 'lotto',
                        'op' => 'results',
                        'type' => 'year_short',
                        'year' => self.year }) # Vuosi parametrein myöhemmin
    @http.request(req).body
  end

  def next_results_page(path)
    req = Net::HTTP::Get.new(path)
    @http.request(req).body
  end

  def create_results(response)
    # Parsin single results page
    doc = Hpricot.parse(response)
    if (doc/('div#content/h2[text()="Lotto - Oikeat rivit '+self.year+'"]')).size == 0
      return
    end
    (doc/'div#content/table.results/tbody/tr').each{|row|
      @results.push(Result.new({
                                :round => (row/'td:nth(1)').inner_text,
                                :date => (row/'td:nth(2)').inner_text,
                                :numbers => (row/'td:nth(4)').inner_text,
                                :extra_numbers => (row/'td:nth(5)').inner_text
                              }))
    }

    link = doc/'div.commands/ul/li/a[text()="Seuraava >>"]'
    if link
      self.create_results(self.next_results_page(link.attr('href')))
    end
  end
end

parser = LottoParser.new('2008')

jakauma = {}

parser.results.each{|r|
  r.numbers.split.each{|i|
    jakauma[i] = 0 if !jakauma[i]
    jakauma[i] += 1
  }
  r.extra_numbers.split.each{|i|
    jakauma[i] = 0 if !jakauma[i]
    jakauma[i] += 1
  }
}

sorted = jakauma.sort{|a,b| b[1] <=> a[1]}

puts "Vuoden #{parser.year} tiheimmin esiintyneet numerot"
sorted.each{|n|
  puts "#{n[0]}: #{n[1]} kertaa = #{"%.2f" % (n[1].to_f / parser.results.size * 100)}%"
}

puts "Suosituimmista koottu rivi: " +
  sorted[0,7].sort{|a,b| a[0].to_i <=> b[0].to_i}.map{|i|i[0]}.join(' ')

# Voitonjakojen haku:
# POST https://www.veikkaus.fi/tuloshaku
# Z_ACTION: Hae+voitonjaot
# game: lotto
# op: results
# type: year_winshares
# year: 2008
