#!/usr/bin/env ruby

################################################################################
# default
################################################################################
@n = 3
@@one  = -1
@@zero = -2
@@unknown = -3

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
# Graph
################################################################################
class Graph
  #### accessors ####
  attr_reader :n, :s, :t, :e

  #### new ####
  def initialize(_n)
    @n = _n
    @s = 1
    @t = _n
    @e = []
    @a = Array.new(@n){|i| [] }
    @f = Hash.new(nil)
  end

  #### show ####
  def show
    p @e
    p @f
  end

  #### set start/terinal ####
  def set_start(_s)
    @s = _s
  end
  def set_terminal(_t)
    @t = _t
  end

  #### gets ####
  def enum
    @e.size
  end
  def vnum
    @n.size
  end

  #### add edge ####
  def add_edge(_e)
    e = _e.sort
    i = e[0]
    j = e[1]
    @a[i-1].push(j-1)
    @a[j-1].push(i-1)
    @e.push(e)
  end

  #### update ####
  def update
    # update edge order
    @e.sort!{|a, b| (a[0] <=> b[0]).nonzero? || (a[1] <=> b[1])}

    # update frontier diff
    @f.clear
    for i in 0..@n-1
      if (j = @a[i].max) != nil
        e = [i+1, j+1].sort
        @f[e] = [] if @f[e] == nil
        @f[e].push(i+1)
      end
    end
  end

  #### leaving_vertices ####
  def leaving_vertices(_e)
    if @f[_e] == nil
      []
    else
      @f[_e]
    end
  end
end

#### generate grid graph ####
def generate_grid(_n)
  n = _n
  g = Graph.new(n**2)
  g.set_start(1)
  g.set_terminal(n**2)

  id = 0
  e = [0, 1]

  #### generate edges ####
  for i in 1..2 * (n-1)
    if i < n
      m = 2 * i
    else
      m = 2 * (2*(n-1) - i + 1)
    end

    for j in 1..m
      if j == 1
        e[0] += 1
        e[1] += 1
      elsif (i < n && j % 2 == 0) || (i >= n && j % 2 == 1)
        e[1] += 1
      else
        e[0] += 1
      end

      g.add_edge(e)
      id += 1
    end
  end
  g.update
  g
end

################################################################################
# Mate
################################################################################
########################################
# Mate class
########################################
class Mate
  #### accessor ####
  attr_reader :mate, :node

  #### new ####
  def initialize()
    @mate = Hash.new(nil)
    @node = nil
  end

  #### show ####
  def show
    puts "ADD  #{self}"
    puts "KEY  #{@mate}"
    puts "NODE #{@node}"
  end

  #### clone ####
  def clone
    m = Mate.new
    @mate.keys.each do |n|
      m.set_mate(n, @mate[n])
    end
    m
  end

  #### set ####
  def set_mate(_n, _v)
    @mate[_n] = _v
  end
  def set_node(_node)
    @node = _node
  end

  #### add/delete ####
  def add_to_frontier(_n)
    @mate[_n] = _n if @mate[_n] == nil
  end
  def delete_from_frontier(_n)
    v = @mate[_n]
    @mate.delete(_n)
    v
  end

  #### get digree ####
  def get_digree(_n)
    return 0 if @mate[_n] == _n
    return 2 if @mate[_n] == 0
    return 1
  end

  #### to key ####
  def to_key
    @mate.to_a.each{|n| "#{n}"}.join(':')
  end
end

########################################
# Mate Manager class
########################################
class MateManager
  #### new ####
  def initialize(_g)
    @g = _g

    #### mate hash ####
    @mhash = Array.new(@g.enum){|i| Hash.new(nil)}
  end

  #### show ####
  def show
    puts "#{@g.vnum} vertices"
    puts "#{@g.enum} edges"
    for i in 0..@g.enum-1
      puts "LEV #{i}"
      @mhash[i].keys.each do |key|
        puts "--------------------------------------------------------------------------------"
        @mhash[i][key].show
      end
      puts "--------------------------------------------------------------------------------"
    end
  end

  #### delete level ####
  def delete_level(_level)
    @mhash[_level].clear
  end

  #### make mate ####
  def get_mate(_mate, _level)
    @mhash[_level][_mate.to_key]
  end
  def set_mate(_mate, _level)
    @mhash[_level][_mate.to_key] = _mate
  end

  #### update mate by edge & val ####
  def update_mate(_mate, _edge, _val)
    m = _mate

    # add no edge
    return m if _val == 0

    # ad an edge
    a = _edge[0]
    b = _edge[1]

    if m.mate[a] == nil && m.mate[b] == nil  # a, b are new terminal
      m.mate[a] = b
      m.mate[b] = a
    elsif m.mate[a] == nil # a is a new terminal
      t = m.mate[b]
      m.mate[a] = t
      m.mate[t] = a if m.mate[t] != nil
      m.mate[b] = 0
    elsif m.mate[b] == nil # b is a new terminal
      t = m.mate[a]
      m.mate[b] = t
      m.mate[t] = b if m.mate[t] != nil
      m.mate[a] = 0
    else # a, b, are not a new terminal
      t = m.mate[a]
      s = m.mate[b]
      m.mate[a] = 0
      m.mate[b] = 0
      m.mate[s] = t if m.mate[s] != nil
      m.mate[t] = s if m.mate[t] != nil
    end

    return m
  end

  #### pre-checking ####
  def pre_checking(_mate, _edge, _val)
    return @@unknown if _val == 0

    m = _mate
    e = _edge
    d = [m.get_digree(e[0]), m.get_digree(e[1])]

    # shold be a path
    return @@zero if d[0] == 2 || d[1] == 2

    # @s and @t must be terminals
    for b in 0..1
      return @@zero if (e[b] == @g.s || e[b] == @g.t) && d[b] == 1
    end

    # no cycle
    return @@zero if m.mate[ e[0] ] == e[1] &&  m.mate[ e[1] ] == e[0]

    # s-t path
    if (m.mate[ e[0] ] == @g.s && m.mate[ e[1] ] == @g.t) ||
       (m.mate[ e[0] ] == @g.t && m.mate[ e[1] ] == @g.s)
      m.mate.keys.each do |n|
        return @@zero if n != @s && n != @t && n != e[0] && n != e[1] && m.get_digree(n) == 1
      end
      return @@one
    end

    return @@unknown
  end

  #### post-checking ####
  def post_checking(_mate, _vs)
    m = _mate

    _vs.each do |v|
      if (v == @g.s || v == @g.t)
        return @@zero if m.get_digree(v) == 0
      else
        return @@zero if m.get_digree(v) == 1
      end
      m.delete_from_frontier(v)
    end
    return @@unknown
  end
