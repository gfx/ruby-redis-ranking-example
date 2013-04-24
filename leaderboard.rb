#!/usr/bin/env ruby
# use Ruby 2.0.0

require 'redis'
require 'pp'

class Leaderboard

    class Entry
        attr_reader :user_id, :score, :rank
        def initialize(user_id, score, rank)
            @user_id = user_id
            @score   = score
            @rank    = rank
        end

        def inspect
            "#<#{self.class} user_id:#{user_id}, score:#{score}, rank:#{rank}>"
        end
    end

    def initialize(id, user_id)
        @r = Redis.new
        @id = id
        @user_id = user_id
    end

    def _add(user_id, score)
        @r.zadd @id, score, user_id
    end

    def add(score)
        @r.zadd @id, score, @user_id
    end

    def get_score
        @r.zscore @id, @user_id
    end

    def get_rank
        @r.zrank @id, @user_id
    end

    def get_range(start, count)
        @r.zrange(@id, start, start + count, with_scores: true).map.with_index do |pair, i|
            Entry.new *pair, start + i + 1
        end
    end

    def get_current_page_num(num_per_page)
        (get_rank / num_per_page).floor
    end

    def get_page(page_num, num_per_page)
        get_range page_num * num_per_page, num_per_page
    end

    def get_current_page(num_per_page)
        get_page get_current_page_num(num_per_page), num_per_page
    end
end

# example code

l = Leaderboard.new "ranking", "bar"

8.times do |i|
    l._add "foo#{i}", 100 + i
end

8.times do |i|
    l._add "baz#{i}", 300 + i
end

l.add 200

p l.get_score
p l.get_rank
p l.get_current_page_num 5

puts "current_page:"
pp l.get_current_page 5

puts "page 0, 1, 2:"
pp l.get_page 0, 5
pp l.get_page 1, 5
pp l.get_page 2, 5

