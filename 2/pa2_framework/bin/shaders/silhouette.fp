/**
 * silhouette.fp
 * 
 * Fragment shader for calculating silhouette edges as described in Decaudin's 1996 paper.
 * 
 * Written for Cornell CS 5625 (Interactive Computer Graphics).
 * Copyright (c) 2012, Computer Science Department, Cornell University.
 * 
 * @author Asher Dunn (ad488)
 * @date 2012-04-01
 */

uniform sampler2DRect DiffuseBuffer;
uniform sampler2DRect PositionBuffer;

/* Decodes a vec2 into a normalized vector See Renderer.java for more info. */
vec3 decode(vec2 v)
{
	vec3 n;
	n.z = 2.0 * dot(v.xy, v.xy) - 1.0;
	n.xy = normalize(v.xy) * sqrt(1.0 - n.z*n.z);
	return n;
}

/**
 * Samples from position and normal buffer and returns (nx, ny, nz, depth) packed into one vec4.
 */
vec4 sample(vec2 coord)
{
	vec3 n = decode(vec2(texture2DRect(DiffuseBuffer, coord).a, texture2DRect(PositionBuffer, coord).a));
	return vec4(n, texture2DRect(PositionBuffer, coord).z);
}

void main()
{
	// TODO PA2: Take a 3x3 sample of positions and normals and perform edge/crease estimation as in [Decaudin96].
	
	vec2 c = gl_FragCoord.xy;
	vec4 A = sample(c + vec2(-1.0, -1.0)),
	     B = sample(c + vec2( 0.0, -1.0)),
	     C = sample(c + vec2( 1.0, -1.0)),
	     D = sample(c + vec2(-1.0,  0.0)),
	     E = sample(c + vec2( 1.0,  0.0)),
	     F = sample(c + vec2(-1.0,  1.0)),
	     G = sample(c + vec2( 0.0,  1.0)),
	     H = sample(c + vec2( 1.0,  1.0)),
	     X = sample(c);
	
	vec4 g = abs(A - X) + 2 * abs(B - X) + abs(C - X) + 2 * abs(D - X) +
		     2 * abs(E - X) + abs(F - X) + 2 * abs(G - X) + abs(H - X);
	
	gl_FragColor = g;
}
