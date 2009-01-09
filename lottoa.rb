#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'lotto_parser'

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
  puts "#{n[0]}:\t#{n[1]} kertaa\t=\t#{"%.2f" % (n[1].to_f / parser.results.size * 100)}%"
}

puts "\nSuosituimmista koottu rivi: " +
  sorted[0,7].sort{|a,b| a[0].to_i <=> b[0].to_i}.map{|i|i[0]}.join(' ')
