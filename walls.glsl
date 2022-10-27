#ifdef PIXEL

#define MAIN_CANVAS 0
#define WALL_DEPTH_BUFFER 1

struct RenderData {
    float textureId;
    float wallHeight;
    float u;
    float shade;
    float distance;
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
| 1   | rayLength | not used      | not used  | not used  |
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
    result.distance = row2.r;
    result.z = row2.g;

    return result;
}

void effect() {
    vec2 screen_coords = love_PixelCoord;
    RenderData rd = extractRenderData(screen_coords.x/drawDimensions.x);

    float ceilling = (drawDimensions.y/2) - (rd.wallHeight/2) + (cameraOffset / rd.distance) + cameraTilt;
    float floor = ceilling + rd.wallHeight;
    float v = (screen_coords.y-ceilling) / rd.wallHeight;

    if (screen_coords.y < ceilling || screen_coords.y > floor) {
        love_Canvases[MAIN_CANVAS] = vec4(0);
        love_Canvases[WALL_DEPTH_BUFFER] = vec4(1);
        
    } else {    
        vec3 colour = Texel(textures, vec3(rd.u,v, rd.textureId)).rgb * rd.shade;
        float depth = rd.distance / drawDepth;

        love_Canvases[MAIN_CANVAS] = vec4(colour, 1);
        love_Canvases[WALL_DEPTH_BUFFER] = vec4(depth, depth, depth, 1); 
    }
}

#endif