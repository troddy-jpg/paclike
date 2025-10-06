math.randomseed(os.time())
-- local function drawfn_from_image(img_location)
--   local img = love.graphics.newImage(img_location)
--   local quad = love.graphics.newQuad(0, 0, img:getWidth(), img:getHeight(), img)
--   local function drawfn(pos)
--     love.graphics.draw(img, quad, pos[1], pos[2])
--   end
--   return drawfn
-- end
local lick = require "lick"
lick.reset=true

local function get_bitmap_from_img(filepath)
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
local player = {}
local comps = {} -- enemy entities
local start_tile = {3, 6}
local tilesize = 32
local playerimg 
local dir_to_offset = {
    {0,-1},
    {1,0},
    {0,1},
    {-1,0}
  }

function love.load()
   love.window.setMode(512,512) -- set window size
   bitmap = get_bitmap_from_img("mapBits.png") -- get bitmap
   playerimg = love.graphics.newImage("player_sprite.png")
   --print bitmap
   for _, row in ipairs(bitmap) do
    for _, pixel in ipairs(row) do
      io.write(pixel)
    end
    print() -- Print a newline character after each row
  end

   -- start a player and three enemies somewhere
   player = {
     pos={(start_tile[1]-1) * tilesize, (start_tile[2]-1) * tilesize},
     quad = love.graphics.newQuad(0,0, tilesize, tilesize, playerimg),
     current_tile = {3, 6},
     direction = 4, -- 1: north; 2:e; 3:s; 4:w
     ammo = 1,
     status = 1, -- 1: alive, 0: dead
   }


end

--requires bitmap global
function px_to_tile(x,y)
  local floored = {math.floor(x/tilesize), math.floor(y/tilesize)}
  return bitmap[floored[2]+1][floored[1]+1]
end
--requires global tilesize
function move_validity(dx, dy)
  if px_to_tile(dx,dy)==0 then return false end
  if px_to_tile(dx+tilesize-1,dy)==0 then return false end
  if px_to_tile(dx,dy+tilesize-1)==0 then return false end
  if px_to_tile(dx+tilesize-1,dy+tilesize-1)==0 then return false end
  return true
end
function validate_direction(direction)
  -- check that we can still move and keep moving
  local offset = dir_to_offset[direction]
  local dx = player.pos[1]+offset[1]
  local dy = player.pos[2]+offset[2]

  -- wrap if neccecary
  if dy == -1 then dy = love.graphics.getHeight()-tilesize end
  if dy+tilesize > love.graphics.getHeight() then dy = 0 end
  if dx == -1 then dx = love.graphics.getWidth() end
  if dx > love.graphics.getWidth() then dx = 0 end

  -- check new location is valid
  if move_validity(dx, dy) then
    return true
  end

end


function love.update(dt)
  local nextDirection = player.direction
  if love.keyboard.isDown('up') then
      nextDirection = 1
  elseif love.keyboard.isDown('right') then
      nextDirection = 2
  elseif love.keyboard.isDown('down') then
      nextDirection = 3
  elseif love.keyboard.isDown('left') then
      nextDirection = 4
  end
  if validate_direction(nextDirection) then player.direction = nextDirection end

  while not validate_direction(player.direction) do player.direction = math.random(1,4) end
  if validate_direction(player.direction) then
    local offset = dir_to_offset[player.direction]
    local dx = player.pos[1]+offset[1]
    local dy = player.pos[2]+offset[2]
      -- wrap if neccecary
    if dy ==-1 then dy = love.graphics.getHeight()-tilesize end
    if dy+tilesize > love.graphics.getHeight() then dy = 0 end
    if dx == -1 then dx = love.graphics.getWidth() end
    if dx > love.graphics.getWidth() then dx = 0 end

    player.pos = {dx, dy}
  end
 
end

function love.draw()


  -- check would-be coordinated, with all modifications, then decide player location and draw
  --draw level from bitmap 
  for y, val in pairs(bitmap) do
    for x, real_val in pairs(val) do
      love.graphics.setColor(real_val, real_val, real_val)
      love.graphics.rectangle("fill",(x-1)*tilesize, (y-1)*tilesize, tilesize,tilesize)
    end
  end
  love.graphics.setColor(1,1,1) --clear the color 
  love.graphics.draw(playerimg, player.quad, player.pos[1], player.pos[2])
  print(player.pos[2])
end
