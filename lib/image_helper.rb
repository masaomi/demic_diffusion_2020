#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20210915-095900'
# ref: https://madogiwa0124.hatenablog.com/entry/2018/07/21/170019

class ImageHelper
  require 'mini_magick'
  require 'securerandom'

  #BASE_IMAGE_PATH = './bg_image.png'.freeze
  GRAVITY = 'center'.freeze
  TEXT_POSITION = '220,40'.freeze
  FONT = 'font/30170907412.ttf'.freeze
  FONT_SIZE = 10
  INDENTION_COUNT = 11
  ROW_LIMIT = 8

  class << self
    def build(text, base_image_path, text_position)
      text = prepare_text(text)
      @image = MiniMagick::Image.open(base_image_path)
      configuration(text, text_position)
    end

    def build2(base_image_path)
      @image = MiniMagick::Image.open(base_image_path)
      configuration2
    end

    def write(text, base_image_path, out_png, text_position=TEXT_POSITION)
      build(text, base_image_path, text_position)
      #@image.write uniq_file_name
      @image.write out_png
    end

    def padding(base_image_path, out_png)
      build2(base_image_path)
      #@image.write uniq_file_name
      @image.write out_png
    end

    private

    def uniq_file_name
      "#{SecureRandom.hex}.png"
    end

    def configuration(text, text_position)
      @image.combine_options do |config|
        config.font FONT
        config.gravity GRAVITY
        config.pointsize FONT_SIZE
        config.draw "text #{text_position} '#{text}'"
      end
    end

    def configuration2()
      @image.combine_options do |config|
        config.gravity GRAVITY
        config.background('white')
        config.extent('110x110') 
      end
    end

    def prepare_text(text)
      text.scan(/.{1,#{INDENTION_COUNT}}/)[0...ROW_LIMIT].join("\n")
    end
  end
end

if __FILE__ == $0
  #ImageHelper.write('aaaa', "human_lang_crop_genotype_time_0000.png", "test.png")
  ImageHelper.write('generation: 0001', "test.png", "test.png")
  ImageHelper.write('human', "test.png", "test.png", "0, -40")
  ImageHelper.write('crop', "test.png", "test.png", "100, -40")
  ImageHelper.write('lang', "test.png", "test.png", "200, -40")
end

