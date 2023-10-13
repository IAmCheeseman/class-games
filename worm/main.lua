local mathf = require("mathf")

local appleImage = love.graphics.newImage("apple.png")
local font = love.graphics.newFont(48)
local smallFont = love.graphics.newFont(24)
love.graphics.setFont(font)

love.graphics.setBackgroundColor(1, 0.5, 0.5)
love.mouse.setVisible(false)

local player
local runtime = 0
local score = 0
local nextAppleAt = 10
local gameState = "playing"
local causeOfDeath = "None"

local applePositions = {

}

local function randomizeApple()
  local x = love.math.random(16, love.graphics.getWidth() - 16)
  local y = love.math.random(16, love.graphics.getHeight() - 16)
  return x, y
end

local function restart()
  player = {
    x = love.graphics.getWidth() / 2,
    y = love.graphics.getHeight() / 2,
    tx = 0,
    ty = 0,
    vx = 0, 
    vy = 0,
    dir = 0,
    speed = 360,
    tail = {},
    eatTimers = {},
    pullDist = 16,
  }

  for i = 1, 3 do
    table.insert(player.tail, {
      x=player.x - player.pullDist * (i - 1),
      y=player.y
    }) 
  end

  applePositions = {}
  local ax, ay = randomizeApple()
  applePositions[1] = { x=ax, y=ay }

  score = 0
  nextAppleAt = 10
  gameState = "playing"
end

restart()

