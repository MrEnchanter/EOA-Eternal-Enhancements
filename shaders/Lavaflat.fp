mat3 GetTBN();
vec2 GetAutoscaleAt(vec2 texcoord);
vec2 GetparallaxwavescrollAt(vec2 texcoord);
vec2 ParallaxMap(mat3 tbn); 
vec3 GetBumpedNormal(mat3 tbn, vec2 parallaxMap);
vec2 GetTopdiffusescaleAt(vec2 parallaxMap);
vec2 GetbottomdiffusescaleAt(vec2 parallaxMap);
vec2 GetNormalLiquidscrollposAt(vec2 parallaxMap);
vec2 GetNormalLiquidscrollnegAt(vec2 parallaxMap);
vec2 GetLiquidscrollposAt(vec2 parallaxMap);
vec2 GetLiquidscrollnegAt(vec2 parallaxMap);
vec2 GetLayerposAt(vec2 parallaxMap);

////////////////////////////////////////////////////////////////////////////////
//////////////////material setup////////////////////////////////////////////////
void SetupMaterial(inout Material material)				
{
    mat3 tbn = GetTBN(); 
	vec2 texCoord = vTexCoord.st;
	vec2 ParallaxMap = ParallaxMap(tbn);
	
	////Masktexture////
	vec4 Diffusemasktex = texture(Diffusemask, GetLayerposAt(ParallaxMap));//parallax texture (black / white)
	
	////Normaltexture For bottom layer////
	vec4 NormalmapA = texture(Diffusedistortion, GetNormalLiquidscrollposAt(ParallaxMap) * 0.5);
	vec4 NormalmapB = texture(Diffusedistortion, GetNormalLiquidscrollnegAt(ParallaxMap) * 0.5);
	vec4 NormalmapC = texture(Diffusedistortion, GetNormalLiquidscrollposAt(ParallaxMap) * 3.0);
	vec4 NormalmapD = texture(Diffusedistortion, GetNormalLiquidscrollnegAt(ParallaxMap) * 3.0);
	vec4 Normalmapbase = ((NormalmapA + NormalmapB) * 0.8) + ((NormalmapC + NormalmapD) * 0.15);
	
	////generate diffuse base texture////
	vec4 DiffuseyposL = texture(Diffuse, (Normalmapbase.xy + GetLiquidscrollposAt(ParallaxMap))) * 0.6;//diffuse texture scroll positive and brightness 
	vec4 DiffuseynegL = texture(Diffuse, (-Normalmapbase.xy + GetLiquidscrollnegAt(ParallaxMap))) * 0.6;//diffuse texture scroll negetive and brightness 
	vec4 DiffuseyposXL = texture(Diffuse, (Normalmapbase.xy + GetLiquidscrollposAt(ParallaxMap)) * 0.3) * 0.6;//diffuse texture scroll positive and brightness 
	vec4 DiffuseynegXL = texture(Diffuse, (-Normalmapbase.xy + GetLiquidscrollnegAt(ParallaxMap)) * 0.3) * 0.6;//diffuse texture scroll negetive and brightness 
	vec4 Diffusebase = clamp(DiffuseyposL + DiffuseynegL + DiffuseyposXL + DiffuseynegXL,0.0,1.0);//add diffuse textures togeter for generated effect
	
	////speculartexture////
	vec4 Spectexture = texture(speculartexture, GetTopdiffusescaleAt(ParallaxMap));
	
	////generate diffuse top layer////
	vec4 Diffusetoplayer = Spectexture;//top diffuse texture and scale value
	vec4 Layerglow = vec4(0.35, 0.0, 0.0, 1.0);//RGBA
	vec4 Glowblend = clamp(Layerglow * (clamp(Diffusemasktex * 50.0,0.0,1.0)) - (Diffusemasktex * 0.55),0.0,1.0);
	
	////generate diffuse mask////
	vec4 parallaxwave = texture(Parallax, GetparallaxwavescrollAt(texCoord).xy);//parallax wave texture with parallax wave scroll texcoords
	vec4 white = vec4(1.0, 1.0, 1.0, 1.0);//white color
	vec4 wavecolorfinal = clamp(white - parallaxwave,0.0,1.0);//create inverted parallax texture color
	vec4 Diffusemasked = clamp(Diffusebase - (clamp((Diffusemasktex * 30.0) * wavecolorfinal,0.0,1.0)),0.0,1.0);
	vec4 Diffuselayermasked = Diffusetoplayer * (clamp(Diffusemasktex * 50.0,0.0,1.0));
	
	////generate diffuse color////
	vec4 Diffusefinal = clamp(Diffuselayermasked + Diffusemasked + Glowblend,0.0,1.0);
	
	//// generate brightmap texture////
	vec4 Brightmapmask = clamp(Diffusefinal + 0.6 - (clamp(Diffusemasktex * 30.0,0.0,1.0)) + (clamp(Glowblend * 2.0,0.0,1.0)),0.0,1.0);
	
	////generate specular texure masked////
	vec4 Specfinal = Spectexture * (clamp(Diffusemasktex * 5.0,0.0,1.0));//specular texture values multiplied by the diffuse mask texture ( 0.0 = black / 1.0 = white)

	////materials////
	material.Base = Diffusefinal;
    material.Normal = GetBumpedNormal(tbn, ParallaxMap);
	material.Bright = Brightmapmask; 
//#if defined(SPECULAR)
    material.Specular = Specfinal.rgb;
	//material.Glossiness = uSpecularMaterial.x;
    //material.SpecularLevel = uSpecularMaterial.y;
//#endif
}

