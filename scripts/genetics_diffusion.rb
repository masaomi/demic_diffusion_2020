#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20200709-130601'

require "zlib"

# default
WIDTH, HEIGHT = 100, 100
CENTER = [HEIGHT/2, WIDTH/2]
GENERATION = 300
UNIT_MAX = 10

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


def generate_pop(num_pop)
  pop = []
  num_pop.times do 
    baby = "11111111"
    pop << baby
  end
  pop
end
def born(parent)
  baby = ""
  8.times do |i|
    if rand < MUTATION_RATE
      baby << if parent[i] == "0"
                "1"
              else
                "0"
              end
    else
      baby << parent[i]
    end
  end
  baby
end
class Array
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


# init world
world = Array.new(HEIGHT).map{Array.new(WIDTH,0)}
pop = Array.new(HEIGHT).map{Array.new(WIDTH,0)}
HEIGHT.times do |x|
  WIDTH.times do |y|
    if dist(CENTER, [x,y]) < 10
      world[x][y] = rgb(UNIT_MAX)
      pop[x][y] = generate_pop(UNIT_MAX)
    else
      world[x][y] = rgb(0)
      pop[x][y] = []
    end
  end
end

open("time_0000.png", "w") do |out|
  make_png(world, out)
end

def dense(rgb)
  (255 - rgb.first) * UNIT_MAX / 255
end

# one generation
one_generation =-> () do
  mig_world = Array.new(HEIGHT).map{Array.new(WIDTH,0)}
  HEIGHT.times do |x|
    WIDTH.times do |y|
      d0 = dense(world[x][y])
      d0.times do |i|
        if rand<MIGRATE_RATE
          mig_world[x][y] -= 1
          mig_world[x+[1,-1][rand(2)]][y+[1,-1][rand(2)]] += 1
          if pop[x][y].length > 0
            select_i = rand(pop[x][y].length)
            select_x = pop[x][y].delete_at(select_i)
            pop[x+[1,-1][rand(2)]][y+[1,-1][rand(2)]] << select_x
          end
        end
        if rand<(BIRTH_RATE)
          mig_world[x][y] += 1
          if pop[x][y].length > 0
            select_i = rand(pop[x][y].length)
            pop[x][y] << born(pop[x][y][select_i])
          end
        end
        if rand<(DEATH_RATE)
          mig_world[x][y] -= 1
          if pop[x][y].length > 0
            select_i = rand(pop[x][y].length)
            pop[x][y].delete_at(select_i)
          end
        end
      end
    end
  end

  HEIGHT.times do |x|
    WIDTH.times do |y|
      d0 = dense(world[x][y])
      #world[x][y] = rgb(d0 + mig_world[x][y])
      world[x][y] = pop[x][y].pop2rgb
    end
  end
end

GENERATION.times do |gi|
  warn "# generation: #{gi+1}"
  one_generation.()
  out_file = "time_%04d.png" % (gi+1)
  open(out_file, "w") do |out|
    make_png(world, out)
  end
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


