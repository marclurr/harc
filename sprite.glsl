uniform float depth;

#ifdef PIXEL

uniform Image depthBuffer;
uniform Image MainTex;
uniform float maxDepth;
uniform float shadeDepth;

void effect() { 
    float normalisedDepth = depth / maxDepth;
    float fdepth = Texel(depthBuffer, vec2(love_PixelCoord.x/love_ScreenSize.x, love_PixelCoord.y/love_ScreenSize.y)).r;
    float shade = 1.0f - (depth / shadeDepth);
    vec4 colour = Texel(MainTex, VaryingTexCoord.xy) ;

    if (normalisedDepth <= fdepth && colour.a > 0) {
        love_Canvases[0] = vec4(colour.rgb*shade,1);
        gl_FragDepth = normalisedDepth;
    } else {
        discard;
    }
}
#endif