////////////////////////////////////////////////////////////////////////////////
////////Tangent/bitangent/normal space to world space transform matrix//////////
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
///////////////////////base diffuse texture animation///////////////////////////
////diffuse normal map
vec2 GetNormalLiquidscrollposAt(vec2 parallaxMap)//scroll direction for large base texture
{
	vec2 texCoord = GetbottomdiffusescaleAt(parallaxMap);							
	vec2 offset = vec2(0,0);
	offset.x = texCoord.x * 1.5 + (timer * 0.1);//scroll direction and speed    
	offset.y = texCoord.y * 1.5;    
    return(texCoord += offset);
}

vec2 GetNormalLiquidscrollnegAt(vec2 parallaxMap)//scroll direction for large base texture
{
	vec2 texCoord = GetbottomdiffusescaleAt(parallaxMap);									
	vec2 offset = vec2(0,0);
	offset.x = texCoord.x + (timer * -0.1);//scroll direction and speed   
	offset.y = texCoord.y;
    return(texCoord += offset);
}
////diffuse color
vec2 GetLiquidscrollposAt(vec2 parallaxMap)//scroll direction for large base texture
{
	vec2 texCoord = GetbottomdiffusescaleAt(parallaxMap);							
	vec2 offset = vec2(0,0);
	offset.y = texCoord.y * 1.5 + (timer * 0.175);//scroll direction and speed  
	offset.x = texCoord.x * 1.5;
    return(texCoord += offset);
}

vec2 GetLiquidscrollnegAt(vec2 parallaxMap)//scroll direction for large base texture
{
	vec2 texCoord = GetbottomdiffusescaleAt(parallaxMap);									
	vec2 offset = vec2(0,0);
	offset.y = texCoord.y + (timer * -0.175);//scroll direction and speed 
	offset.x = texCoord.x;
    return(texCoord += offset);
}

