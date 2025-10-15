_G.love = require("love")
local love = require("love")
math.randomseed(os.time())
local lick = require "lib/lick"
lick.reset=true
local flux = require"lib/flux"

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

local function random_valid_spot() -- returns a place something could spawn
  local goodSpot = {1,1}
    repeat
      goodSpot[1]=math.random(1,16)
      goodSpot[2]=math.random(1,16)
    until bitmap[goodSpot[2]][goodSpot[1]] == 1
  return goodSpot
end

local function coord_to_pos(coords)
  return {(coords[1]-1)*tilesize, (coords[2]-1)*tilesize}
end

local function pos_to_coord(pos)
  local x,y = pos[1],pos[2]
  return {math.floor(x/tilesize)+1, math.floor(y/tilesize)+1}
end

local function px_to_tile(x,y)
  local floored = pos_to_coord({x,y}) 
  return bitmap[floored[2]][floored[1]]
end

local function new_guy()
  local goodSpot = random_valid_spot()
  return {
      pos=coord_to_pos(goodSpot),
      quad = love.graphics.newQuad(0,0, tilesize, tilesize, playerimg),
      current_tile = goodSpot,
      direction = 4, -- 1: north; 2:e; 3:s; 4:w
      nextDirection=4,
      ammo = 1,
      status = 1, -- 1: alive, 0: dead
    }
end

--requires global tilesize
local function move_validity(dx, dy)
  -- check for tiles Innot move through
  if px_to_tile(dx,dy)==0 then return false end
  if px_to_tile(dx+tilesize-1,dy)==0 then return false end
  if px_to_tile(dx,dy+tilesize-1)==0 then return false end
  if px_to_tile(dx+tilesize-1,dy+tilesize-1)==0 then return false end
  return true
end

function next_pos(guy,dt)
  -- return true if guy.nextDirection would be a valid move.
  local dir = guy.nextDirection
  local offset = dir_to_offset[dir]
  dt=dt*100
  local dx = guy.pos[1]+(offset[1]*dt)
  local dy = guy.pos[2]+(offset[2]*dt)

  -- wrap if neccecary
  if dy <= 0 then dy = love.graphics.getHeight()-tilesize end
  if dy+tilesize > love.graphics.getHeight() then dy = 0 end
  if dx <= 0 then dx = love.graphics.getWidth() end
  if dx > love.graphics.getWidth() then dx = 0 end

  return {dx,dy}
end

-- function validate_direction(guy,dt)--player.
--   local pos = next_pos(guy,dt)
--   local dx = pos[1]
--   local dy = pos[2]
--   -- check new location is valid
--   if not move_validity(dx, dy) then
--     return true
--   else
--     return false
-- end


-- local function validate_and_move(guy,dt)
--   local pos next_pos(guy)
--   local dx = pos[1]
--   local dy = pos[2]
--   -- check new location is valid
--   if move_validity(dx, dy) then
--     local c = false

--     if compindex > 0 then
--       for i, comp in ipairs(comps) do
--         if not i == compindex then
--           if pos_to_coord(comp.pos) == pos_to_coord(guy.pos) then c=true end
--         end
--       end
--     end
--     if not c then
--       guy.pos = {dx, dy}
--       return true
--     end
--   else return false
--   end
-- end

