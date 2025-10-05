
-- local function drawfn_from_image(img_location)
--   local img = love.graphics.newImage(img_location)
--   local quad = love.graphics.newQuad(0, 0, img:getWidth(), img:getHeight(), img)
--   local function drawfn(pos)
--     love.graphics.draw(img, quad, pos[1], pos[2])
--   end
--   return drawfn
-- end

local function get_tilemap_from_img(filepath)
  local img = love.image.newImageData(filepath)
  local bitmapTable={}
  local height = 16
  for y = 0, height-1 do
    bitmapTable[y+1]={}
      for x = 0,height-1 do
        local r,g,b = img:getPixel(x,y)
        if r < 0.1 and g < 0.1 and b < 0.1 then
          bitmapTable[y+1][x+1] = 0
        else
          bitmapTable[y+1][x+1] = 1
        end
      end
  end
  return bitmapTable
end

local bitmap = {}

function love.load()
   love.window.setMode(512,512) -- set window size
   bitmap = get_bitmap_from_img("mapBits.png") -- get bitmap

   --print bitmap
   for _, row in ipairs(bitmap) do
    for _, pixel in ipairs(row) do
      io.write(pixel)
    end
    print() -- Print a newline character after each row
  end
end

function love.update(dt)
end

function love.draw()

  --draw level from bitmap 
  local tilesize = 32
  for y, val in pairs(bitmap) do
    for x, real_val in pairs(val) do
      love.graphics.setColor(real_val, real_val, real_val)
      love.graphics.rectangle("fill",(x-1)*tilesize, (y-1)*tilesize, tilesize,tilesize)
    end
  end
end
