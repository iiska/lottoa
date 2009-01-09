# -*- coding: utf-8 -*-
require 'rubygems'
require 'net/http'
require 'net/https'
require 'hpricot'
require 'uri'

require 'result'
require 'win_share'


class LottoParser
  attr :results
  attr :winshares
  attr :year

  def initialize(year)
    @year = year
    @results = []
    @winshares = {} # kierros => WinShare

    @url = URI.parse('https://www.veikkaus.fi/tuloshaku')
    @http = Net::HTTP.new(@url.host, @url.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    self.create_results(self.initial_results_page)
    self.create_winshare_list(self.initial_winshare_page)
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

  def initial_winshare_page
    req = Net::HTTP::Post.new(@url.path)
    req.set_form_data({ 'Z_ACTION' => 'Hae+voitonjaot',
                        'game' => 'lotto',
                        'op' => 'results',
                        'type' => 'year_winshares',
                        'year' => self.year }) # Vuosi parametrein myöhemmin
    @http.request(req).body
  end

  def next_page(path)
    req = Net::HTTP::Get.new(path)
    @http.request(req).body
  end

  def parse(elem, &block)
    (elem/'div#content/table.results/tbody/tr').each &block
  end

  def create_results(response)
    # Parsin single results page
    doc = Hpricot.parse(response)
    if (doc/('div#content/h2[text()="Lotto - Oikeat rivit '+self.year+'"]')).size == 0
      return
    end
    self.parse(doc){|row|
      @results.push(Result.new({
                                :round => (row/'td:nth(1)').inner_text,
                                :date => (row/'td:nth(2)').inner_text,
                                :numbers => (row/'td:nth(4)').inner_text.split,
                                :extra_numbers => (row/'td:nth(5)').inner_text.split
                              }))
    }

    link = doc/'div.commands/ul/li/a[text()="Seuraava >>"]'
    if link
      self.create_results(self.next_page(link.attr('href')))
    end
  end

  def create_winshare_list(response)
    doc = Hpricot.parse(response)
    if (doc/('div#content/h2[text()="Lotto - Voitonjaot '+self.year+'"]')).size == 0
      return
    end
    re = Regexp.new("^(.*)<br />",true)
    f = lambda{|v|
      s = re.match(v)[1]
      s = s.gsub(',','.')
      s.gsub(/[^0-9.]/,'').to_f
    }
    self.parse(doc){|row|
      round = (row/'td:nth(1)').inner_text
      @winshares[round] = WinShare.new({
                                         "7" => f.call((row/'td:nth(3)').inner_html),
                                         "6+1" => f.call((row/'td:nth(4)').inner_html),
                                         "6" => f.call((row/'td:nth(5)').inner_html),
                                         "5" => f.call((row/'td:nth(6)').inner_html),
                                         "4" => f.call((row/'td:nth(7)').inner_html)
                                       })
    }

    link = doc/'div.commands/ul/li/a[text()="Seuraava >>"]'
    if link
      self.create_winshare_list(self.next_page(link.attr('href')))
    end
  end
end
