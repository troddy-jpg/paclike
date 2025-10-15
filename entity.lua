local function gridPosWrap(pos) 
  if pos[1]>16 then pos[1]=1 return true end
  if pos[1]<1 then pos[1]=16 return true end
  if pos[2]>16 then pos[2]=1 return true end
  if pos[2]<1 then pos[2]=16 return true end
  return false
end



--ENTITY
local function entity(gridPos,dir, screenX, screenY) 
  return {
  gridPos = gridPos,
  dir = dir or 1,
  direction = function(self) return directions[self.dir] end,
  screenPosX = (gridPos[1]-1)*tilesize,
  screenPosY = (gridPos[2]-1)*tilesize,
  lastMove = 0,
  lastDash = 0,

  -- MOVEMENT FUNCTION
  move = function(self)
    local fella = self
    if fella.lastMove < 0.3 then
    else
      -- fella.screenPosX=(fella.gridPos[1]-1) * tilesize
      -- set fella screen position based on current tile
      -- fella.screenPosY=(fella.gridPos[2]-1) * tilesize
      fella.lastMove = 0
      local wouldBePos = {fella.gridPos[2]+fella:direction()[2], fella.gridPos[1]+fella:direction()[1]}
      gridPosWrap(wouldBePos)
      if stateGrid[wouldBePos[1]][wouldBePos[2]] == 1 then
        walksound:play()
        local oldpos = {fella.gridPos[1],fella.gridPos[2]}
        stateGrid[fella.gridPos[2]][fella.gridPos[1]] = 1
        fella.gridPos[2] = fella.gridPos[2] + fella:direction()[2]
        fella.gridPos[1] = fella.gridPos[1] + fella:direction()[1]
        local didWrap = gridPosWrap(fella.gridPos)
        stateGrid[fella.gridPos[2]][fella.gridPos[1]] = 3
        local newScreenX = (fella.gridPos[1]-1)*tilesize
        local newScreenY = (fella.gridPos[2]-1)*tilesize
        if didWrap then 
          fella.screenPosX = newScreenX
          fella.screenPosY = newScreenY
          return
        end
        --otherwise do tha thang
        flux.to(fella, 0.1, {
          screenPosX = (oldpos[1]-1) * tilesize, 
          screenPosY = (oldpos[2]-1) * tilesize
        }):after(fella, 0.2, {screenPosX = newScreenX, screenPosY = newScreenY})
      end
    end
  end,

  -- dash function
  dash = function(self)
    local fella = self
     if fella.lastDash < 0.3 then return end
  -- leave if currently blocked from dashing
  local testMove = {fella.gridPos[1]+(fella:direction()[1]), fella.gridPos[2]+(fella:direction()[2])}
  gridPosWrap(testMove)
  if stateGrid[testMove[2]][testMove[1]] == 0 then 
    print("BAD DASH")
    baddashSound:play()
    return
  end --LEAVE IF STARTING FACING A WALL

  --otherwise, dash!
  fella.lastDash = 0
  local rover = {fella.gridPos[1],fella.gridPos[2]}
  local positions = {{},{},{}}
  local didWraps = {false,false,false} -- need to know if I should teleport instead of tweening for wraps
  local i = 1
  stateGrid[fella.gridPos[2]][fella.gridPos[1]] = 1
  dashsound:play()
  rover[1]=fella.gridPos[1]
  rover[2]=fella.gridPos[2]
  repeat
    repeat 
      rover[1] =rover[1]+fella:direction()[1]
      rover[2] =rover[2]+fella:direction()[2]
      gridPosWrap(rover)
    until stateGrid[rover[2]][rover[1]] == 0
    -- then go back a step
    rover[1] =rover[1]-fella:direction()[1]
    rover[2] =rover[2]-fella:direction()[2]
    didWraps[i] = gridPosWrap(rover)
    positions[i][1] = rover[1]
    positions[i][2] = rover[2]
    i=i+1
    --find new valid direction
    local newD = fella.dir-2
    for d = 1, 5 do
      newD = newD+1
      if newD > 4 then newD = 1 elseif newD < 1 then newD = 4 end
      local testDir = {rover[1],rover[2]}
      testDir[1]=testDir[1]+directions[newD][1]
      testDir[2]=testDir[2]+directions[newD][2]
      gridPosWrap(testDir)
      if stateGrid[testDir[2]][testDir[1]]==1 then
        fella.dir = newD
        break
      end
    end
  until i == 4
  fella.lastMove = 0 -- prevent moving for a second

  for k,pos in ipairs(positions) do
    if didWraps[k] then 
      fella.screenPosX = (pos[1]-1)*tilesize
      fella.screenPosY = (pos[2]-1)*tilesize
    else
      flux.to(fella, 0.1, {
        screenPosX = (pos[1]-1)*tilesize,
        screenPosY = (pos[2]-1)*tilesize
      }):delay(((k-1)/10) + 0.3)
    end
  end

  -- flux.to(fella, 0.1, {
  --   screenPosX = (positions[1][1]-1)*tilesize,
  --   screenPosY = (positions[1][2]-1)*tilesize
  --   -- })
  -- }):ease("linear"):after(fella,0.1, {
  --   screenPosX = (positions[2][1]-1)*tilesize,
  --   screenPosY = (positions[2][2]-1)*tilesize
  -- }):ease("linear"):after(fella,0.1, {
  --   screenPosX = (positions[3][1]-1)*tilesize,
  --   screenPosY = (positions[3][2]-1)*tilesize
  -- }):ease("linear")
  fella.gridPos = positions[3]
  stateGrid[positions[3][2]][positions[3][1]] = 3
  -- print("=====")
  -- print(positions[1][1])
  -- print(positions[1][2])
  -- print(positions[2][1])
  -- print(positions[2][2])
  -- print(positions[3][1])
  -- print(positions[3][2])
  end,
  }
end
return entity