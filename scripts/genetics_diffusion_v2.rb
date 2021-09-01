#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20210901-105406'

require "zlib"
require "fileutils"
require 'json'

# default
OUT_DIR = "out"
WIDTH, HEIGHT = 100, 100
CENTER = [HEIGHT/2, WIDTH/2]
UNIT_MAX = 10


# parameters1, semi fixed
SEED = 1234

GENERATION = 100
GENOME_LENGTH = 8

# parameters2, for parameter searching
BIRTH_RATE = 1.0
DEATH_RATE = 0.5
MIGRATION_RATE = 0.1
MUTATION_RATE = 0.02

help =-> () do
  puts <<-eos
  usage:
   #{File.basename(__FILE__)} (options)
  options:
   -b birth_rate (default: #{BIRTH_RATE})
   -d death_rate (default: #{DEATH_RATE})
   -g migration_rate (default: #{MIGRATION_RATE})
   -m mutation_rate (default: #{MUTATION_RATE})

   -s random seed (default: #{SEED})
   -n generation (default: #{GENERATION})
   -l genome length (default: #{GENOME_LENGTH})

   -o out dir (default: #{OUT_DIR})
   -h command option help
  eos
  exit
end

if ARGV.index("-h")
  help.()
end
$birth_rate = if i=ARGV.index("-b")
                ARGV[i+1].to_f
              else
                BIRTH_RATE
              end
$death_rate = if i=ARGV.index("-d")
                ARGV[i+1].to_f
              else
                DEATH_RATE
              end
$migration_rate = if i=ARGV.index("-g")
                    ARGV[i+1].to_f
                  else
                    MIGRATION_RATE
                  end
$mutation_rate = if i=ARGV.index("-m")
                   ARGV[i+1].to_f
                 else
                   MUTATION_RATE
                 end
$seed = if i=ARGV.index("-s")
          ARGV[i+1].to_i
        else
          SEED
        end

$generation = if i=ARGV.index("-n")
                ARGV[i+1].to_i
              else
                GENERATION
              end

$genome_length = if i=ARGV.index("-l")
                   ARGV[i+1].to_i
                 else
                   GENOME_LENGTH
                 end

$out_dir = if i=ARGV.index("-o")
             ARGV[i+1]
           else
             "#{OUT_DIR}_#{$birth_rate}_#{$death_rate}_#{$migration_rate}_#{$mutation_rate}"
           end

srand($seed)
FileUtils.mkdir_p $out_dir

def warn2(arg, log=File.join($out_dir, "command.log"))
  open(log, "a") do |out|
    out.puts arg
    warn arg
  end
end

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
def save_color_world(color_world, gi)
  out_file = File.join($out_dir, "time_%04d.png" % (gi+1))
  open(out_file, "w") do |out|
    make_png(color_world, out)
  end
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
    $genome_length.times do |i|
      if rand < $mutation_rate
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
  def num_mutations
    split(//).count("1")
  end
  def rgb
    if self.length > 0
      rb = (num_mutations * 255 / self.length).to_i
      if rb > 255
        rb = 255
      end
      #[255-rb, 255-rb, 255]
      [rb, rb, 255]
    else
      [255, 255, 255]
    end
  end
end

module Cell
  def generate_cell_pop(num_pop)
    self.clear
    num_pop.times do 
      baby = "0"*$genome_length
      self << baby
    end
  end
  def average_genotype
    self.map{|genome| genome.split(//)}.transpose.map{|nucs_at_same_pos|
      nucs_at_same_pos.count("1") > nucs_at_same_pos.size/2 ? 1 : 0
    }.join
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
          if rand<$migration_rate
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
          if rand<($birth_rate)
            if self[x][y].size > 0 and self[x][y].size < UNIT_MAX
              select_i = rand(self[x][y].length)
              self[x][y] << self[x][y][select_i].make_child
            end
          end
          if rand<($death_rate)
            if self[x][y].size > 0
              select_i = rand(self[x][y].length)
              self[x][y].delete_at(select_i)
            end
          end
        end
      end
    end
  end
  def update_color_world(color_world)
    HEIGHT.times do |y|
      WIDTH.times do |x|
        color_world[x][y] = self[x][y].average_genotype.rgb
      end
    end
  end
  def save_cells(gi)
    sub_out_dir = File.join($out_dir, "cells")
    FileUtils.mkdir_p sub_out_dir unless File.exist?(sub_out_dir)
    out_file = File.join(sub_out_dir, "cells_%04d.txt" % (gi+1))
    open(out_file, "w") do |out|
      out.puts self.to_json
    end
  end
  def load_cells
    # TD
    cells = JSON.parse(File.read("test.txt"))
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
color_world = Array.new(HEIGHT).map{Array.new(WIDTH,0)}
cells = Array.new(HEIGHT).map{Array.new(WIDTH).map{[]}}
cells.init_cells

cells.update_color_world(color_world)
open(File.join($out_dir, "time_0000.png"), "w") do |out|
  make_png(color_world, out)
end
cells.save_cells(0)

$generation.times do |gi|
  warn "# generation: #{gi+1}, pop_size: #{cells.total_size}"
  cells.one_generation
  cells.save_cells(gi)
  cells.update_color_world(color_world)
  save_color_world(color_world, gi)
end

command = "convert -delay 5 -loop 0 #{$out_dir}/time_* #{$out_dir}/anime.gif; rm #{$out_dir}/time_*.png"
`#{command}`

# log
puts
warn2 "ruby #{__FILE__} #{ARGV.join(" ")}"
warn2 "# #{command}"
warn2 "# Parameters"
warn2 "# SEED: #{$seed}"
warn2 "# GENERATION: #{$generation}"
warn2 "# GENOME_LENGTH: #{$genome_length}"

# parameters2, for parameter searching
warn2 "# BIRTH_RATE: #{$birth_rate}"
warn2 "# DEATH_RATE: #{$death_rate}"
warn2 "# MIGRATION_RATE: #{$migration_rate}"
warn2 "# MUTATION_RATE: #{$mutation_rate}"


__END__


