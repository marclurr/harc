uniform float depth;
uniform Image MainTex;
uniform float maxDepth;
uniform float shadeDepth;
uniform mat4 spriteProjectionMatrix;

#ifdef VERTEX

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    return TransformMatrix * spriteProjectionMatrix * vec4(vertex_position.xy, depth, vertex_position.w);
}

#endif

#ifdef PIXEL

void effect() { 
    float shade = 1.0f - (depth / shadeDepth);
    vec4 colour = Texel(MainTex, VaryingTexCoord.xy) ;

    if (colour.a > 0) {
        love_Canvases[0] = vec4(colour.rgb*shade,1);
    } else {
        discard;
    }
}
#endif