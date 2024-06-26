mat3 GetTBN();
vec2 GetAutoscaleAt(vec2 texcoord);
vec2 ParallaxMap(mat3 tbn); 
vec3 GetBumpedNormal(mat3 tbn, vec2 ParallaxMap);
vec2 GetTopscrollposAt(vec2 parallaxMap);
vec2 GetLayerScaleAt(vec2 parallaxMap);
vec2 GetLiquidscrollposAt(vec2 parallaxMap);
vec2 GetLiquidscrollnegAt(vec2 parallaxMap);
vec2 GetLayerposAt(vec2 parallaxMap);


void SetupMaterial(inout Material material)				
{
    mat3 tbn = GetTBN(); 
    vec2 ParallaxMap = ParallaxMap(tbn);
	
	//// generate normal texture
	vec4 NMone = texture(normaltexture, GetLiquidscrollposAt(ParallaxMap));//normalmap scroll Y positive
	vec4 NM2two = texture(normaltexture, GetLiquidscrollnegAt(ParallaxMap));//normalmap scroll y negetive
	vec2 Nmap = ((NMone + NM2two) * 0.5).xy;//add textures together and devide brightness in half, as one single texture at full brightness.
	
	////color tint values///////////
	////water
	#if defined (WATER)
	vec4 refacttint = vec4(0.0, 1.0, 0.75, 1.0);//RGBA fake refaction color
	vec4 reflectioncolor = vec4(0.18, 0.25, 0.30, 1.0);//RGBA reflectioncolor color
	vec4 foamcolor = vec4(0.14, 0.17, 0.20, 1.0);//RGBA foamcolor color 
	#else
		////////blood
		#if defined (BLOOD)
		vec4 refacttint = vec4(1.0, 0.0, 0.0, 1.0);//RGBA fake refaction color
		vec4 reflectioncolor = vec4(0.30, 0.14, 0.10, 1.0);//RGBA reflectioncolor color
		vec4 foamcolor = vec4(0.2, 0.09, 0.07, 1.0);//RGBA foamcolor color 
		#else
			////////slime
			#if defined (SLIME)
			vec4 refacttint = vec4(1.0, 0.85, 0.0, 1.0);//RGBA fake refaction color
			vec4 reflectioncolor = vec4(0.30, 0.26, 0.15, 1.0);//RGBA reflectioncolor color
			vec4 foamcolor = vec4(0.2, 0.17, 0.115, 1.0);//RGBA foamcolor color 
			#endif
		#endif
	#endif
	
	///generate reflection
	vec4 Reflectionbase = texture(reflection, (normalize(transpose(tbn) * (uCameraPos.xyz - pixelpos.xyz)).xy) + Nmap * 0.45);//reflection texture interat with generated normal texture
	vec4 Reflectionfinal = clamp(Reflectionbase * reflectioncolor,0.0,1.0);//combine rendered reflection with color tint rgb values
	
	////generate diffuse texture
	vec4 DIffuseypos = texture(Diffuse, GetLiquidscrollposAt(ParallaxMap) * 0.175);//diffuse texture scroll Y positive	and devide brightness in half
	vec4 DIffuseyneg = texture(Diffuse, GetLiquidscrollposAt(ParallaxMap) * 0.3);//diffuse texture scroll y negetive and devide brightness in half
	vec4 DIffuselarge = (DIffuseypos + DIffuseyneg) * 0.25;
	
	////refact diffuse color
	vec4 Refaction = texture(Diffuse, ((Nmap * (-1.5)) + (GetLiquidscrollnegAt(ParallaxMap) * 0.2))) * 0.50 * refacttint;
	vec4 Diffusebase = clamp(DIffuselarge + Refaction + Reflectionfinal,0.0,1.0);//add both diffuse textures and refaction togeter for generated scrolling effect at full brightness.
	
	////generate liquidfall foam
	vec4 Foam1 = texture(foamlayer, GetTopscrollposAt(ParallaxMap));//foam layer scroll speed
	vec4 Foam2 = texture(foamlayer, GetTopscrollposAt(ParallaxMap) * 2.5);//foam layer scroll speed 
	vec4 Foam = (Foam1 + Foam2) * foamcolor;//foam color values must stay under 0.5 for a total texture brightness of 1.0 or under.
	
	//diffuse final color
	vec4 DIffusefinal = clamp(Diffusebase + Foam,0.0,1.0);
	
	material.Base = DIffusefinal;
    material.Normal = GetBumpedNormal(tbn, ParallaxMap);
	material.Bright = texture(brighttexture, ParallaxMap); 
//#if defined(SPECULAR)
    material.Specular = texture(speculartexture, ParallaxMap).rgb;
    //material.Glossiness = uSpecularMaterial.x;
    //material.SpecularLevel = uSpecularMaterial.y;
//#endif 
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

////////////////////////////////////////////////////////////////////////////////
//////////////////////////////base diffuse texture//////////////////////////////

vec2 GetLayerScaleAt(vec2 parallaxMap)//scale base texture
{
	vec2 texcoord = GetLayerposAt(parallaxMap) * 3.0;//Base scale for diffuse and normal textures 						
    return texcoord;
}

vec2 GetLiquidscrollposAt(vec2 parallaxMap)//scroll direction for large base texture
{
	vec2 texcoord = GetLayerScaleAt(parallaxMap);						
	vec2 offset = vec2(0,0);
	offset.y = texcoord.y * 1.5 + (timer * -1.4); //scroll direction and speed    
	offset.x = texcoord.x * 1.5;//scroll direction and speed   
    return(texcoord += offset);
}

vec2 GetLiquidscrollnegAt(vec2 parallaxMap)//scroll direction for large base texture
{
	vec2 texcoord = GetLayerScaleAt(parallaxMap);								
	vec2 offset = vec2(0,0);
	offset.y = texcoord.y + (timer * -0.6); //scroll direction and speed 
	offset.x = texcoord.x;
    return(texcoord += offset);
}

////////////////////////////////////////////////////////////////////////////////
//////////////////////////////top diffuse texture//////////////////////////////
vec2 GetTopscrollposAt(vec2 parallaxMap)//scroll direction for foam texture
{
	vec2 texcoord = GetLayerposAt(parallaxMap);	
	texcoord.x = texcoord.x * 1.25;
	texcoord.y = texcoord.y * 0.5;
	const float pi = 3.14159265358979323846;
	vec2 offset = vec2(0,0);
	//		Frequency         Animation Speed     Amplitude        
	//(sin(pi * 4.05 * (texcoord.x + timer * 0.15)) * 0.025)
	offset.y = texcoord.y + (timer * -0.2) + (sin(pi * 0.4 * (texcoord.x  + timer * 0.01)) * 0.4) + (sin(pi * 2.9 * (texcoord.x + (timer * 0.03))) * 0.15);//scroll direction and speed     
	offset.x = texcoord.x + (timer * 0.01);//scroll direction and speed    
    return(texcoord += offset);
}

////////////////////////////////////////////////////////////////////////////////
/////////////////////Normal texture Generate and normal math ///////////////////
vec3 GetBumpedNormal(mat3 tbn, vec2 ParallaxMap)
{
//#if defined(NORMALMAP)
	vec3 NormalmapA = texture(normaltexture, GetLiquidscrollposAt(ParallaxMap)).xyz;//normalmap for diffuse top layer texture
	vec3 NormalmapB = texture(normaltexture, GetLiquidscrollnegAt(ParallaxMap)).xyz;//normalmap for diffuse top layer texture
	vec3 Normalmap = (NormalmapA + NormalmapB) * 0.5;
		 Normalmap = Normalmap * 255./127. - 128./127.; // Math so "odd" because 0.5 cannot be precisely described in an unsigned format
		 Normalmap.xy *= vec2(1.0, -1.0); //flip Y
    return normalize(tbn * Normalmap);
//#else
  //return normalize(vWorldNormal.xyz);
//#endif
}

////////////////////////////////////////////////////////////////////////////////
///////////////////main multi layer texture scale setup/////////////////////////
vec2 GetLayerposAt(vec2 parallaxMap)
{  	
	vec2 texcoord = parallaxMap;
	texcoord.x = texcoord.x * 0.30;
	texcoord.y = texcoord.y * 0.15;
	vec2 offset = vec2(0,0);		
	const float pi = 3.14159265358979323846;
						 // 	Frequency         Animation Speed     Amplitude        
						 //(sin(pi * 4.05 * (texcoord.x + timer * 0.15)) * 0.025)
	offset.y = texcoord.y + (sin(pi * 0.1 * (texcoord.x + (timer * 0.01))) * 0.5) * (sin(pi * 0.6 * (texcoord.x + timer * 0.015))* 0.5); //scroll direction and speed                    
	offset.x = texcoord.x;
	texcoord += offset;
    return texcoord;													
}																						

////////////////////////////////////////////////////////////////////////////////
/////////////////main parallax texture scale and texcoord setup/////////////////
vec2 GetAutoscaleAt(vec2 currentTexCoords) //////sets the main parallax texture scale size which all the other texture scale values are based on.
{
	vec2 PXCoord = vTexCoord.st;
	PXCoord.x = PXCoord.x * 0.5;//scale main parallax texture here
	PXCoord.y = PXCoord.y * 0.5;//scale main parallax texture here 
    return PXCoord;
}

////////////////////////////////////////////////////////////////////////////////
///////////////////Parallax texture color setup/////////////////////////////////
float GetDisplacementAt(vec2 currentTexCoords)
{
	vec2 texCoord = vTexCoord.st;
	vec2 PXcoord = GetAutoscaleAt(currentTexCoords).xy;
	vec2 offset = vec2(0,0);
	offset.y =  PXcoord.y + (timer * -0.7); //displacement texture scroll direction and speed
	offset.x =  PXcoord.x + (timer * 0.025); //displacement texture scroll direction and speed
	float parallax = texture(Parallax, offset).r;//main parallax texture with adjusted texture offset
    return 1.0 - (parallax);
}

////////////////////////////////////////////////////////////////////////////////
///////////////////Parallax/////////////////////////////////////////////////////
vec2 ParallaxMap(mat3 tbn)
{
    // Calculate fragment view direction in tangent space
	ivec2 texSize = textureSize(tex, 0);
    mat3 invTBN = transpose(tbn);
    vec3 V = normalize(invTBN * (uCameraPos.xyz - pixelpos.xyz));
	vec2 texCoord = vTexCoord.st;
    vec2 PXcoord = GetAutoscaleAt(texCoord).xy;
	vec2 parallaxScale = vec2(15.0);
	float minLayers = 0.0;
    float maxLayers = 1.0;
	float viewscale = 0.0;
	float viewscaleX = float (texSize.x / texSize.y);
	float viewscaleY = float (texSize.y / texSize.x);                 
    float numLayers = mix(minLayers, maxLayers, clamp(abs(V.z), 0.0, 1.0)); // clamp is required due to precision loss

    // calculate the size of each layer
    float layerDepth = 1.0 / numLayers;
    // depth of current layer
    float currentLayerDepth = 0.0;
	
	// parallax auto scale for non 1:1 (x,y) textures
	parallaxScale = parallaxScale / float (max(texSize.y, texSize.x));
	
	// correct the visual parallax effect for non 1:1 (x,y) ratio textures 
	V.y = V.y / max(viewscaleX, viewscaleY);
			 
	// the amount to shift the texture coordinates per layer (from vector P)
    vec2 P = V.xy * parallaxScale;
    vec2 deltaTexCoords = P / numLayers; 
    vec2 currentTexCoords = PXcoord;									
    float currentDepthMapValue = GetDisplacementAt(currentTexCoords);
    while (currentLayerDepth < currentDepthMapValue)
    {
        // shift texture coordinates along direction of P
        currentTexCoords -= deltaTexCoords;

        // get depthmap value at current texture coordinates
        currentDepthMapValue = GetDisplacementAt(currentTexCoords);

        // get depth of next layer
        currentLayerDepth += layerDepth;
    }

	deltaTexCoords *= 0.5;
	layerDepth *= 0.5;

	currentTexCoords += deltaTexCoords;
	currentLayerDepth -= layerDepth;

	const int _reliefSteps = 8;
	int currentStep = _reliefSteps;
	while (currentStep > 0) {
	float currentGetDisplacementAt = GetDisplacementAt(currentTexCoords);
		deltaTexCoords *= 0.5;
		layerDepth *= 0.5;

		if (currentGetDisplacementAt > currentLayerDepth) {
			currentTexCoords -= deltaTexCoords;
			currentLayerDepth += layerDepth;
		}

		else {
			currentTexCoords += deltaTexCoords;
			currentLayerDepth -= layerDepth;
		}
		currentStep--;
	}

	return currentTexCoords;
}

