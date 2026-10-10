# frozen_string_literal: true
require 'json'

module MyApp
  class User < ApplicationRecord
    attr_accessor :name

    VERSION = '1.2.3'
    MAX_RETRIES = 10

    def initialize(name, email = "test@example.com")
      @name = name.to_s.strip
      @email = email
      @count = 0x1F + 0b1010 + 1_000_000 + 1.5e3
      @@instances ||= []
    end

    def to_json(*args)
      { name: @name, email: @email }.to_json
    end

    def self.find(id)
      return nil unless id

      user = all.find { |u| u.id == id }
      raise ArgumentError, "not found: #{id}" unless user
      user
    end

    private

    def format_name(prefix = ">>")
      "#{prefix} #{@name}!" + `echo #{@name}`
    end
  end
end

# Комментарий по-русски: переменная сумма
sum = numbers.reduce(0) { |acc, n| acc + n }
puts "Сумма: #{sum}", :sym, :"quoted sym", 3.14r, 1i
str = %w[a b c].map(&:upcase).join(", ")
regexp = /^\d{2}-\d{2}$/
x = a ? b : c
hash = { "key" => :value, other: 42 }
arr = [1, 2, 3].select { _1.odd? }

=begin
multi-line
documentation block
=end

__END__
after end
