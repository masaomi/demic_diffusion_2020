#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20210831-052232'

require "zlib"

# default
WIDTH, HEIGHT = 100, 100
CENTER = [HEIGHT/2, WIDTH/2]
GENERATION = 300
UNIT_MAX = 10
GENOME_LENGTH = 8

# parameters
BIRTH_RATE = 1.0
DEATH_RATE = 0.5
MIGRATE_RATE = 0.1
MUTATION_RATE = 0.02


def make_png(rgb_data, out=$stdout)
  width, height = WIDTH, HEIGHT
  depth, color_type = 8, 2


  def chunk(type, data)
    [data.bytesize, type, data, Zlib.crc32(type + data)].pack("NA4A*N")
  end

  out.print "\x89PNG\r\n\x1a\n"

  out.print chunk("IHDR", [width, height, depth, color_type, 0, 0, 0].pack("NNCCCCC"))

  img_data = rgb_data.map {|line| ([0] + line.flatten).pack("C*") }.join
  out.print chunk("IDAT", Zlib::Deflate.deflate(img_data))

  out.print chunk("IEND", "")
end

def dist(a, b)
  Math.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2)
end

def rgb(pop_num)
  rb = (pop_num * 255 / UNIT_MAX).to_i
  if rb > 255
    rb = 255
  end
  [255-rb, 255-rb, 255]
end

module Gene
  def make_child
    baby = ""
    GENOME_LENGTH.times do |i|
      if rand < MUTATION_RATE
        baby << if self[i] == "0"
                  "1"
                else
                  "0"
                end
      else
        baby << self[i]
      end
    end
    baby
  end
end

module Cell
  def generate_cell_pop(num_pop)
    self.clear
    num_pop.times do 
      baby = "11111111"
      self << baby
    end
  end
  def pop2rgb
    sum = 0
    if length > 0
      each do |gene|
        sum += gene.to_i(2)
      end
      rb = sum/length
      [255-rb, 255-rb, 255]
    else
      [255, 255, 255]
    end
  end
end

module Cells
  def total_size
    flatten.size
  end
  def init_cells
    HEIGHT.times do |y|
      WIDTH.times do |x|
        if dist(CENTER, [x,y]) < 10
          #world[x][y] = rgb(UNIT_MAX)
          self[x][y].generate_cell_pop(UNIT_MAX)
        else
          #world[x][y] = rgb(0)
        end
      end
    end
  end

  # one generation
  def one_generation
    HEIGHT.times do |y|
      WIDTH.times do |x|
        self[x][y].size.times do |i|
          if rand<MIGRATE_RATE
            if self[x][y].length > 0
              select_i = rand(self[x][y].length)
              select_x = self[x][y].delete_at(select_i)
              x_direction = [1,-1][rand(2)]
              y_direction = [1,-1][rand(2)]
              if self[(x+x_direction)%WIDTH][(y+y_direction)%HEIGHT].size < UNIT_MAX
                self[(x+x_direction)%WIDTH][(y+y_direction)%HEIGHT] << select_x
              end
            end
          end
          if rand<(BIRTH_RATE)
            if self[x][y].size > 0 and self[x][y].size < UNIT_MAX
              select_i = rand(self[x][y].length)
              self[x][y] << self[x][y][select_i].make_child
            end
          end
          if rand<(DEATH_RATE)
            if self[x][y].size > 0
              select_i = rand(self[x][y].length)
              self[x][y].delete_at(select_i)
            end
          end
        end
      end
    end

    #HEIGHT.times do |x|
    #  WIDTH.times do |y|
    #    d0 = dense(world[x][y])
    #    world[x][y] = pop[x][y].pop2rgb
    #  end
    #end
  end
end

class String
  include Gene
end

class Array
  include Cell
  include Cells
end


# init world
#world = Array.new(HEIGHT).map{Array.new(WIDTH,0)}
cells = Array.new(HEIGHT).map{Array.new(WIDTH).map{[]}}
cells.init_cells
#open("time_0000.png", "w") do |out|
#  make_png(world, out)
#end

def dense(rgb)
  (255 - rgb.first) * UNIT_MAX / 255
end

GENERATION.times do |gi|
  warn "# generation: #{gi+1}, pop_size: #{cells.total_size}"
  cells.one_generation
  #out_file = "time_%04d.png" % (gi+1)
  #open(out_file, "w") do |out|
  #  make_png(world, out)
  #end
end



__END__
# sample
raw_data = []
HEIGHT.times do
  raw_data << WIDTH.times.with_object([]) do |i, ob|
    ob << [rand(256), rand(256), rand(256)]
  end
end
open("test.png", "w") do |out|
  make_png(raw_data, out)
end

