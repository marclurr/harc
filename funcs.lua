function math.remainder(f) 
    return f - math.floor(f)
end

function math.round(f)
    return math.floor(f+0.55)
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

function math.len(x, y)
    return math.sqrt(x*x+y*y)
end

function ortho(left, right, top, bottom, near, far)
    --[[ 
        copied from  https://github.com/love2d/love/blob/8e7fd10b6fd9b6dce6d61d728271019c28a7213e/src/common/Matrix.cpp#L418
        Removed the slightly uintuitive (to me) negation on the z clipping 
    ]]
    local mat = {
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        0,0,0,1
    }

    mat[1] = 2.0 / (right - left);
	mat[6] = 2.0 / (top - bottom);
	mat[11] = 2.0 / (far - near);

	mat[4] = -(right + left) / (right - left);
	mat[8] = -(top + bottom) / (top - bottom);
	mat[12] = -(far + near) / (far - near);
    return mat
end