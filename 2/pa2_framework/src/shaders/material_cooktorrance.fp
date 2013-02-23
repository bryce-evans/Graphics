/**
 * material_cooktorrance.fp
 * 
 * Fragment shader which writes material information needed for Blinn-Phong shading to
 * the gbuffer.
 * 
 * Written for Cornell CS 5625 (Interactive Computer Graphics).
 * Copyright (c) 2012, Computer Science Department, Cornell University.
 * 
 * @author Asher Dunn (ad488), Sean Ryan (ser99)
 * @date 2013-01-29
 */

/* ID of Cook-Torrance material, so the lighting shader knows what material
 * this pixel is. */
const int COOKTORRANCE_MATERIAL_ID = 4;

/* Material properties passed from the application. */
uniform vec3 DiffuseColor;
uniform vec3 SpecularColor;
uniform float M;
uniform float N;

/* Textures and flags for whether they exist. */
uniform sampler2D DiffuseTexture;
uniform sampler2D SpecularTexture;
uniform sampler2D MTexture;
uniform sampler2D NTexture;

uniform bool HasDiffuseTexture;
uniform bool HasSpecularTexture;
uniform bool HasMTexture;
uniform bool HasNTexture;

/* Environment cube map index (0 means not to use environment lighting) */
uniform int CubeMapIndex;

/* Fragment position and normal, and texcoord, from vertex shader. */
varying vec3 EyespacePosition;
varying vec3 EyespaceNormal;
varying vec2 TexCoord;

/* Encodes a normalized vector as a vec2. See Renderer.java for more info. */
vec2 encode(vec3 n)
{
	return normalize(n.xy) * sqrt(0.5 * n.z + 0.5);
}

void main()
{
	// TODO PA1: Store diffuse color, position, encoded normal, material ID, and all other useful data in the g-buffer.
	// TODO PA2: Store the cube map index in the g-buffer.
	
	gl_FragData[0] = gl_FragData[1] = gl_FragData[2] = gl_FragData[3] = vec4(1.0);		
}
