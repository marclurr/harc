function math.remainder(f) 
    return f - math.floor(f)
end

function math.round(f)
    return math.floor(f+0.50)
end

function math.sign(f)
    if f < 0 then
        return -1
    elseif f > 0 then
        return 1
    else
        return 0
    end
end

function math.lerp(a, b, t)
    return (a + ((b - a) * t))
end
