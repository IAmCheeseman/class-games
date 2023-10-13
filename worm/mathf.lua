local mathf = {}

function mathf.lerp(a, b, t)
  return (b - a) * (1 - 0.5^t) + a
end

function mathf.angleDiff(a, b)
  local diff = (b - a) % (math.pi * 2)
  return (2 * diff) % (math.pi * 2) - diff
end

function mathf.lerpAngle(a, b, t)
  return a + mathf.angleDiff(a, b) * (1 - 0.5^t)
end

function mathf.length(x, y)
  return math.sqrt(x^2 + y^2)
end

function mathf.angle(x, y)
  return math.atan2(y, x)
end

function mathf.normalize(x, y)
  local len = math.sqrt(x^2 + y^2)
  if len ~= 0 then
    return x / len, y / len
  end
  return x, y
end

function mathf.distance(x, y, xx, yy)
  return math.sqrt((xx - x)^2 + (yy - y)^2)
end

function mathf.direction(x, y, xx, yy)
  return mathf.normalize(xx - x, yy - y)
end

return mathf
