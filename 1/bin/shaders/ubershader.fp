/**
 * ubershader.fp
 * 
 * Fragment shader for the "ubershader" which lights the contents of the gbuffer. This shader
 * samples from the gbuffer and then computes lighting depending on the material type of this 
 * fragment.
 * 
 * Written for Cornell CS 5625 (Interactive Computer Graphics).
 * Copyright (c) 2012, Computer Science Department, Cornell University.
 * 
 * @author Asher Dunn (ad488), Sean Ryan (ser99), Ivo Boyadzhiev (iib2)
 * @date 2012-03-24
 */
 
 #define M_PI 3.141568

/* Copy the IDs of any new materials here. */
const int UNSHADED_MATERIAL_ID = 1;
const int LAMBERTIAN_MATERIAL_ID = 2;
const int BLINNPHONG_MATERIAL_ID = 3;
const int COOKTORRANCE_MATERIAL_ID = 4;
const int ISOTROPIC_WARD_MATERIAL_ID = 5;
const int ANISOTROPIC_WARD_MATERIAL_ID = 6;

/* Some constant maximum number of lights which GLSL and Java have to agree on. */
#define MAX_LIGHTS 40

/* Samplers for each texture of the GBuffer. */
uniform sampler2DRect DiffuseBuffer;
uniform sampler2DRect PositionBuffer;
uniform sampler2DRect MaterialParams1Buffer;
uniform sampler2DRect MaterialParams2Buffer;
uniform sampler2DRect SilhouetteBuffer; // Unused in PA1.

/* Uniform specifying the sky (background) color. */
uniform vec3 SkyColor;

/* Uniforms describing the lights. */
uniform int NumLights;
uniform vec3 LightPositions[MAX_LIGHTS];
uniform vec3 LightAttenuations[MAX_LIGHTS];
uniform vec3 LightColors[MAX_LIGHTS];

/* Decodes a vec2 into a normalized vector See Renderer.java for more info. */
vec3 decode(vec2 v)
{
	vec3 n;
	n.z = 2.0 * length(v.xy) - 1.0;
	n.xy = normalize(v.xy) * sqrt(1.0 - n.z*n.z);
	return n;
}

/**
 * Performs Lambertian shading on the passed fragment data (color, normal, etc.) for a single light.
 * 
 * @param diffuse The diffuse color of the material at this fragment.
 * @param position The eyespace position of the surface at this fragment.
 * @param normal The eyespace normal of the surface at this fragment.
 * @param lightPosition The eyespace position of the light to compute lighting from.
 * @param lightColor The color of the light to apply.
 * @param lightAttenuation A vector of (constant, linear, quadratic) attenuation coefficients for this light.
 * 
 * @return The shaded fragment color; for Lambertian, this is `lightColor * diffuse * n_dot_l`.
 */
vec3 shadeLambertian(vec3 diffuse, vec3 position, vec3 normal, vec3 lightPosition, vec3 lightColor, vec3 lightAttenuation)
{
	vec3 lightDirection = normalize(lightPosition - position);
	float ndotl = max(0.0, dot(normal, lightDirection));
	
	float r = length(lightPosition - position);
	float attenuation = 1.0 / dot(lightAttenuation, vec3(1.0, r, r * r));
	
	return lightColor * attenuation * diffuse * ndotl;
}

/**
 * Performs Blinn-Phong shading on the passed fragment data (color, normal, etc.) for a single light.
 *  
 * @param diffuse The diffuse color of the material at this fragment.
 * @param specular The specular color of the material at this fragment.
 * @param exponent The Phong exponent packed into the alpha channel. 
 * @param position The eyespace position of the surface at this fragment.
 * @param normal The eyespace normal of the surface at this fragment.
 * @param lightPosition The eyespace position of the light to compute lighting from.
 * @param lightColor The color of the light to apply.
 * @param lightAttenuation A vector of (constant, linear, quadratic) attenuation coefficients for this light.
 * 
 * @return The shaded fragment color.
 */
