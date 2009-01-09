#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'lotto_parser'

parser = LottoParser.new('2008')

jakauma = {}

parser.results.each{|r|
  r.numbers.each{|i|
    jakauma[i] = 0 if !jakauma[i]
    jakauma[i] += 1
  }
  r.extra_numbers.each{|i|
    jakauma[i] = 0 if !jakauma[i]
    jakauma[i] += 1
  }
}

sorted = jakauma.sort{|a,b| b[1] <=> a[1]}

puts "Vuoden #{parser.year} tiheimmin esiintyneet numerot"
sorted[0,10].each{|n|
  puts "#{n[0]}:\t#{n[1]} kertaa\t=\t#{"%.2f" % (n[1].to_f / parser.results.size * 100)}%"
}

selected_row = sorted[0,7].sort{|a,b| a[0].to_i <=> b[0].to_i}.map{|i|i[0]}

puts "\nSuosituimmista koottu rivi: " + selected_row.join(' ')

total = parser.results.inject(0.0){|sum,r|
  a = r.numbers & selected_row
  if a
    n = a.size
  else
    n = 0
  end
  a = r.extra_numbers & selected_row
  if a
    e = a.size
  else
    e = 0
  end
  sum += parser.winshares[r.round].money?(n,e)
}

puts "Tulos vuoden pelaamisen jälkeen: %.2f€" % total