function love.load()
  love.window.setMode(512,512, nil) -- set window size

  _G.start_tile = {3, 6}
  _G.tilesize = 32 --pixels
  _G.dir_to_offset = {
      {0,-1},
      {1,0},
      {0,1},
      {-1,0}
    }
    _G.bitmap = get_bitmap_from_img("mapBits.png") -- get bitmap
    _G.playerimg = love.graphics.newImage("player_sprite.png",nil)
    _G.mapimg = love.graphics.newImage("pacmap_illustrated.png",nil)
    --print bitmap
    for _, row in ipairs(bitmap) do
      for _, pixel in ipairs(row) do
        -- io.write(pixel)
      end
      -- print() -- Print a newline character after each row
    end
    -- start a player and three enemies somewhere


    -- PLAYER TABLE
    _G.player = {
      pos={(start_tile[1]-1) * tilesize, (start_tile[2]-1) * tilesize},
      quad = love.graphics.newQuad(0,0, tilesize, tilesize, playerimg),
      current_tile = {3, 6},
      direction = 4, -- 1: north; 2:e; 3:s; 4:w
      nextDirection=4,
      dash = function(dt)    
        local offset = _G.dir_to_offset[player.direction]
        local targPos = pos_to_coord(player.pos)

        -- Step forward FIRST to avoid checking the current tile
        targPos[1] = targPos[1] + offset[1]
        targPos[2] = targPos[2] + offset[2]

        -- Apply wraparound
        if targPos[1] > 16 then targPos[1] = 1 elseif targPos[1] < 1 then targPos[1] = 16 end
        if targPos[2] > 16 then targPos[2] = 1 elseif targPos[2] < 1 then targPos[2] = 16 end

        -- Continue while in walkable tiles
        while bitmap[targPos[2]][targPos[1]] == 1 do
          targPos[1] = targPos[1] + offset[1]
          targPos[2] = targPos[2] + offset[2]

          if targPos[1] > 16 then targPos[1] = 1 elseif targPos[1] < 1 then targPos[1] = 16 end
          if targPos[2] > 16 then targPos[2] = 1 elseif targPos[2] < 1 then targPos[2] = 16 end
        end

        -- step one step back (otherwise we are in the wall)
        targPos[1]=targPos[1]-offset[1]
        targPos[2]=targPos[2]-offset[2]

        -- convert from tile coordinate to render position
        targPos=coord_to_pos(targPos)
        flux.to(player.pos, 0.05, targPos)



        --use the :after function to chain three different targ_pos destinations
        --find new player direction
        local newDirection = 1
        while newDirection < 5 and move_validity=------------------------------------------------------------------------(next_pos(player,dt)) do
          newDirection=newDirection+1
        end
        local offset = _G.dir_to_offset[player.direction]
        local targPos = pos_to_coord(player.pos)

        -- Step forward FIRST to avoid checking the current tile
        targPos[1] = targPos[1] + offset[1]
        targPos[2] = targPos[2] + offset[2]

        -- Apply wraparound
        if targPos[1] > 16 then targPos[1] = 1 elseif targPos[1] < 1 then targPos[1] = 16 end
        if targPos[2] > 16 then targPos[2] = 1 elseif targPos[2] < 1 then targPos[2] = 16 end

        -- Continue while in walkable tiles
        while bitmap[targPos[2]][targPos[1]] == 1 do
          targPos[1] = targPos[1] + offset[1]
          targPos[2] = targPos[2] + offset[2]

          if targPos[1] > 16 then targPos[1] = 1 elseif targPos[1] < 1 then targPos[1] = 16 end
          if targPos[2] > 16 then targPos[2] = 1 elseif targPos[2] < 1 then targPos[2] = 16 end
        end

        -- step one step back (otherwise we are in the wall)
        targPos[1]=targPos[1]-offset[1]
        targPos[2]=targPos[2]-offset[2]

        -- convert from tile coordinate to render position
        targPos=coord_to_pos(targPos)
        flux.to(player.pos, 0.05, targPos)

      
      end,
    }
    _G.comps={}
    table.insert(_G.comps,new_guy())
    table.insert(_G.comps,new_guy())
    table.insert(_G.comps,new_guy())
    table.insert(_G.comps,new_guy())
end



-- -- KEYBINDINGS --
-- function love.keypressed(key)
--   if key == "w" or key == "up" or key == "kp8" then
--     -- if game.state.running then
--     -- player.thrusting = true
--   end
  