////////////////////////////////////////////////////////////////////////////////
/////////////////////Normal texture Generate and normal math ///////////////////
vec3 GetBumpedNormal(mat3 tbn, vec2 parallaxMap)
{
 //#if defined(NORMALMAP)
	vec3 Diffusemasktex = texture(Diffusemask, GetLayerposAt(parallaxMap)).xyz;//parallax texture (black / white)
	vec3 Toplayernormal = (texture(layermasknormal, GetLayerposAt(parallaxMap)) * 0.5).xyz;//normalmap for Diffusemask mask based on parallax map
	vec3 Normalmap = (texture(normaltexture, GetTopdiffusescaleAt(parallaxMap)) * 0.5).xyz;//normalmap for diffuse top layer texture
	vec3 Normalmapmaksed = Normalmap * clamp(Diffusemasktex * 20.0,0.0,1.0);//remove diffuse normalmap color based on layermask brightness
	vec3 Normalcombined = clamp(Toplayernormal + Normalmapmaksed,0.0,1.0);//add the adjusted diffuse normal map color to the layermask normal map color
		 Normalcombined = Normalcombined * 255./127. - 128./127.; // Math so "odd" because 0.5 cannot be precisely described in an unsigned format
		 Normalcombined.xy *= vec2(1.0, -1.0); //flip Y
    return normalize(tbn * Normalcombined);
//#else
  //return normalize(vWorldNormal.xyz);
//#endif
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////layer mask texture scale////////////////////////////////
vec2 GetLayerposAt(vec2 parallaxMap)
{        																				
    return parallaxMap * 0.75;//change scale of layer mask texture here  -----------------															
}																							//
float GetLayerscaleAt(vec2 currentTexCoords)												//numbers must match
{																							//
    return 0.75;//change scale of Layer mask texture here -------------------------------------
}

////////////////////////////////////////////////////////////////////////////////
///////////////top layer diffuse texture scale//////////////////////////////////
vec2 GetTopdiffusescaleAt(vec2 parallaxMap)
{																		
    return parallaxMap * 7.0;//change scale of top diffuse texture here 
}

////////////////////////////////////////////////////////////////////////////////
///////////////bottom diffuse texture scale/////////////////////////////////////
vec2 GetbottomdiffusescaleAt(vec2 parallaxMap)
{																			
    return parallaxMap * 3.0;//change scale of bottom diffuse texture here
}

////////////////////////////////////////////////////////////////////////////////
/////////////////main parallax texture scale and texcoord setup/////////////////
vec2 GetAutoscaleAt(vec2 currentTexCoords) //////sets the main parallax texture scale size which all the other texture scale values are based on.
{
	vec2 PXCoord = vTexCoord.st;
	PXCoord.x = PXCoord.x * 0.2;//scale main parallax texture here
	PXCoord.y = PXCoord.y * 0.2;//scale main parallax texture here 
	vec2 offset = vec2(0,0);
	const float pi = 3.14159265358979323846;
	//		Frequency         Animation Speed     Amplitude        
	//(sin(pi * 4.05 * (texcoord.x + (timer * 0.15))) * 0.025)
	offset.y = sin(pi * (PXCoord.x + (timer * 0.05))) * 0.05;                     
	offset.x = sin(pi * (PXCoord.y + (timer * 0.05))) * 0.05;
	PXCoord += offset;															
    return PXCoord;
}

////////////////////////////////////////////////////////////////////////////////
///////////////////Parallax texture color setup/////////////////////////////////

vec2 GetparallaxwavescrollAt(vec2 currentTexCoords) //////parralax wave texture texcoords.
{
	vec2 texCoord = vTexCoord.st;
	vec2 PXCoord = (GetAutoscaleAt(currentTexCoords).xy) * 0.5;
	vec2 offset = vec2(0,0);
	offset.y =  PXCoord.y + (timer * 0.3); //parallax texture scroll direction and speed
	offset.x =  PXCoord.x + (timer * 0.025); //parallax texture scroll direction and speed
	PXCoord += offset;															
    return PXCoord;
}

float GetDisplacementAt(vec2 currentTexCoords)//adjust parallax color and animation texcoord here
{
	vec2 texCoord = vTexCoord.st;
	vec2 PXcoord = GetAutoscaleAt(currentTexCoords).xy;
	float parallax = texture(Parallax, GetparallaxwavescrollAt(currentTexCoords).xy).r;//main parallax texture with parallax wave scroll texcoords
	float Diffusemask = texture(Diffusemask, (PXcoord * GetLayerscaleAt(currentTexCoords))).r;//top layer parallax texture
	float parallaxwave = clamp(parallax - Diffusemask,0.0,1.0);//clamp used to keep values between 0 and 1
	float parallaxcombined = clamp(parallaxwave + Diffusemask,0.0,1.0);//blend texture brightness and keep values between 0 and 1
    return 1.0 - (parallaxcombined);
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
	vec2 parallaxScale = vec2(2.5);
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