end


################################################################################
# Node
################################################################################
########################################
# Node class
########################################
class Node
  #### accessors ####
  attr_reader :var, :child, :mate, :count

  #### new ####
  def initialize(_var)
    @var   = _var
    @child = [nil, nil]
    @mate  = nil
    @count = 0
  end

  #### show ####
  def show
    puts "ADD  #{self}"
    puts "LEV  #{var}"
    for b in 0..1
      if @child[b] == nil || (@child[b].var != @@one && @child[b].var != @@zero)
        puts "CH#{b}  #{child[b]}"
      else
        puts "CH#{b}  #{child[b].var + 2}"
      end
    end
    puts "MATE #{@mate}"
    puts "REF  #{@count}"
  end

  #### set_child ####
  def set_v_child(_val, _node)
    @child[_val] = _node
  end

  #### set_mate ####
  def set_mate(_mate)
    @mate = _mate
  end

  #### add_count ####
  def add_count(_c)
    @count += _c
  end
end

########################################
# Node manager
########################################
class NodeManager
  #### accessors ####
  attr_reader :one, :zero, :list

  #### new ####
  def initialize(_level)
    @level = _level           # # variables (edges)
    @n     = 0                # # non-terminal nodes
    @one  = Node.new(@@one)   # 1 terminal
    @zero = Node.new(@@zero)  # 0 terminal
    @list = Array.new(@level){|i| Array.new}
  end

  #### show ####
  def show
    puts "#{@level} variables"
    puts "#{@n} non-terminal nodes"
    for i in 0..@level-1
      puts "LEV #{i}"
      @list[i].each do |n|
        puts "--------------------------------------------------------------------------------"
        n.show
      end
      puts "--------------------------------------------------------------------------------"
    end
  end

  #### delete level ####
  def delete_level(_level)
    @list[_level].clear
  end

  #### make node ####
  def make_node(_var, _ch0, _ch1)
    @n += 1
    n = Node.new(_var)
    n.set_v_child(0, _ch0)
    n.set_v_child(1, _ch1)
    @list[_var].push(n)
    n
  end

  #### get terminal ####
  def get_terminal(_val)
    if _val == @@one
      @one
    elsif _val == @@zero
      @zero
    else
      nil
    end
  end
end

################################################################################
# Frontier
################################################################################
class Simpath
  #### new ####
  def initialize(_g)
    @g = _g
    @nm = NodeManager.new(@g.enum)
    @mm = MateManager.new(@g)

    #### root node ####
    n = @nm.make_node(0, nil, nil)
    m = Mate.new()
    n.set_mate(m)
    n.add_count(1)
    m.set_node(n)
    @mm.set_mate(m, 0)
  end

  #### show ####
  def show
    puts "Graph"
    @g.show

    puts "Node Manager"
    @nm.show

    puts "Mate Manager"
    @mm.show
  end

  #### ####
  def try
    # for each level
    for level in 0..@g.enum-1
      e = @g.e[level]
      nl = @nm.list[level]
      puts "<---- level = #{level}, edge = #{e}, # nodes = #{nl.size} ---->"

      # for each node at _level
      for i in 0..nl.size-1
        n = nl[i]
        m = n.mate

        # FOR each child
        for b in 0..1
          # child mate
          cm = m.clone
          cm.add_to_frontier(e[0])
          cm.add_to_frontier(e[1])

          # pre-cheking
          cn = @nm.get_terminal( @mm.pre_checking(cm, e, b) )

          # update child mate
          if cn == nil
            cm = @mm.update_mate(cm, e, b)
            cn = @nm.get_terminal( @mm.post_checking(cm, @g.leaving_vertices(e)) )
          end

          # get child node
          if cn == nil
            if @mm.get_mate(cm, level+1) == nil
              cn = @nm.make_node(level+1, nil, nil)
              cn.set_mate(cm)
              cm.set_node(cn)
              @mm.set_mate(cm, level+1)
            else
              cm = @mm.get_mate(cm, level+1)
              cn = cm.node
            end
          end

          # set child
          n.set_v_child(b, cn)
          cn.add_count(n.count)
        end # for b
      end # for node
      @nm.delete_level(level)
      @mm.delete_level(level)
    end # for level

    puts "Answer = #{(@nm.one).count}"
  end
end

################################################################################
# main
################################################################################

#### toy graph ####
#g = Graph.new(9)
g = generate_grid(@n)

#### simpath ####
s = Simpath.new(g)
s.try
