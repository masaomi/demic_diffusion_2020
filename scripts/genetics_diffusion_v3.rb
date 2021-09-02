#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20210902-040952'

require "zlib"
require "fileutils"
require 'json'

# default
OUT_DIR = "out"
WIDTH = 100
CENTER = [WIDTH/2, WIDTH/2]
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
   -na do not make anime.gif (default: make anime.gif)
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
$do_not_make_anime = ARGV.index("-na")

srand($seed)
FileUtils.mkdir_p $out_dir

def warn2(arg, log=File.join($out_dir, "command.log"))
  open(log, "a") do |out|
    out.puts arg
    warn arg
  end
end

def make_png(rgb_data, out=$stdout)
  width, height = WIDTH, WIDTH
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
def save_color_world(color_world, gi, type)
  out_file = File.join($out_dir, "#{type}_time_%04d.png" % (gi))
  open(out_file, "w") do |out|
    make_png(color_world, out)
  end
end
def dist(a, b)
  Math.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2)
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
  def rgb
    rb = (size * 255 / UNIT_MAX).to_i
    if rb > 255
      rb = 255
    end
    [255-rb, 255-rb, 255]
  end
end

module Cells
  def total_size
    flatten.size
  end
  def init_cells
    (0..WIDTH-1).to_a.repeated_permutation(2).each do |x,y|
      if dist(CENTER, [x,y]) < 10
        self[x][y].generate_cell_pop(UNIT_MAX)
      end
    end
  end

  # one generation
  def human_one_generation
    (0..WIDTH-1).to_a.repeated_permutation(2).to_a.shuffle.each do |x,y|
      self[x][y].size.times do |i|
        if rand<$migration_rate
          if self[x][y].length > 0
            select_i = rand(self[x][y].length)
            select_x = self[x][y].delete_at(select_i)
            x_direction = [1,-1][rand(2)]
            y_direction = [1,-1][rand(2)]
            if self[(x+x_direction)%WIDTH][(y+y_direction)%WIDTH].size < UNIT_MAX
              self[(x+x_direction)%WIDTH][(y+y_direction)%WIDTH] << select_x
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
  def crop_one_generation(human_cells)
    (0..WIDTH-1).to_a.repeated_permutation(2).to_a.shuffle.each do |x,y|
      human_cells[x][y].size.times do |i|
        if rand<$migration_rate
          if self[x][y].length > 0
            select_i = rand(self[x][y].length)
            select_x = self[x][y].delete_at(select_i)
            x_direction = [1,-1][rand(2)]
            y_direction = [1,-1][rand(2)]
            if self[(x+x_direction)%WIDTH][(y+y_direction)%WIDTH].size < UNIT_MAX and
               human_cells[(x+x_direction)%WIDTH][(y+y_direction)%WIDTH].size > 0
              self[(x+x_direction)%WIDTH][(y+y_direction)%WIDTH] << select_x
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

  def update_genotype_color_world(color_world)
    (0..WIDTH-1).to_a.repeated_permutation(2).each do |x,y|
      color_world[x][y] = self[x][y].average_genotype.rgb
    end
  end
  def update_dense_color_world(color_world)
    (0..WIDTH-1).to_a.repeated_permutation(2).each do |x,y|
      color_world[x][y] = self[x][y].rgb
    end
  end
  def save_cells(gi, type)
    sub_out_dir = File.join($out_dir, "#{type}_cells")
    FileUtils.mkdir_p sub_out_dir unless File.exist?(sub_out_dir)
    out_file = File.join(sub_out_dir, "#{type}_cells_%04d.txt" % (gi))
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

##
## main
##

# init world
human_genotype_color_world = Array.new(WIDTH).map{Array.new(WIDTH,0)}
human_dense_color_world = Array.new(WIDTH).map{Array.new(WIDTH,0)}
human_cells = Array.new(WIDTH).map{Array.new(WIDTH).map{[]}}
human_cells.init_cells

crop_genotype_color_world = Array.new(WIDTH).map{Array.new(WIDTH,0)}
crop_dense_color_world = Array.new(WIDTH).map{Array.new(WIDTH,0)}
crop_cells = Array.new(WIDTH).map{Array.new(WIDTH).map{[]}}
crop_cells.init_cells

human_cells.save_cells(0, "human")
crop_cells.save_cells(0, "crop")
unless $do_not_make_anime
  human_cells.update_genotype_color_world(human_genotype_color_world)
  human_cells.update_dense_color_world(human_dense_color_world)
  save_color_world(human_genotype_color_world, 0, "human_genotype")
  save_color_world(human_dense_color_world, 0, "human_dense")

  crop_cells.update_genotype_color_world(crop_genotype_color_world)
  crop_cells.update_dense_color_world(crop_dense_color_world)
  save_color_world(crop_genotype_color_world, 0, "crop_genotype")
  save_color_world(crop_dense_color_world, 0, "crop_dense")
end

$generation.times do |gi|
  human_cells.human_one_generation
  crop_cells.crop_one_generation(human_cells)
  warn "# generation: #{gi+1}, human pop size: #{human_cells.total_size}, crop pop size: #{crop_cells.total_size}"
  human_cells.save_cells(gi+1, "human")
  crop_cells.save_cells(gi+1, "crop")
  unless $do_not_make_anime
    human_cells.update_genotype_color_world(human_genotype_color_world)
    human_cells.update_dense_color_world(human_dense_color_world)
    save_color_world(human_genotype_color_world, gi+1, "human_genotype")
    save_color_world(human_dense_color_world, gi+1, "human_dense")

    crop_cells.update_genotype_color_world(crop_genotype_color_world)
    crop_cells.update_dense_color_world(crop_dense_color_world)
    save_color_world(crop_genotype_color_world, gi+1, "crop_genotype")
    save_color_world(crop_dense_color_world, gi+1, "crop_dense")
  end
end

class Array
  def swap(a)
    self[a], self[self.length-1] = self[self.length-1], self[a]
    self
  end
end
def merge_png(*types)
  new_type = types.join("_").split(/_/).uniq.swap(1).join("_")
  (0..$generation).each do |gi|
    files = types.map{|type| "#{$out_dir}/#{type}_time_%04d.png" % gi}
    merged_file = "#{$out_dir}/#{new_type}_time_#{"%04d" % gi}.png"
    command = "convert +append #{files.join(" ")} #{merged_file}; rm #{files.join(" ")}"
    `#{command}`
    warn2 "# #{command}"
  end
  new_type
end

def make_gif_anime(type)
  command = "convert -delay 5 -loop 0 #{$out_dir}/#{type}_time_* #{$out_dir}/#{type}_anime.gif; rm #{$out_dir}/#{type}_time_*.png"
  `#{command}`
  warn2 "# #{command}"
end

# log
puts
warn2 "ruby #{__FILE__} #{ARGV.join(" ")}"
unless $do_not_make_anime
  human_crop_genotype = merge_png("human_genotype", "crop_genotype")
  make_gif_anime(human_crop_genotype)
  human_crop_dense = merge_png("human_dense", "crop_dense")
  make_gif_anime(human_crop_dense)
end
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


