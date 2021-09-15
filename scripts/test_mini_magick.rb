require 'mini_magick'

img = MiniMagick::Image.open("test.jpg")

img.combine_options do |c|
#  c.gravity 'Southwest'
#  c.draw 'text 10,10 "whatever"'
#  c.font '-*-helvetica-*-r-*-*-18-*-*-*-*-*-*-2'
#  c.fill("#FFFFFF")

  c.gravity('center') 
  c.background('white')
  c.extent('1000x1000') 
end

img.write("new.jpg")
