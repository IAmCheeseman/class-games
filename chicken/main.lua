love.graphics.setBackgroundColor(0.5, 0.2, 0.2)

local w, h = love.graphics.getDimensions()

local x, y = w / 2, h / 2
local speed = 600
local accel = 15
local jumpForce = 9.81 * 64

local jumpVelocity = 0
local currentSpeed = 0
local speedSign = 1

local world = love.physics.newWorld(0, 9.81 * 64)

local player = {}
player.body = love.physics.newBody(world, x, y, "dynamic")
player.body:setMass(75)
player.shape = love.physics.newRectangleShape(50, 50)
player.fixture = love.physics.newFixture(player.body, player.shape)

local ground = {}
ground.body = love.physics.newBody(world, love.graphics.getWidth() / 2, love.graphics.getHeight() - 50, "static")
ground.shape = love.physics.newRectangleShape(love.graphics.getWidth(), 100)
ground.fixture = love.physics.newFixture(ground.body, ground.shape)

local leftWall = {}
leftWall.body = love.physics.newBody(world, 0, love.graphics.getHeight() / 2, "static")
leftWall.shape = love.physics.newRectangleShape(5, love.graphics.getHeight())
leftWall.fixture = love.physics.newFixture(leftWall.body, leftWall.shape)

local rightWall = {}
rightWall.body = love.physics.newBody(world, love.graphics.getWidth(), love.graphics.getHeight() / 2, "static")
rightWall.shape = love.physics.newRectangleShape(5, love.graphics.getHeight())
rightWall.fixture = love.physics.newFixture(rightWall.body, rightWall.shape)


local walkDist = 10

local runtime = 0

local function lerp(a, b, t)
  return (b - a) * t + a
end

function love.update(dt)
  world:update(dt)

  runtime = runtime + dt

  x, y = player.body:getPosition()
  x = x - 25
  y = y - 45

  local vx, vy = player.body:getLinearVelocity()
  local ix = 0
  if love.keyboard.isDown("a") then ix = ix - 1 end
  if love.keyboard.isDown("d") then ix = ix + 1 end

  if ix ~= 0 then
    speedSign = ix < 0 and -1 or 1
  end
  
  if love.keyboard.isDown("space") and player.body:isTouching(ground.body) then
    vy = -jumpForce
  end

  local currentAccel = accel

  if not player.body:isTouching(ground.body) then
    jumpVelocity = vy / jumpForce
    currentAccel = accel / 6
  else
    jumpVelocity = math.huge
  end

  vx = lerp(vx, ix * speed, currentAccel * dt)
  currentSpeed = math.abs(vx) / speed

  player.body:setLinearVelocity(vx, vy)
end

local function walk(fx, fy, offset)
  local angle = runtime * 48 + offset
  local dist = walkDist * currentSpeed
  if jumpVelocity ~= math.huge then
    angle = angle / 3
    dist = math.abs(jumpVelocity) * walkDist
  end
  local yOffset = (1 - currentSpeed) * walkDist
  local swing = speedSign
  return fx + math.cos(angle) * dist * speedSign, fy + math.sin(angle) * dist + yOffset
end

local function chooseOnDir(a, b)
  if speedSign < 0 then
    return b
  else
    return a
  end
end

function love.draw()
  -- back foot
  local p2x, p2y = x + 35, y + 50
  p2x, p2y = walk(p2x, p2y, math.pi)

  love.graphics.setColor(1, 0.5, 0)
  love.graphics.rectangle("fill", p2x, p2y, 20, 10, 10)

  -- Body
  local offsety = (1 - currentSpeed) * walkDist
  local bodyy = math.sin(runtime * 24) * 5 + offsety
  if jumpVelocity ~= math.huge then
    bodyy = jumpVelocity * 10
  end

  local combx = chooseOnDir(5, 50 - 32 - 5)
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", x + combx, y - 10 + bodyy, 32, 42, 10)

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", x, y + bodyy, 50, 50, 10)

  -- face
  local facey = math.sin(runtime * 24) * 4
  if jumpVelocity ~= math.huge then
    facey = jumpVelocity * 10
  end

  local secondEyeX = chooseOnDir(50, 0)
  love.graphics.setColor(0, 0, 0)
  love.graphics.circle("fill", x + 25, y + 20 + bodyy + facey, 8)
  love.graphics.circle("fill", x + secondEyeX, y + 20 + bodyy + facey, 8)

  local gobbleThingX = chooseOnDir(35, 0)
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", x + gobbleThingX, y + 25 + bodyy + facey, 15, 20, 10)

  local beakx = chooseOnDir(25, 25 - 32)
  love.graphics.setColor(1, 0.5, 0)
  love.graphics.rectangle("fill", x + beakx, y + 25 + bodyy + facey, 32, 10, 10)

  -- front foot
  local p1x, p1y = x - 5, y + 50
  p1x, p1y = walk(p1x, p1y, 0)

  love.graphics.setColor(1, 0.5, 0)
  love.graphics.rectangle("fill", p1x, p1y, 20, 10, 10)

  -- Draw ground
  love.graphics.setColor(0.20, 0.20, 0.20)
  love.graphics.polygon(
      "fill", ground.body:getWorldPoints(ground.shape:getPoints()))
  -- love.graphics.setColor(1, 0, 0, 0.5)
  -- love.graphics.polygon(
  --     "fill", player.body:getWorldPoints(player.shape:getPoints()))
end
