
  -- TODO RN
-- fix visuals when wrapping
-- when I dash into the enemy it dies
-- make the enemy move randomly
-- make the enemy able to dash
-- make the enemy follow the player
-- if the enemy dashes into me I die
-- if the enemy and I are both dashing dur
-- during collision:
-- if I am dashing enemy dies
-- if enemy is dashing I die
-- if both are dashing check directions. if y axis is the same the one going left / right lives. vice-versa.
-- if both dashing and both moving along 'kill axis', that means they must have dashed into each other resulting in PLAYER_1, loss by suicide
-- WIN!
-- LOSS BY DEATH!
-- LOSS BY SUICIDE!

--delay to dash activating, 3x some sound


--import stuff and declare globals
_G.love=require"love"
_G.flux=require"lib/flux"
_G.lick=require"lib/lick"
_G.tilesize=32
_G.directions = {{0,-1},{1,0},{0,1},{-1,0}}
_G.walksound = love.audio.newSource("1.wav","stream")
_G.dashsound = love.audio.newSource("dash.wav","stream")
_G.baddashSound = love.audio.newSource("baddash.wav","stream")
-- MY STUFF
_G.entity = require"entity"

-- AI generated function to convert hex to a decimal color table
local function hexToRGBA(hexColor)
  hexColor = hexColor:gsub("#", "") -- Remove the '#' if it exists
  local r = tonumber("0x" .. hexColor:sub(1, 2))
  local g = tonumber("0x" .. hexColor:sub(3, 4))
  local b = tonumber("0x" .. hexColor:sub(5, 6))
  return {r / 255, g / 255, b / 255}
end

--convert low res black and white image into bitmap for game map
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

_G.bitmap = get_bitmap_from_img("mapBits.png")
_G.stateGrid = bitmap

-- PLAYER ENEMY TABLES
_G.player = entity({1,4},2,0,tilesize*3)
_G.enemy = entity({16,4},4,tilesize*15,tilesize*3)

--INDICATE PLAYER,ENEMY LOCATION ON GRID
stateGrid[player.gridPos[2]][player.gridPos[1]] = 3
stateGrid[enemy.gridPos[2]][enemy.gridPos[1]] = 4

-- LOVE2D FUNCTIONS ======================================================================
-- LOVE2D FUNCTIONS ======================================================================
-- LOVE2D FUNCTIONS ======================================================================
function love.load()
  --love settings
  love.window.setMode(512,512,nil)
  --print bitmap
    for _, row in ipairs(bitmap) do
      for _, pixel in ipairs(row) do
        -- io.write(pixel)
      end
      -- print() -- Print a newline character after each row
    end
    -- start a player and three enemies somewhere
end

function love.keypressed(key)
  if key == "space" then
    player:dash()
  end
  if key == "up" then
    player.dir = 1
  end
  if key == "right" then
    player.dir = 2
  end
  if key == "down" then
    player.dir = 3
  end
  if key == "left" then
    player.dir = 4
  end
end


function love.update(dt)
  --update timers
  player.lastDash = player.lastDash + dt
  enemy.lastDash = enemy.lastDash + dt
  player.lastMove = player.lastMove + dt
  enemy.lastMove = enemy.lastMove + dt
  flux.update(dt) -- for tweening

  -- move entities
  player:move()
  enemy:move()

end

function love.draw()
  -- draw level from bitmap
  -- draw level from bitmap
    for y, val in pairs(bitmap) do
      for x, real_val in pairs(val) do
        if real_val == 1 or real_val == 0 then 
          love.graphics.setColor(real_val, real_val, real_val)
          love.graphics.rectangle("fill",(x-1)*tilesize, (y-1)*tilesize, tilesize,tilesize)
        end
        if real_val == 3 or real_val == 4 then
        --   love.graphics.setColor(0,1,0)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("fill",(x-1)*tilesize, (y-1)*tilesize, tilesize,tilesize)
        end
      end
    end

  --draw player
  local hexxed = hexToRGBA("#81E01F")
  love.graphics.setColor(hexxed[1],hexxed[2],hexxed[3])
  local r = tilesize/2
  love.graphics.circle("fill", player.screenPosX + r, player.screenPosY + r,r)

  --draw enemy
  local hexxed = hexToRGBA("#D9414C")
  love.graphics.setColor(hexxed[1],hexxed[2],hexxed[3])
  local r = tilesize/2
  love.graphics.circle("fill", enemy.screenPosX + r, enemy.screenPosY + r,r)
end