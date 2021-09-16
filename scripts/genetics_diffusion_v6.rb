#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20210916-182253'

require "zlib"
require "fileutils"
require "json"
require "./lib/image_helper"

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
# human
H_BIRTH_RATE = 1.0
H_DEATH_RATE = 0.5
H_MIGRATION_RATE = 0.1
H_MUTATION_RATE = 0.02

# crop
C_BIRTH_RATE = 1.0
C_DEATH_RATE = 0.5
C_MIGRATION_RATE = 0.1
C_MUTATION_RATE = 0.02
C_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE = 1.0

# lang
L_BIRTH_RATE = 1.0
L_DEATH_RATE = 0.5
L_MIGRATION_RATE = 0.1
L_MUTATION_RATE = 0.02
L_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE = 1.0


help =-> () do
  puts <<-eos
  usage:
   #{File.basename(__FILE__)} (options)
  options:
   -hb human birth_rate (default: #{H_BIRTH_RATE})
   -hd human death_rate (default: #{H_DEATH_RATE})
   -hg human migration_rate (default: #{H_MIGRATION_RATE})
   -hm human mutation_rate (default: #{H_MUTATION_RATE})

   -cb crop birth_rate (default: #{C_BIRTH_RATE})
   -cd crop death_rate (default: #{C_DEATH_RATE})
   -cg crop migration_rate (default: #{C_MIGRATION_RATE})
   -cm crop mutation_rate (default: #{C_MUTATION_RATE})
   -ct crop transmission rate by human genotype (default: #{C_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE})

   -lb lang birth_rate (default: #{L_BIRTH_RATE})
   -ld lang death_rate (default: #{L_DEATH_RATE})
   -lg lang migration_rate (default: #{L_MIGRATION_RATE})
   -lm lang mutation_rate (default: #{L_MUTATION_RATE})
   -lt lang transmission rate by human genotype (default: #{L_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE})

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

# human
$h_birth_rate = if i=ARGV.index("-hb")
                  ARGV[i+1].to_f
                else
                  H_BIRTH_RATE
                end
$h_death_rate = if i=ARGV.index("-hd")
                  ARGV[i+1].to_f
                else
                  H_DEATH_RATE
                end
$h_migration_rate = if i=ARGV.index("-hg")
                      ARGV[i+1].to_f
                    else
                      H_MIGRATION_RATE
                    end
$h_mutation_rate = if i=ARGV.index("-hm")
                     ARGV[i+1].to_f
                   else
                     H_MUTATION_RATE
                   end

# crop
$c_birth_rate = if i=ARGV.index("-cb")
                  ARGV[i+1].to_f
                else
                  C_BIRTH_RATE
                end
$c_death_rate = if i=ARGV.index("-cd")
                  ARGV[i+1].to_f
                else
                  C_DEATH_RATE
                end
$c_migration_rate = if i=ARGV.index("-cg")
                      ARGV[i+1].to_f
                    else
                      C_MIGRATION_RATE
                    end
$c_mutation_rate = if i=ARGV.index("-cm")
                     ARGV[i+1].to_f
                   else
                     C_MUTATION_RATE
                   end
$c_transmission_rate_by_human_genotype = if i=ARGV.index("-ct")
                     ARGV[i+1].to_f
                   else
                     C_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE
                   end



# lang
$l_birth_rate = if i=ARGV.index("-lb")
                  ARGV[i+1].to_f
                else
                  L_BIRTH_RATE
                end
$l_death_rate = if i=ARGV.index("-ld")
                  ARGV[i+1].to_f
                else
                  L_DEATH_RATE
                end
$l_migration_rate = if i=ARGV.index("-lg")
                      ARGV[i+1].to_f
                    else
                      L_MIGRATION_RATE
                    end
$l_mutation_rate = if i=ARGV.index("-lm")
                     ARGV[i+1].to_f
                   else
                     L_MUTATION_RATE
                   end
$l_transmission_rate_by_human_genotype = if i=ARGV.index("-lt")
                     ARGV[i+1].to_f
                   else
                     L_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE
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
             "#{OUT_DIR}_#{$h_birth_rate}_#{$h_death_rate}_#{$h_migration_rate}_#{$h_mutation_rate}:#{$c_birth_rate}_#{$c_death_rate}_#{$c_migration_rate}_#{$c_mutation_rate}:#{$l_birth_rate}_#{$l_death_rate}_#{$l_migration_rate}_#{$l_mutation_rate}"
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
  def make_child(mutation_rate)
    baby = ""
    $genome_length.times do |i|
      if rand < mutation_rate
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
  def diff(another_gene)
   if self.length == another_gene.length
      [self.split(//), another_gene.split(//)].transpose.map{|pair| pair.uniq.length==2}.count(true)
    else
      $genome_length
    end
  end
end

module Cell
  def generate_cell_pop(num_pop)
    self.clear
    num_pop.times do 
      #baby = "0"*$genome_length
      zero = rand($genome_length+1)
      one = $genome_length - zero
      baby = ("0"*zero + "1"*one).split(//).shuffle.join
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
        if rand<$h_migration_rate
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
        if rand<($h_birth_rate)
          if self[x][y].size > 0 and self[x][y].size < UNIT_MAX
            select_i = rand(self[x][y].length)
            self[x][y] << self[x][y][select_i].make_child($h_mutation_rate)
          end
        end
        if rand<($h_death_rate)
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
        if rand<$c_migration_rate
          if self[x][y].length > 0
            select_i = rand(self[x][y].length)
            select_x = self[x][y][select_i]
            x_direction = [1,-1][rand(2)]
            y_direction = [1,-1][rand(2)]
            new_x = (x+x_direction)%WIDTH
            new_y = (y+y_direction)%WIDTH
            diff_human_genotypes = human_cells[x][y].average_genotype.diff(human_cells[new_x][new_y].average_genotype)
            diff_human_genotypes_rate = diff_human_genotypes/$genome_length.to_f
            transmission_rate = 1.0 - diff_human_genotypes_rate
            if rand*$c_transmission_rate_by_human_genotype <= transmission_rate and
               self[new_x][new_y].size < UNIT_MAX and
               human_cells[new_x][new_y].size > 0
              self[new_x][new_y] << select_x
            end
          end
        end
        if rand<($c_birth_rate)
          if self[x][y].size > 0 and self[x][y].size < UNIT_MAX
            select_i = rand(self[x][y].length)
            self[x][y] << self[x][y][select_i].make_child($c_mutation_rate)
          end
        end
      end
      self[x][y].size.times do |i|
        if rand<($c_death_rate)
          if self[x][y].size > 0
            select_i = rand(self[x][y].length)
            self[x][y].delete_at(select_i)
          end
        end
      end
    end
  end
  def lang_one_generation(human_cells)
    (0..WIDTH-1).to_a.repeated_permutation(2).to_a.shuffle.each do |x,y|
      human_cells[x][y].size.times do |i|
        if rand<$l_migration_rate
          if self[x][y].length > 0
            select_i = rand(self[x][y].length)
            select_x = self[x][y][select_i]
            x_direction = [1,-1][rand(2)]
            y_direction = [1,-1][rand(2)]
            new_x = (x+x_direction)%WIDTH
            new_y = (y+y_direction)%WIDTH
            diff_human_genotypes = human_cells[x][y].average_genotype.diff(human_cells[new_x][new_y].average_genotype)
            diff_human_genotypes_rate = diff_human_genotypes/$genome_length.to_f
            transmission_rate = 1.0 - diff_human_genotypes_rate
            if rand*$l_transmission_rate_by_human_genotype <= transmission_rate and
               self[new_x][new_y].size < UNIT_MAX and
               human_cells[new_x][new_y].size > 0
              self[new_x][new_y] << select_x
            end
          end
        end
        if rand<($l_birth_rate)
          if self[x][y].size > 0 and self[x][y].size < UNIT_MAX
            select_i = rand(self[x][y].length)
            self[x][y] << self[x][y][select_i].make_child($l_mutation_rate)
          end
        end
      end
      self[x][y].size.times do |i|
        if rand<($l_death_rate)
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

lang_genotype_color_world = Array.new(WIDTH).map{Array.new(WIDTH,0)}
lang_dense_color_world = Array.new(WIDTH).map{Array.new(WIDTH,0)}
lang_cells = Array.new(WIDTH).map{Array.new(WIDTH).map{[]}}
lang_cells.init_cells


human_cells.save_cells(0, "human")
crop_cells.save_cells(0, "crop")
lang_cells.save_cells(0, "lang")
unless $do_not_make_anime
  human_cells.update_genotype_color_world(human_genotype_color_world)
  human_cells.update_dense_color_world(human_dense_color_world)
  save_color_world(human_genotype_color_world, 0, "human_genotype")
  save_color_world(human_dense_color_world, 0, "human_dense")

  crop_cells.update_genotype_color_world(crop_genotype_color_world)
  crop_cells.update_dense_color_world(crop_dense_color_world)
  save_color_world(crop_genotype_color_world, 0, "crop_genotype")
  save_color_world(crop_dense_color_world, 0, "crop_dense")

  lang_cells.update_genotype_color_world(lang_genotype_color_world)
  lang_cells.update_dense_color_world(lang_dense_color_world)
  save_color_world(lang_genotype_color_world, 0, "lang_genotype")
  save_color_world(lang_dense_color_world, 0, "lang_dense")
end

$generation.times do |gi|
  human_cells.human_one_generation
  crop_cells.crop_one_generation(human_cells)
  lang_cells.lang_one_generation(human_cells)

  warn "# generation: #{gi+1}, human pop size: #{human_cells.total_size}, crop pop size: #{crop_cells.total_size}; lang pop size: #{lang_cells.total_size}"
  human_cells.save_cells(gi+1, "human")
  crop_cells.save_cells(gi+1, "crop")
  lang_cells.save_cells(gi+1, "lang")
  unless $do_not_make_anime
    human_cells.update_genotype_color_world(human_genotype_color_world)
    human_cells.update_dense_color_world(human_dense_color_world)
    save_color_world(human_genotype_color_world, gi+1, "human_genotype")
    save_color_world(human_dense_color_world, gi+1, "human_dense")

    crop_cells.update_genotype_color_world(crop_genotype_color_world)
    crop_cells.update_dense_color_world(crop_dense_color_world)
    save_color_world(crop_genotype_color_world, gi+1, "crop_genotype")
    save_color_world(crop_dense_color_world, gi+1, "crop_dense")

    lang_cells.update_genotype_color_world(lang_genotype_color_world)
    lang_cells.update_dense_color_world(lang_dense_color_world)
    save_color_world(lang_genotype_color_world, gi+1, "lang_genotype")
    save_color_world(lang_dense_color_world, gi+1, "lang_dense")
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
    files.each do |png|
      ImageHelper.padding(png, png)
    end
    merged_file = "#{$out_dir}/#{new_type}_time_#{"%04d" % gi}.png"
    command = "convert +append #{files.join(" ")} #{merged_file}; rm #{files.join(" ")}"
    `#{command}`
    warn2 "# #{command}"
    ImageHelper.write("generation: %04d" % gi, merged_file, merged_file)
    ImageHelper.write('human', merged_file, merged_file, "0, -40")
    ImageHelper.write('crop', merged_file, merged_file, "100, -40")
    ImageHelper.write('lang', merged_file, merged_file, "200, -40")
  end
  new_type
end

def make_gif_anime(type)
  command = "convert -delay 5 -loop 0 #{$out_dir}/#{type}_time_* #{$out_dir}/#{type}_anime.gif; rm #{$out_dir}/#{type}_time_*.png"
  #command = "convert -delay 5 -loop 0 #{$out_dir}/#{type}_time_* #{$out_dir}/#{type}_anime.gif"
  `#{command}`
  warn2 "# #{command}"
end

# log
puts
unless $do_not_make_anime
  human_crop_lang_genotype = merge_png("human_genotype", "crop_genotype", "lang_genotype")
  make_gif_anime(human_crop_lang_genotype)
  human_crop_lang_dense = merge_png("human_dense", "crop_dense", "lang_dense")
  make_gif_anime(human_crop_lang_dense)
end
puts
warn2 "ruby #{__FILE__} #{ARGV.join(" ")}"
warn2 "# Parameters"
warn2 "# SEED: #{$seed}"
warn2 "# GENERATION: #{$generation}"
warn2 "# GENOME_LENGTH: #{$genome_length}"

# parameters2, for parameter searching
warn2 "# Human"
warn2 "#  H_BIRTH_RATE: #{$h_birth_rate}"
warn2 "#  H_DEATH_RATE: #{$h_death_rate}"
warn2 "#  H_MIGRATION_RATE: #{$h_migration_rate}"
warn2 "#  H_MUTATION_RATE: #{$h_mutation_rate}"
warn2 "#"
warn2 "# Crop"
warn2 "#  C_BIRTH_RATE: #{$c_birth_rate}"
warn2 "#  C_DEATH_RATE: #{$c_death_rate}"
warn2 "#  C_MIGRATION_RATE: #{$c_migration_rate}"
warn2 "#  C_MUTATION_RATE: #{$c_mutation_rate}"
warn2 "#  C_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE: #{$c_transmission_rate_by_human_genotype}"
warn2 "#"
warn2 "# Lang"
warn2 "#  L_BIRTH_RATE: #{$l_birth_rate}"
warn2 "#  L_DEATH_RATE: #{$l_death_rate}"
warn2 "#  L_MIGRATION_RATE: #{$l_migration_rate}"
warn2 "#  L_MUTATION_RATE: #{$l_mutation_rate}"
warn2 "#  L_TRANSMISSION_RATE_BY_HUMAN_GENOTYPE: #{$l_transmission_rate_by_human_genotype}"






__END__