vec3 shadeBlinnPhong(vec3 diffuse, vec3 specular, float exponent, vec3 position, vec3 normal,
	vec3 lightPosition, vec3 lightColor, vec3 lightAttenuation)
{
	vec3 viewDirection = -normalize(position);
	vec3 lightDirection = normalize(lightPosition - position);
	vec3 halfDirection = normalize(lightDirection + viewDirection);
		
	float ndotl = max(0.0, dot(normal, lightDirection));
	float ndoth = max(0.0, dot(normal, halfDirection));
	
	float pow_ndoth = (ndotl > 0.0 && ndoth > 0.0 ? pow(ndoth, exponent) : 0.0);

	float r = length(lightPosition - position);
	float attenuation = 1.0 / dot(lightAttenuation, vec3(1.0, r, r * r));
	
	return lightColor * attenuation * (diffuse * ndotl + specular * pow_ndoth);
}

float getSchlickApprox(float theta, float N){
		float t0 = pow((N-1.0)/(N+1.0),2.0);
		return (t0 + (1.0-t0)*(pow(1.0-cos(theta),5.0)));
}

/**
 * Performs Cook-Torrance shading on the passed fragment data (color, normal, etc.) for a single light.
 * 
 * @param diffuse The diffuse color of the material at this fragment.
 * @param specular The specular color of the material at this fragment.
 * @param m The microfacet rms slope at this fragment.
 * @param n The index of refraction at this fragment.
 * @param position The eyespace position of the surface at this fragment.
 * @param normal The eyespace normal of the surface at this fragment.
 * @param lightPosition The eyespace position of the light to compute lighting from.
 * @param lightColor The color of the light to apply.
 * @param lightAttenuation A vector of (constant, linear, quadratic) attenuation coefficients for this light.
 * 
 * @return The shaded fragment color.
 */
vec3 shadeCookTorrance(vec3 diffuse, vec3 specular, float m, float n, vec3 position, vec3 normal,
	vec3 lightPosition, vec3 lightColor, vec3 lightAttenuation)
{
	//view direction
	vec3 v = -normalize(position);
	
	//light direction
	vec3 l = normalize(lightPosition - position);
	
	//half direction
	vec3 h = normalize(l + v);	

	// DONE PA1: Complete the Cook-Torrance shading function.
	
	float ndotv = max(0.0, dot(normal,  v));
	float ndoth = max(0.0, dot(normal,  h));
	float ndotl = max(0.0, dot(normal, l));
	
	//fresnal equation
	float theta = acos(ndotl);
	float f = getSchlickApprox(theta,n);
	
	// facet distribution
	float a = acos(dot(normal,h));
	float e_exp = -pow((tan(a)/m),2.0);
	float e_term = exp(e_exp);
	float m_term = 4.0*m*m*pow(cos(a),4.0);
	float d = e_term/m_term;
	
	// masking/shadowing
	float temp = 2.0*ndoth/dot(v,h);
	float g = min(temp*ndotv,temp*ndotl);
	g = min(1.0,g);
	

	
	vec3 spec = (specular/M_PI)*(f*d*g)/(ndotl*ndotv);
	
	if(spec.x > 0){
		return vec3(1.0,0.0,0.0);
	} else {
		return vec3(0.0,1.0,0.0);
	}
	
	
	float r = length(lightPosition - position);
	float attenuation = 1.0 / dot(lightAttenuation, vec3(1.0, r, r * r));
	
	vec3 finalColor = lightColor * attenuation * ndotl * (diffuse + spec);
	
	return finalColor;
	
}

/**
 * Performs Anisotropic Ward shading on the passed fragment data (color, normal, etc.) for a single light.
 * 
 * @param diffuse The diffuse color of the material at this fragment.
 * @param specular The specular color of the material at this fragment.
 * @param alpha_x The surface roughness in x.
 * @param alpha_y The surface roughness in y. 
 * @param position The eyespace position of the surface at this fragment.
 * @param normal The eyespace normal of the surface at this fragment.
 * @param tangent The eyespace tangent vector at this fragment.
 * @param bitangent The eyespace bitangent vector at this fragment.
 * @param lightPosition The eyespace position of the light to compute lighting from.
 * @param lightColor The color of the light to apply.
 * @param lightAttenuation A vector of (constant, linear, quadratic) attenuation coefficients for this light.
 * 
 * @return The shaded fragment color.
 */