local function updatePlayer(dt)
  if gameState == "dead" then
    return
  end

  local ix, iy = 0, 0

  if love.keyboard.isDown("w") then iy = iy - 1 end
  if love.keyboard.isDown("a") then ix = ix - 1 end
  if love.keyboard.isDown("s") then iy = iy + 1 end
  if love.keyboard.isDown("d") then ix = ix + 1 end

  ix, iy = mathf.normalize(ix, iy)

  if mathf.length(ix, iy) ~= 0 then
    player.tx, player.ty = ix, iy
  end

  player.vx = player.tx * player.speed
  player.vy = player.ty * player.speed

  if mathf.length(player.vx, player.vy) ~= 0 then
    player.dir = mathf.lerpAngle(player.dir, mathf.angle(player.vx, player.vy), 10 * dt)
  end

  player.x = player.x + player.vx * dt
  player.y = player.y + player.vy * dt

  player.tail[1].x = player.x
  player.tail[1].y = player.y

  -- Pull tail along
  for i = #player.tail, 2, -1 do
    local a = player.tail[i]
    local b = player.tail[i - 1]

    if i > 5 and mathf.distance(player.x, player.y, a.x, a.y) < 48 then
      causeOfDeath = "you ate yourself"
      gameState = "dead"
    end

    if mathf.distance(a.x, a.y, b.x, b.y) > player.pullDist then
      local dx, dy = mathf.direction(a.x, a.y, b.x, b.y)
      a.x = b.x - dx * player.pullDist
      a.y = b.y - dy * player.pullDist
    end
  end

  local screenWidth, screenHeight = love.graphics.getDimensions()

  if player.x < 24 or player.x > screenWidth - 24
  or player.y < 24 or player.y > screenHeight - 24 then
    causeOfDeath = "you ate the wall"
    gameState = "dead"
  end

  for i, v in ipairs(player.eatTimers) do
    player.eatTimers[i] = v + 10 * dt

    if v >= #player.tail then 
      local back = player.tail[#player.tail]
      table.insert(player.tail, { x=back.x, y=back.y })

      table.remove(player.eatTimers, i)
    end
  end


  for i, apple in ipairs(applePositions) do
    if mathf.distance(player.x, player.y, apple.x, apple.y) < 48 then
      table.insert(player.eatTimers, 0)

      local newx, newy = randomizeApple()
      applePositions[i].x = newx
      applePositions[i].y = newy

      score = score + 1

      if score == nextAppleAt then
        nextAppleAt = nextAppleAt + math.ceil((#applePositions)^2 * 10)
        
        local newx, newy = randomizeApple()
        table.insert(applePositions, {
          x = newx,
          y = newy
        })
      end
    end
  end
end

function love.keypressed(key, _, isRepeat)
  if key == "r" and not isRepeat then
    restart()
  end

  if key == "escape" and not isRepeat and gameState ~= "dead" then
    gameState = gameState == "paused" and "playing" or "paused"
  end

  if key == "e" and not isRepeat then
    if gameState ~= "paused" and gameState ~= "dead" then
      return
    end
    love.event.quit()
  end
end

function love.update(dt)
  if gameState == "paused" then
    return
  end

  runtime = runtime + dt

  updatePlayer(dt)
end

local function drawText(text, dropShadow, x, y, ...)
    text = tostring(text):upper()

    -- Drop shadow
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(text, 0, y + dropShadow, ...)

    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(text, 0, y, ...)
end

local function drawApple()
  -- local x, y = love.mouse.getPosition()
  for _, apple in ipairs(applePositions) do
    local x, y = apple.x, apple.y
    love.graphics.setColor(1, 1, 1)
    local w, h = appleImage:getDimensions()
    w = w * 0.05
    h = h * 0.05
    love.graphics.draw(appleImage, x - w / 2, y - h / 2, 0, 0.05)
  end
end

function love.draw()
  drawApple()

  -- tail
  for i = #player.tail, 1, -1 do
    local radius = 32
    for _, v in ipairs(player.eatTimers) do
      -- Try to expand
      local eatIndex = math.floor(v)
      local progress = v - eatIndex
      local newRadius = radius + 5 * progress
      if radius < newRadius and eatIndex == i then
        radius = newRadius
      else
        -- Try to shrink
        local x = v - 1
        eatIndex = math.floor(x)
        progress = 1 - (x - eatIndex)
        newRadius = radius + 5 * progress

        if radius < newRadius and eatIndex == i then
          radius = newRadius
        end
      end
    end

    local pos = player.tail[i]
    if i % 2 == 0 then
      love.graphics.setColor(0, 0.5, 0)
    else
      love.graphics.setColor(0, 1, 0)
    end

    love.graphics.circle("fill", pos.x, pos.y, radius)
  end

  -- head
  love.graphics.setColor(1, 0.2, 0.2)
  love.graphics.circle("fill", player.x, player.y, 32)

  -- eyes
  love.graphics.setColor(0, 0, 0)
  local separation = math.pi / 5
  local dist = 32
  love.graphics.circle("fill", 
      player.x + math.cos(player.dir - separation) * dist,
      player.y + math.sin(player.dir - separation) * dist, 10)
  love.graphics.circle("fill", 
      player.x + math.cos(player.dir + separation) * dist,
      player.y + math.sin(player.dir + separation) * dist, 10)

  love.graphics.setColor(1, 1, 1)

  love.graphics.setFont(font)
  local fontHeight = font:getHeight()

  if gameState ~= "playing" then
    local screenHeight = love.graphics.getHeight()
    local y = screenHeight / 2 - fontHeight / 2

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local text
    local subtext
    if gameState == "dead" then
      text = causeOfDeath
      subtext = "Press 'R' to restart, 'E' to exit"
    elseif gameState == "paused" then
      text = "Paused"
      subtext = "Press 'E' to exit"
    end
    drawText(text, 5, 0, y, love.graphics.getWidth(), "center")

    love.graphics.setFont(smallFont)
    drawText(subtext, 3, 0, y + fontHeight, love.graphics.getWidth(), "center")
    love.graphics.setFont(font)
  end

  drawText("Score: " .. score, 5, 0, 0, love.graphics.getWidth(), "left")
  love.graphics.setFont(smallFont)
  drawText("Next Apple In: " .. nextAppleAt - score, 3, 0, fontHeight, love.graphics.getWidth(), "left")
  drawText(love.timer.getFPS(), 4, 0, 0, love.graphics.getWidth(), "right")
end
