mat3 GetTBN();
vec3 GetBumpedNormal(mat3 tbn, vec2 texcoord);
vec2 ParallaxMap(mat3 tbn);

Material ProcessMaterial()
{
    mat3 tbn = GetTBN();
    vec2 texCoord = ParallaxMap(tbn);

    Material material;
    material.Base = getTexel(texCoord);
    material.Normal = GetBumpedNormal(tbn, texCoord);
    material.Specular = texture(speculartexture, texCoord).rgb;
    vec4 glossSpec = texture(tex_gloss, texCoord);
   material.Glossiness = glossSpec.r * uSpecularMaterial.x;
   material.SpecularLevel = glossSpec.g * uSpecularMaterial.y;
#if defined(BRIGHTMAP)
    material.Bright = texture(brighttexture, texCoord);
#endif
    return material;
}

// Tangent/bitangent/normal space to world space transform matrix
mat3 GetTBN()
{
    vec3 n = normalize(vWorldNormal.xyz);
    vec3 p = pixelpos.xyz;
    vec2 uv = vTexCoord.st;

    // get edge vectors of the pixel triangle
    vec3 dp1 = dFdx(p);
    vec3 dp2 = dFdy(p);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);

    // solve the linear system
    vec3 dp2perp = cross(n, dp2); // cross(dp2, n);
    vec3 dp1perp = cross(dp1, n); // cross(n, dp1);
    vec3 t = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;

    // construct a scale-invariant frame
    float invmax = inversesqrt(max(dot(t,t), dot(b,b)));
    return mat3(t * invmax, b * invmax, n);
}

vec3 GetBumpedNormal(mat3 tbn, vec2 texcoord)
{
#if defined(NORMALMAP)
    vec3 map = texture(normaltexture, texcoord).xyz;
    map = map * 255./127. - 128./127.; // Math so "odd" because 0.5 cannot be precisely described in an unsigned format
    map.y = -map.y;
    return normalize(tbn * map);
#else
    return normalize(vWorldNormal.xyz);
#endif
}

vec2 ParallaxMap(mat3 tbn)
{
    const float parallaxScale = 0.050;
    const float minLayers = 16.0;
    const float maxLayers = 64.0;

    // Calculate fragment view direction in tangent space
    mat3 invTBN = transpose(tbn);
    vec3 V = normalize(invTBN * (uCameraPos.xyz - pixelpos.xyz));
    vec2 T = vTexCoord.st;

    float numLayers = mix(maxLayers, minLayers, clamp(abs(V.z), 0.0, 1.0)); // clamp is required due to precision loss

    // calculate the size of each layer
    float layerDepth = 1.0 / numLayers;

    // depth of current layer
    float currentLayerDepth = 0.0;

    // the amount to shift the texture coordinates per layer (from vector P)
    vec2 P = V.xy * parallaxScale;
    vec2 deltaTexCoords = P / numLayers;
    vec2 currentTexCoords = T;
    float currentDepthMapValue = texture(tex_heightmap, currentTexCoords).r;

    while (currentLayerDepth < currentDepthMapValue)
    {
        // shift texture coordinates along direction of P
        currentTexCoords -= deltaTexCoords;

        // get depthmap value at current texture coordinates
        currentDepthMapValue = texture(tex_heightmap, currentTexCoords).r; 

        // get depth of next layer
        currentLayerDepth += layerDepth; 
    }

    // get texture coordinates before collision (reverse operations)
    vec2 prevTexCoords = currentTexCoords + deltaTexCoords;

    // get depth after and before collision for linear interpolation
    float afterDepth  = currentDepthMapValue - currentLayerDepth;
    float beforeDepth = texture(tex_heightmap, prevTexCoords).r - currentLayerDepth + layerDepth;
     
    // interpolation of texture coordinates
    float weight = afterDepth / (afterDepth - beforeDepth);
    vec2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

    return finalTexCoords; 
}