vec3 shadeAnisotropicWard(vec3 diffuse, vec3 specular, float alphaX, float alphaY, vec3 position, vec3 normal,
	vec3 tangent, vec3 bitangent, vec3 lightPosition, vec3 lightColor, vec3 lightAttenuation)
{
	vec3 viewDirection = -normalize(position);
	vec3 lightDirection = normalize(lightPosition - position);
	vec3 halfDirection = normalize(lightDirection + viewDirection);
	
	vec3 finalColor = vec3(0.0);

	// DONE PA1: Complete the Anisotropic Ward shading function.
	float ndotv = max(0.0, dot(normal,  viewDirection));
	float ndoth = max(0.0, dot(normal,  halfDirection));
	float ndotl = max(0.0, dot(normal, lightDirection));
	
	float num_x = pow(dot(halfDirection,   tangent) / alphaX, 2.0);
	float num_y = pow(dot(halfDirection, bitangent) / alphaY, 2.0);
	
	float exponent = exp(-2.0 * ((num_x + num_y) / (1.0 + ndoth)));
	
	float spec_term = ((ndotl <= 0.0) || (ndotv <= 0.0) ? 0.0 : exponent / (4.0 * M_PI * alphaX * alphaY * sqrt(ndotl * ndotv)));
	
	float r = length(lightPosition - position);
	float attenuation = 1.0 / dot(lightAttenuation, vec3(1.0, r, r * r));
	
	finalColor = lightColor * attenuation * ndotl * (diffuse + spec_term * specular);
	
	return finalColor;
}

/**
 * Performs Isotropic Ward shading on the passed fragment data (color, normal, etc.) for a single light.
 * 
 * @param diffuse The diffuse color of the material at this fragment.
 * @param specular The specular color of the material at this fragment.
 * @param alpha The surface roughness. 
 * @param position The eyespace position of the surface at this fragment.
 * @param normal The eyespace normal of the surface at this fragment.
 * @param lightPosition The eyespace position of the light to compute lighting from.
 * @param lightColor The color of the light to apply.
 * @param lightAttenuation A vector of (constant, linear, quadratic) attenuation coefficients for this light.
 * 
 * @return The shaded fragment color.
 */
vec3 shadeIsotropicWard(vec3 diffuse, vec3 specular, float alpha, vec3 position, vec3 normal,
	vec3 lightPosition, vec3 lightColor, vec3 lightAttenuation)
{
	vec3 viewDirection  = -normalize(position);
	vec3 lightDirection =  normalize(lightPosition - position);
	vec3 halfDirection  =  normalize(lightDirection + viewDirection);
	
	vec3 finalColor = vec3(0.0);

	// DONE PA1: Complete the Isotropic Ward shading function.
	float ndotv = max(0.0, dot(normal,  viewDirection));
	float ndoth = max(0.0, dot(normal,  halfDirection));
	float ndotl = max(0.0, dot(normal, lightDirection));
	
	float theta = acos(ndoth);
	float tan_theta = tan(theta);
	
	float alpha_sqr = pow(alpha, 2.0);
	float exponent = exp(-(pow(tan_theta, 2.0) / alpha_sqr));
	
	float r = length(lightPosition - position);
	float attenuation = 1.0 / dot(lightAttenuation, vec3(1.0, r, r * r));
	
	float spec_term = (ndotl <= 0.0) || (ndotv <= 0.0) ? 0.0 : exponent / (4.0 * M_PI * alpha_sqr * sqrt(ndotl * ndotv));
	
	finalColor = lightColor * attenuation * ndotl * (diffuse + spec_term * specular);
	
	return finalColor;
}


