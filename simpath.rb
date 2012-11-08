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
########################################
# mate
########################################
class Mate
  #### new ####
  def initialize
    @edge = nil
    @mate = Hash.new(nil)
  end

  #### look ####
  def look(i)
    @mate[i]
  end

  #### add node i ####
  def add_node(i)
    @mate[i] = i if @mate[i] == nil
  end

  #### remove node i ####
  def delete_terminal_node(i)
    if @mate[i] == 1 && @mate[1] == i && @mate.size == 2
      true
    else
      false
    end
  end
  def delete_node(i)
    if @mate[i] == nil || @mate[i] == i || @mate[i] == 0
      v = true
    else
      v = false
    end
    if i == 1
      !v
    else
      @mate.delete(i)
      v
    end
  end

  #### add edge e = [i, j] as v####
  def add_edge(e, v)
    @edge = e

    #### set as 0 ####
    return true if v == 0

    #### set as 1 ####
    i = e[0]
    j = e[1]

    #### unaddable ####
    return false if @mate[i] == 0 || @mate[j] == 0  # no path
    return false if @mate[i] == j && @mate[j] == i  # cycle

    #### unaddable ####
    add_node(i)
    add_node(j)

    # new pair
    if @mate[i] == i && @mate[j] == j
      @mate[i] = j
      @mate[j] = i

    # extend path
    elsif @mate[i] == i || @mate[j] == j
      # i is a new end point
      if @mate[j] == j
        t = i
        i = j
        j = t
      end

      #
      @mate[i] = @mate[j]
      @mate[ @mate[i] ] = i
      @mate[j] = 0

    # connect paths
    else
      a = @mate[i]
      b = @mate[j]
      @mate[a] = b
      @mate[b] = a
      @mate[i] = 0
      @mate[j] = 0
    end

    return true
  end

  #### to key (string) ####
  def to_key
    key = @mate.keys.sort.map{|key| "#{key}:#{@mate[key]};" }.join
    key = "#{@edge[0]}:#{@edge[1]}+" + key if @edge != nil
    key
  end

  #### set hash [key, val] ####
  def set(key, val)
    @mate[key] = val
  end

  #### clone ####
  def clone
    m = Mate.new
    @mate.keys.each do |key|
      m.set(key, @mate[key])
    end
    m
  end

  #### show ####
  def show
    p @mate
  end

  #### path? ####
  def path?(s, t)
    return false if @mate.size != 2

    if @mate[s] == t && @mate[t] == s
      true
    else
      false
    end
  end
end

########################################
# node of ZDD
########################################
class Node
  #### new ####
  def initialize(edge, mate)
    @edge = edge
    @mate = mate
    @child = [nil, nil]
  end

  #### getters ####
  attr_reader :edge, :mate, :child
  def key
    @mate.to_key
  end
  def clone_mate
    @mate.clone
  end

  #### setters ####
  def set_child(val, node)
    @child[val] = node
  end
  def set_edge(edge)
    @edge = edge
  end

  #### show ####
  def show
    p @edge
    @mate.show
    puts "0-child : #{@child[0]}"
    puts "1-child : #{@child[1]}"
  end
end

########################################
# mate hash
########################################
class MateHash
  #### new ####
  def initialize
    @hash = Hash.new(nil)
  end

  #### member? ####
  def member?(key)
    if @hash[key] == nil
      false
    else
      true
    end
  end

  #### add node ####
  def add_node(n)
    add(n.key, n)
  end
  def add(key, n)
    @hash[key] = n if !member?(key)
  end

  #### get node ####
  def get_node(key)
    @hash[key]
  end

  # show
  def show
    @hash.keys.each do |key|
      puts "----------------------------------------"
      puts "#{key} : #{@hash[key]}"
      @hash[key].show
      puts "----------------------------------------"
    end
  end
end

########################################
# simpath
########################################
class Simpath
  #### new ####
  def initialize(n)
    @n = n # # nodes
    @mh = MateHash.new  #
    @r = Node.new([1,2], Mate.new)       # root node
    @mh.add_node(@r)
    @nl = [ @r ]

    # generate edges
    @ea = []       # edge ary
    @eh = Hash.new # edge hash

    id = 0
    e = [0, 1]
    for i in 1..2 * (@n-1)
      if i < @n
        m = 2 * i
      else
        m = 2 * (2*(@n-1) - i + 1)
      end

      for j in 1..m
        if j == 1
          e[0] += 1
          e[1] += 1
        elsif (i < @n && j % 2 == 0) || (i >= @n && j % 2 == 1)
          e[1] += 1
        else
          e[0] += 1
        end

        #
        @ea.push(e.clone)
        @eh["#{e[0]}:#{e[1]}"] = id
        id += 1
      end
    end
  end

  #### show ####
  def show
    p @n
    @mh.show
  end

  #### open ####
  def open
    return false  if @nl.size == 0

    n = @nl.shift      # node
    ce = n.edge        # current edge
    ne = next_edge(ce) # next edge

    #### v-child ####
    for v in 0..1
      m = n.clone_mate

      # add current edge as v
      t = m.add_edge(ce, v)

      # delete node from mate if needed
      t = m.delete_node(ce[0]) if t == true && (ne == nil || ce[0] != ne[0])

      # last node
      if t == false || m.look(1) == 0
        ch = "0"
      elsif ne == nil
        if m.path?(1, @n**2)
          ch = "1"
        else
          ch = "0"
        end
      else
        if @mh.member?(m.to_key)
          ch = @mh.get_node(m.to_key)
          ch.set_edge(ne)
        else
          ch = Node.new(ne, m)
          @mh.add_node(ch)
        end
        @nl.push(ch)
      end

      # set as child
      n.set_child(v, ch)
    end

    if @nl.size > 0
      true
    else
      false
    end
  end

  #### next edge ####
  def next_edge(e)
    id = @eh["#{e[0]}:#{e[1]}"]
    if id == @ea.size-1
      nil
    else
      @ea[id + 1]
    end
  end

  #### count up ####
  def count_up
    count_up_node(@r)
  end
  def count_up_node(n)
    if n == "1"
      1
    elsif n == "0"
      0
    else
      count_up_node(n.child[0]) + count_up_node(n.child[1])
    end
  end
end

################################################################################
# main
################################################################################
s = Simpath.new(@n)
i = 1
while s.open
end
# s.show
p s.count_up
