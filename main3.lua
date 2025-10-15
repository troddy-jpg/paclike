

--entity functions
local function coord_to_pos(coords)
  return {(coords[1]-1)*tilesize, (coords[2]-1)*tilesize}
end

local function pos_to_coord(pos)
  local x,y = pos[1],pos[2]
  return {math.floor(x/tilesize)+1, math.floor(y/tilesize)+1}
end

local function coord_to_tile(coord)
  return bitmap[coord[2]][coord[1]]
end

--i need it
local function wrap(number,min,max)
   local toret = number
   if toret > max then toret = min end
   if toret < min then toret = max end
   return toret
end

local pos_to_tile = function(pos)
  return coord_to_tile(pos_to_coord(pos))
end

local function wrapPos(pos) return {
        wrap(pos[1],0,love.graphics.getWidth()),
        wrap(pos[2],0,love.graphics.getHeight())}
end

_G.love=require"love"
_G.flux=require"lib/flux"
_G.lick=require"lib/lick"
_G.tilesize=32
_G.player = {
   pos=coord_to_pos({16,6}),
   direction={-1,0}, --describes movement offset of direction. {-1,0} means moving to the left.
   nextDirection={-1,0}, -- indicates if the player is trying to turn 

  --is player center at least 16 px away from a bad tile
  properly_distanced = function (self)
    -- if our pos is either along the top or the left of a 1 tile
    local ctile = pos_to_tile(self.pos)
    local ccoord = pos_to_coord(self.pos)
    if ctile == 0 then 
      return false
    end
    local modified_coord = {coord_to_pos(ccoord)[1]+1,coord_to_pos(ccoord)[2]+1}
    if modified_coord(ccoord)[1] % 32 == 1 then
      if self.direction == {0,1} or self.direction == {0,-1} then
        return true
      end
    elseif modified_coord(ccoord)[2] % 32 == 1 then
      if self.direction == {1,0} or self.direction == {-1,0} then
        return true
      end
    end
--   if px_to_tile(dx+tilesize-1,dy)==0 then return false end
--   if px_to_tile(dx,dy+tilesize-1)==0 then return false end
--   if px_to_tile(dx+tilesize-1,dy+tilesize-1)==0 then return false end
  return false
  end,

   try_to_move = function(self, dt,dir) 
    local targPos={self.pos[1]+(dt*dir[1]*100),self.pos[2]+(dt*dir[2]*100)}
      --wrap
      
      targPos = wrapPos(targPos)
      local oldself = self.pos
      self.pos=targPos
      if self:properly_distanced() == false then 
        self.pos = oldself 
        return false
      else 
        return true
      end
   end,
   move = function(self,dt)
    if self:try_to_move(dt,self.nextDirection) == true then 
      self.direction=self.nextDirection
    else
      self:try_to_move(dt,self.direction)
    end
   end,

   dash = function(self,dt)
      local targ = pos_to_coord(self.pos)
      --step and check
      targ[1] = targ[1] + self.direction[1]
      targ[2] = targ[2] + self.direction[2]

      targ={wrap(targ[1],16,16),wrap(targ[2],16,16)}

      -- 
      while coord_to_tile(pos_to_coord(targ)) do
         targ[1] = targ[1] + self.direction[1]
         targ[2] = targ[2] + self.direction[2]

         -- Apply wraparound
         targ={wrap(targ[1],16,16),wrap(targ[2],16,16)}
      end

      --go back one step
      targ[1] = targ[1] - self.direction[1]
      targ[2] = targ[2] - self.direction[2]

      targ={wrap(targ[1],16,16),wrap(targ[2],16,16)}

      flux.to(player.pos, 0.05, coord_to_pos(targ))
   end
}
_G.enemy = {}

--
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

_G.bitmap = get_bitmap_from_img("mapBits.png") -- get bitmap
_G.stateGrid = bitmap
function love.load()
  love.window.setMode(512,512,nil)
  --print bitmap
    for _, row in ipairs(bitmap) do
      for _, pixel in ipairs(row) do
        io.write(pixel)
      end
      print() -- Print a newline character after each row
    end
    -- start a player and three enemies somewhere
end

function love.draw()
  -- draw level from bitmap
  for y, val in pairs(bitmap) do
    for x, real_val in pairs(val) do
      love.graphics.setColor(real_val, real_val, real_val)
      love.graphics.rectangle("fill",(x-1)*tilesize, (y-1)*tilesize, tilesize,tilesize)
    end
  end

  --draw player
  love.graphics.setColor(0,1,0)
  love.graphics.circle("fill", player.pos[1]+16,player.pos[2]+16,16)
  love.graphics.line(
    player.pos[1]+16+(player.direction[1]*32),
    player.pos[2]+16+(player.direction[2]*32),
    player.pos[1]+16+(player.direction[1]*46),
    player.pos[2]+16+(player.direction[2]*46)
  )
end

function love.update(dt)
  if love.keyboard.isDown('up') then
      player.nextDirection = {0,-1}
  elseif love.keyboard.isDown('right') then
      player.nextDirection = {1,0}
  elseif love.keyboard.isDown('down') then
      player.nextDirection = {0,1}
  elseif love.keyboard.isDown('left') then
      player.nextDirection = {-1,0}
  end
  player:move(dt)
  flux.update(dt)
end