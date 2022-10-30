#ifdef PIXEL

uniform float width;
uniform float height;
uniform vec2 position;
uniform ArrayImage textures;
uniform Image map;
uniform ivec2 mapDimensions;
uniform float fov;
uniform float angle;
uniform float cameraOffset ;
uniform float cameraTilt = 0;
uniform float shadeDepth = 1;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float step = fov / width;
    float rayAngle = angle-(1.04f / 2.0f) + (screen_coords.x * step);
    vec2 dir = vec2(cos(rayAngle), sin(rayAngle));

    float z = (height-cameraOffset)/(height-screen_coords.y);
    float s = 1.0f - (z/shadeDepth);
    float ppx = position.x + dir.x * (z/cos(rayAngle-angle));
    float ppy = position.y + dir.y * (z/cos(rayAngle-angle));
    float ux = floor(ppx);
    float uy = floor(ppy);
    float u = ppx - ux;
    float v = ppy - uy;
    float tileId = Texel(map, vec2(ux , uy) / mapDimensions).r;

    if (int(ux) < 0 || int(ux) >= mapDimensions.x || int(uy) < 0 || int(uy) >= mapDimensions.y || tileId < 0) {
        discard;
    }

    vec3 colour = Texel(textures, vec3(u,v,tileId)).rgb;
    
    return vec4(colour*s, 1);
    
}

#endif