void main()
{
	/* Sample gbuffer. */
	vec3 diffuse         = texture2DRect(DiffuseBuffer, gl_FragCoord.xy).xyz;
	vec3 position        = texture2DRect(PositionBuffer, gl_FragCoord.xy).xyz;
	vec4 materialParams1 = texture2DRect(MaterialParams1Buffer, gl_FragCoord.xy);
	vec4 materialParams2 = texture2DRect(MaterialParams2Buffer, gl_FragCoord.xy);
	vec3 normal          = decode(vec2(texture2DRect(DiffuseBuffer, gl_FragCoord.xy).a,
	                                   texture2DRect(PositionBuffer, gl_FragCoord.xy).a));
	
	/* Initialize fragment to black. */
	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);

	/* Branch on material ID and shade as appropriate. */
	int materialID = int(materialParams1.x);

	if (materialID == 0)
	{
		/* Must be a fragment with no geometry, so set to sky (background) color. */
		gl_FragColor = vec4(SkyColor, 1.0);
	}
	else if (materialID == UNSHADED_MATERIAL_ID)
	{
		/* Unshaded material is just a constant color. */
		gl_FragColor.rgb = diffuse;
	}
	
	// DONE PA1: Add logic to handle all other material IDs. Remember to loop over all NumLights.
	else
	if(materialID == BLINNPHONG_MATERIAL_ID)
	{
		vec3 result = vec3(0.0);
		for(int i = 0; i < NumLights; i++){
			vec3 shade = shadeBlinnPhong(diffuse, materialParams2.rgb, materialParams2.a, position, normal, LightPositions[i], LightColors[i], LightAttenuations[i]);
			result +=  shade;
		}
		gl_FragColor.rgb = result;
	}
	else
	if(materialID == LAMBERTIAN_MATERIAL_ID)
	{
		vec3 result = vec3(0.0);
		for(int i = 0; i < NumLights; i++){
			vec3 shade = shadeLambertian(diffuse, position, normal, LightPositions[i], LightColors[i], LightAttenuations[i]);
			result +=  shade;
		}
		gl_FragColor.rgb = result;
		
	}else if (materialID == COOKTORRANCE_MATERIAL_ID){
		vec3 result = vec3(0.0);
		for(int i = 0; i < NumLights; i++){
			vec3 shade = shadeCookTorrance(diffuse,  materialParams2.xyz, materialParams1.y, materialParams1.z, position, normal,
			LightPositions[i], LightColors[i], LightAttenuations[i]);
			result += shade;
		}
		gl_FragColor.rgb = result;
		
	}
	
	else if(materialID == ISOTROPIC_WARD_MATERIAL_ID)
	{
		vec3 result = vec3(0.0);
		for(int i = 0; i < NumLights; i++){
			vec3 shade = shadeIsotropicWard(diffuse, materialParams2.rgb, materialParams2.a, position,
				normal, LightPositions[i], LightColors[i], LightAttenuations[i]);
			result += shade;
		}
		gl_FragColor.rgb = result;
	}
	else
	if(materialID == ANISOTROPIC_WARD_MATERIAL_ID)
	{
		vec3 result = vec3(0.0);
		
	    vec3 tangent = decode(vec2(materialParams1.a,
	    						   materialParams2.a));
	    tangent -= dot(tangent, normal) * normal;
	    
		vec3 bitangent = cross(normal, tangent);
		 
		if(int(materialParams1.x) < 0){
			bitangent = bitangent * -1.0;
		}
		
		for(int i = 0; i < NumLights; i++){
			vec3 shade = shadeAnisotropicWard(diffuse, materialParams2.rgb, materialParams1.g, materialParams1.b, position,
										normal, tangent, bitangent, LightPositions[i], LightColors[i], LightAttenuations[i]);
			result += shade;
		}
		gl_FragColor.rgb = result;
	}
	else
	{
		/* Unknown material, so just use the diffuse color. */
		gl_FragColor.rgb = diffuse;
	}
	
}