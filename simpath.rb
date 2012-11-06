#!/usr/bin/env ruby

################################################################################
# default
################################################################################
@n = 3

################################################################################
# Arguments
################################################################################
require "optparse"
OptionParser.new { |opts|
  # options
  opts.on("-h","--help","Show this message") {
    puts opts
    exit
  }
  opts.on("-n [int]"){ |f|
    @n = f.to_i
  }
  # parse
  opts.parse!(ARGV)
}

################################################################################
# Class
################################################################################
class MyGraph
  def initialize(file)
    @file = file
    @id = Hash.new(0)
    @od = Hash.new(0)
    @e = Hash.new(nil)

    open(@file).read.split(/\n/).each do |line|
      line.gsub!(/ /, "")
      if line.index("--") != nil
        e = line.split("--").map{|i| i.to_i}
        s = e[0]
        t = e[1]

        add_edge(s, t)
        add_edge(t, s)
      end
    end

    @n = (@id.keys + @od.keys).sort.uniq
  end
  attr_reader :id, :od, :e, :n

  # add dedge
  def add_edge(s, t)
    @e[s] = [] if @e[s] == nil
    @e[s].push(t)
    @od[s] += 1
    @id[t] += 1
  end

  # size of graph
  def size
    @n.size
  end

  # list of to
  def endings_of(n)
    @e[n]
  end
  def startings_of(n)
    s = []
    @n.each do |m|
      s += [m] if @e[m].index(n) != nil
    end
    s
  end

  # show
  def show
    puts "node id, in digree, out digree, terminals"
    @n.each do |n| 
      puts "#{n} #{@id[n]} #{@od[n]} #{@e[n]}"
    end
  end
end

class MyCNF
  def initialize(g, s, t)
    @id = Hash.new(nil)
    @s = s
    @t = t
    @g = g

    @cnf = []

    (g.n).each do |n|
      e = g.endings_of(n)
      e.each do |m|
        v = edge2var(n, m)
        i = var2id(v)
        puts "#{v} #{i}"
      end

      s = g.startings_of(n)
      s.each do |m|
        v = edge2var(m, n)
        i = var2id(v)
        puts "#{v} #{i}"
      end
    end
  end

  def edge2var(i, j)
    "e#{i},#{j}"
  end
  def var2id(str)
    @id[str] = @id.size+1 if @id[str] == nil
    @id[str]
  end
  def edge2id(i, j)
    var2id( edge2var(i, j) )
  end
end

################################################################################
# main
################################################################################
g = MyGraph.new("g33.dot")
g.show

c = MyCNF.new(g, 0, g.size-1)
