#ifdef PIXEL

#define MAIN_CANVAS 0

struct RenderData {
    float textureId;
    float wallHeight;
    float u;
    float shade;
    float rayLength;
    float z;
};

uniform vec2 drawDimensions;
uniform ArrayImage textures;

/**
dataBuffer data layout
__________________________________________________________
|     | r         | g             | b         | a         |
|=====|===========|===============|===========|===========|
| 0   | textureId | wallHeight    | texture U | shade     |
| 1   | rayLength | normalised z  | not used  | not used  |
|_____|___________|_______________|___________|___________|
*/
uniform Image dataBuffer;
uniform float cameraOffset = 0;
uniform float cameraTilt = 0;
uniform float drawDepth = 1;

RenderData extractRenderData(float screenU) {
    RenderData result;

    vec4 row1 = Texel(dataBuffer, vec2(screenU, 0));
    vec4 row2 = Texel(dataBuffer, vec2(screenU, 1));

    result.textureId = row1.r;
    result.wallHeight = row1.g ;
    result.u = row1.b;
    result.shade = row1.a;
    result.rayLength = row2.r;
    result.z = row2.g;

    return result;
}

void effect() {
    vec2 screen_coords = love_PixelCoord;
    RenderData rd = extractRenderData(screen_coords.x/love_ScreenSize.x);

    float ceilling = (love_ScreenSize.y/2) - (rd.wallHeight/2) + (cameraOffset / rd.rayLength) + cameraTilt;
    float floor = ceilling + rd.wallHeight + 1;
    float v = (screen_coords.y-ceilling) / rd.wallHeight;

    if (screen_coords.y < ceilling || screen_coords.y > floor) {
        // can't simply discard this fragment as we want to write to the depth buffer, so just write a blank pixel instead
        love_Canvases[MAIN_CANVAS] = vec4(0);
        gl_FragDepth = 1;
    } else {    
        vec3 colour = Texel(textures, vec3(rd.u,v, rd.textureId)).rgb * rd.shade;
        love_Canvases[MAIN_CANVAS] = vec4(colour, 1);
        gl_FragDepth = rd.z;
    }
}

#endif