--   if key == "space" or key == "down" or key == "kp5" then
--     -- player:shootLazer()
--     -- player:dash(dt) -- no dt!
--   end
  
--   if key == "escape" then
--       -- game:changeGameState("paused")
--   end
-- end

-- function love.keyreleased(key)
--     if key == "w" or key == "up" or key == "kp8" then
--         player.thrusting = false
--     end
-- end

-- function love.mousepressed(x, y, button, istouch, presses)
--     if button == 1 then
--         -- if game.state.running then
--             -- player:shootLazer()
--         -- end
--     end
-- end
-- -- KEYBINDINGS --


function love.update(dt)
  if love.keyboard.isDown('up') then
      player.nextDirection = 1
  elseif love.keyboard.isDown('right') then
      player.nextDirection = 2
  elseif love.keyboard.isDown('down') then
      player.nextDirection = 3
  elseif love.keyboard.isDown('left') then
      player.nextDirection = 4
  end
  if love.keyboard.isDown("space")then
    -- player:shootLazer()
    player.dash(dt)
  end
  flux.update(dt)
  if validate_and_move(player.nextDirection,player,dt,0) then player.direction = player.nextDirection 
  else
    validate_and_move(player.direction,player,dt,0)
  end
  -- collision detections comp-on-comp
  -- for i, comp in ipairs(comps) do
  --   for j=i+1,#comps,1 do
  --     if pos_to_coord(comp.pos)[1] == pos_to_coord(comps[j].pos)[1] then
  --       if pos_to_coord(comp.pos)[2] == pos_to_coord(comps[j].pos)[2] then
  --         -- print("collision")
  --         if comp.direction > 2 then
  --           comp.direction = comp.direction - 2
  --         else
  --           comp.direction = comp.direction + 2
  --         end
  --         if comps[j].direction > 2 then
  --           comps[j].direction = comps[j].direction - 2
  --         else
  --           comps[j].direction = comps[j].direction + 2
  --         end
  --       end
  --     end
  --   end
  -- end
  for i,comp in ipairs(comps) do
    if not validate_and_move(comp.direction,comp,dt,i) then
      comp.direction=math.random(1,4)
    end
    local i2=i
    while i2 < #comps do
      if pos_to_coord(comps[i2].pos) == pos_to_coord(comp.pos) then
        comps[i2].direction = ((comps[i2].direction+2)%4)+1
        comp.direction = ((comp.direction+2)%4)+1
      end
      i2=i2+1
    end
  end
end

function love.draw()
  --draw level from bitmap
  -- for y, val in pairs(bitmap) do
  --   for x, real_val in pairs(val) do
  --     love.graphics.setColor(real_val, real_val, real_val)
  --     love.graphics.rectangle("fill",(x-1)*tilesize, (y-1)*tilesize, tilesize,tilesize)
  --   end
  -- end
  -- local mapquad = love.graphics.newQuad("fill",0,512,512)
  love.graphics.setColor(1,1,1) --clear the color
  love.graphics.draw(mapimg, 0,0)
  love.graphics.setColor(0,1,0)
  love.graphics.circle("fill", player.pos[1]+16,player.pos[2]+16,16)
  local offset=dir_to_offset[player.direction]
  love.graphics.line(
    player.pos[1]+16+(offset[1]*32),
    player.pos[2]+16+(offset[2]*32),
    player.pos[1]+16+(offset[1]*46),
    player.pos[2]+16+(offset[2]*46)
  )
  -- love.graphics.draw(playerimg, player.quad, player.pos[1], player.pos[2])
  love.graphics.setColor(0,0.2,1) --clear the color
  for _, comp in pairs(comps) do
    love.graphics.circle("fill",comp.pos[1]+16,comp.pos[2]+16,16)
    -- love.graphics.draw(playerimg, comp.quad, comp.pos[1], comp.pos[2])
  end
end

-- set up lsp better
-- install and use push for resizing
--
