varying float FragVertexDepth;

#ifdef VERTEX

uniform mat4 spriteProjectionMatrix;
attribute float VertexDepth;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    FragVertexDepth = VertexDepth;
    return TransformMatrix * spriteProjectionMatrix * vec4(vertex_position.xy, VertexDepth, vertex_position.w);
}

#endif

#ifdef PIXEL

uniform Image MainTex;
uniform float maxDepth;
uniform float shadeDepth;


void effect() { 
    float shade = 1.0f - (FragVertexDepth / shadeDepth);
    vec4 colour = Texel(MainTex, VaryingTexCoord.xy) ;

    if (colour.a > 0) {
        love_Canvases[0] = vec4(colour.rgb*shade,1);
    } else {
        discard;
    }
}
#endif