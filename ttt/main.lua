local aiMove = require("ai")

local font = love.graphics.newFont(12 * 10)
font:setFilter("nearest", "nearest")

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")
love.graphics.setBackgroundColor(0.2, 0.2, 0.2)

local canvas = love.graphics.newCanvas(320, 180)

local boardWidth = 48
local boardHeight = 48
local boardStartX = 320 / 2 - boardWidth / 2
local boardStartY = 180 / 2 - boardHeight / 2
local slotWidth = boardWidth / 3
local slotHeight = boardHeight / 3

local States = {
  Empty = 0,
  X = 1,
  O = 2
}

local winningBoards = {
  { 1, 2, 3 },
  { 4, 5, 6 },
  { 7, 8, 9 },
  { 1, 4, 7 },
  { 2, 5, 8 },
  { 3, 6, 9 },
  { 1, 5, 9 },
  { 3, 5, 7 }
}

local board = {
  0, 0, 0,
  0, 0, 0,
  0, 0, 0,
}

local turn = States.X
local won = false
local turnCount = 0
local noPlayers = false
local aiCounter = 0

local function checkWin()
  for _, win in ipairs(winningBoards) do
    local possibleWinner
    local isWin = true
    for _, index in ipairs(win) do
      if not possibleWinner then
        if board[index] == States.Empty then
          isWin = false
          break
        else
          possibleWinner = board[index]
        end
      elseif board[index] ~= possibleWinner then
        isWin = false
        break
      end
    end

    if isWin then
      return true
    end
  end

  -- Checking for a tie
  local tied = true
  for _, state in ipairs(board) do
    if state == States.Empty then
      tied = false
      break
    end
  end
  
  if tied then
    turn = States.Empty
    return true
  end

  return false
end

local function getMouseSlot()
  local mx, my = love.mouse.getPosition()
  mx = mx / 3 - boardStartX
  my = my / 3 - boardStartY

  mx = math.floor(mx / slotWidth)
  my = math.floor(my / slotHeight)

  return mx, my
end

local function getStateString(state)
  if state == States.Empty then
    return ""
  elseif state == States.X then
    return "X"
  elseif state == States.O then
    return "O"
  end
  
  error("Invalid state.")
end

local function changeTurn()
  if turn == States.X then
    turn = States.O
  else
    turn = States.X
  end

  turnCount = turnCount + 1
end

function love.update(dt)
  if noPlayers and not won then
    aiCounter = aiCounter - dt
    if aiCounter < 0 then
      aiCounter = 1
      aiMove(board, turn)

      if checkWin() then
        won = true
      else
        changeTurn()
      end
    end
  end
end

function love.mousepressed(x, y, button, _, _)
  if won or noPlayers then
    return
  end

  local mx, my = getMouseSlot()
  if mx < 0 or mx > 2 or my < 0 or my > 2 then
    return
  end

  local index = (mx + 1) + my * 3
  if board[index] ~= States.Empty then
    return
  end
  board[index] = turn

  if checkWin() then
    won = true
    return
  end

  changeTurn()

  aiMove(board, turn)

  if checkWin() then
    won = true
    return
  end

  changeTurn()
end

function love.keypressed(key, _, isrepeat)
  if key == "s" and turnCount == 0 then
    aiMove(board, turn)
    changeTurn()
  elseif key == "a" and turnCount == 0 then
    noPlayers = true
  elseif key == "escape" then
    love.event.quit()
  elseif key == "r" then
    love.event.quit("restart")
  end
end

local function drawSlot(slot, x, y)
  if slot == States.X then
    love.graphics.setColor(1, 0.2, 0.2)
    x = x + 2
    y = y + 2
    ex = x + slotWidth - 5
    ey = y + slotHeight - 5
    love.graphics.line(
        x, y,
        ex, ey)
    love.graphics.line(
        x, ey,
        ex, y)
  elseif slot == States.O then
    love.graphics.setColor(0, 1, 0.9)
    x = x + slotWidth / 2
    y = y + slotHeight / 2
    love.graphics.circle("line", x, y, slotWidth / 2 - 2)
  end

  love.graphics.setColor(1, 1, 1)
end

function love.draw()
  love.graphics.setCanvas(canvas)
  love.graphics.clear()

  love.graphics.line(
      boardStartX + slotWidth, boardStartY,
      boardStartX + slotWidth, boardStartY + boardHeight)

  love.graphics.line(
      boardStartX + slotWidth * 2, boardStartY,
      boardStartX + slotWidth * 2, boardStartY + boardHeight)
  
  love.graphics.line(
      boardStartX, boardStartY + slotHeight,
      boardStartX + boardWidth, boardStartY + slotHeight)

  love.graphics.line(
      boardStartX, boardStartY + slotHeight * 2,
      boardStartX + boardWidth, boardStartY + slotHeight * 2)

  for i = 1, 9 do
    local zi = i - 1
    local x = zi % 3 + 1
    local y = math.floor(zi / 3) + 1

    local dx = boardStartX + slotWidth * (x - 1)
    local dy = boardStartY + slotHeight * (y - 1)
    drawSlot(board[i], dx, dy)
  end

  love.graphics.setColor(1, 1, 1, 0.5)
  local mx, my = getMouseSlot()
  if mx >= 0 and mx < 3
  and my >= 0 and my < 3 then
    love.graphics.rectangle("fill", 
        mx * slotWidth + boardStartX, 
        my * slotHeight + boardStartY, 
        slotWidth, slotHeight)
  end
  love.graphics.setColor(1, 1, 1)

  local texty = boardStartY + boardHeight * 1.2

  local text = "Make a move"
  if noPlayers then
    text = "Auto"
  end

  if won then
    if turn == States.Empty then
      text = "Tie!"
    else
      text = ("%s won!"):format(getStateString(turn))
    end

    text = text .. " Press 'R' to restart"
  elseif turnCount == 0 then
    text = "Hit 'S' to let the AI go first\n'A' to let the AIs fight"
  end
  
  love.graphics.setFont(font)
  love.graphics.printf(
      text,
      0, texty,
      320 * 10, "center",
      0, 1/10)
  love.graphics.setCanvas()

  love.graphics.draw(canvas, 0, 0, 0, 3)
end
