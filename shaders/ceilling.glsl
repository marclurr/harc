#ifdef PIXEL

uniform float width;
uniform float height;
uniform vec2 position;
uniform ArrayImage textures;
uniform float fov;
uniform float angle;
uniform float cameraOffset ;
uniform float cameraTilt = 0;


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float step = fov / width;
    float rayAngle = angle-(1.04f / 2.0f) + (screen_coords.x * step);
    vec2 dir = vec2(cos(rayAngle), sin(rayAngle));

    float z = (height-cameraOffset)/(height-screen_coords.y);
    float s = 1.0f - (z/12);
    float ppx = position.x + dir.x * (z/cos(rayAngle-angle));
    float ppy = position.y + dir.y * (z/cos(rayAngle-angle));
    float ux = floor(ppx);
    float uy = floor(ppy);

    float id = 0;
    float u = ppx - ux;
    float v = ppy - uy;

    vec3 colour = Texel(textures, vec3(1-u,v,id)).rgb;
    
    return vec4(colour*s, 1);
    
}

#endif