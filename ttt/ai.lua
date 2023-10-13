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

local function getWinIndex(board, turn, win)
  local index = -1

  for _, slot in ipairs(win) do
    if board[slot] == 0 then
      if index ~= -1 then
        return -1 -- more than one move needed
      end
      index = slot
    elseif board[slot] ~= turn then
      return -1 -- win is blocked
    end
  end
  
  return index
end

local function takeOneSlot(board, turn, slots)
  for _, slot in ipairs(slots) do
    if board[slot] == 0 then
      board[slot] = turn
      return true
    end
  end
  return false
end

local function takeCorner(board, turn)
  return takeOneSlot(board, turn, { 1, 3, 7, 9 })
end

local function takeSide(board, turn)
  return takeOneSlot(board, turn, { 2, 4, 6, 8 })
end

local forks = {
  [1] = { 7, 3 },
  [9] = { 7, 3 },
  [3] = { 1, 9 },
  [7] = { 1, 9 }
}

local function getForkIndex(board, turn)
  for slot, forks in pairs(forks) do
    if board[slot] == turn then
      for _, fork in ipairs(forks) do
        if board[fork] == 0 then
          return fork
        end
      end
    end
  end

  return -1
end

local function blockFork(board, turn)
  local opponent = turn == 1 and 2 or 1
  local forks = {
    { 1, 9 },
    { 3, 7 },
  }

  local shouldBlock = function(fork)
    return board[fork[1]] ~= 0
       and board[fork[2]] ~= 0
       and board[fork[1]] ~= turn
       and board[fork[2]] ~= turn
  end

  for _, fork in ipairs(forks) do
    if shouldBlock(fork) then
      return takeSide(board, turn)
    end
  end

  return false
end

local function makeFork(board, turn)
  if board[5] ~= turn then
    return false
  end

  local fork  = getForkIndex(board, turn)
  if fork ~= -1 then
    board[fork] = turn
    return true
  end
  return false
end

local function win(board, turn)
  for _, win in ipairs(winningBoards) do
    local index = getWinIndex(board, turn, win)
    if index ~= -1 then
      board[index] = turn
      return true
    end
  end
  return false
end

local function blockMove(board, turn)
  local opponent = turn == 1 and 2 or 1
  for _, win in ipairs(winningBoards) do
    local index = getWinIndex(board, opponent, win)
    if index ~= -1 then
      board[index] = turn
      return true
    end
  end
  return false
end

local function takeCenter(board, turn)
  if board[5] ~= 0 then
    return false
  end
  board[5] = turn
  return true
end


local function makeMove(board, turn)
  return not win(board, turn)
     and not blockMove(board, turn)
     and not takeCenter(board, turn)
     and not blockFork(board, turn)
     and not makeFork(board, turn)
     and not takeCorner(board, turn)
     and not takeSide(board, turn)
end

return makeMove
