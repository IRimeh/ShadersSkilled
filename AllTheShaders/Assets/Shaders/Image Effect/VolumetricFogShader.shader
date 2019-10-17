Shader "Hidden/VolumetricFogShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_FogColor("Fog Color", Color) = (1,1,1,1)
		_FogDensity("Fog Density", Range(0.001, 0.1)) = 0.1
		_StepSize("Step Size", Range(0.001, 5)) = 0.1
		_MaxSteps("Max Steps", float) = 64
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
			Tags { "LightMode" = "ForwardAdd" }
			// pass for additional light sources

            CGPROGRAM
			#pragma multi_compile DIRECTIONAL POINT SPOT
			#pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#define SPOT
			#include "Lighting.cginc"

            sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			float3 _BoundsMin;
			float3 _BoundsMax;
			fixed4 _FogColor;
			float _FogDensity;
			float _StepSize;
			float _MaxSteps;

			int _NumSpotLights;
			float3 _SpotLightPositions[16];
			float3 _SpotLightDirections[16];
			float2 _SpotLightRangeAngles[16];
			float4 _SpotLightColors[16];

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 ray : TEXCOORD1;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 viewDir : TEXCOORD1;
				float4 wpos : TEXCOORD2;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.wpos = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir = v.ray;
				return o;
			}

			float2 rayBoxDist(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir)
			{
				float3 t0 = (boundsMin - rayOrigin) / rayDir;
				float3 t1 = (boundsMax - rayOrigin) / rayDir;
				float3 tmin = min(t0, t1);
				float3 tmax = max(t0, t1);

				float dstA = max(max(tmin.x, tmin.y), tmin.z);
				float dstB = min(tmax.x, min(tmax.y, tmax.z));

				float distToBox = max(0, dstA);
				float distInsideBox = max(0, dstB - distToBox);
				return float2(distToBox, distInsideBox);
			}

			float4 raymarchFog(float3 originPos, float3 viewDir, float maxDist, float secondaryMaxDist)
			{
				float4 result = 0;
				float step = 0;
				while (step < _MaxSteps)
				{
					step++;
					float3 pos = originPos + (viewDir * (step * _StepSize)); //Current world position
					bool isInsideLight = false;

					//Iterate over spot lights
					for (int i = 0; i < _NumSpotLights; i++)
					{
						//Check if inside range of spotlight
						if (!isInsideLight && distance(_SpotLightPositions[i], pos) < _SpotLightRangeAngles[i].x)
						{
							float3 a = normalize(_SpotLightDirections[i].xyz);
							float3 b = pos - _SpotLightPositions[i].xyz;
							float dotVal = dot(a, normalize(b));

							//Check if inside angle of spotlight
							if (dotVal > 0)
							{
								float3 midSpotPos = 0;

								float hypotenuse = distance(pos, _SpotLightPositions[i].xyz);
								float adjecent = dot(b, a);
								float angle = acos(adjecent / hypotenuse);

								if (angle * (180.0 / UNITY_PI) < _SpotLightRangeAngles[i].y * 0.5)
								{
									result.rgb += lerp(_FogColor.rgb, _SpotLightColors[i].rgb, _SpotLightColors[i].a * 0.1);
									result.a += _FogDensity;
									isInsideLight = true;
									break;
								}
							}
						}
					}

					//Check if current position isn't inside light cone
					if (!isInsideLight)
					{
						result.rgb += _FogColor.rgb;
						result.a += _FogDensity;
					}

					if (step * _StepSize > maxDist || step * _StepSize > secondaryMaxDist || result.a >= 1)
						break;
				}

				result.rgb /= step;
				return clamp(result, 0, 1);
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				//Sample depth
				float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				float linearDepth = Linear01Depth(nonLinearDepth) * length(i.viewDir);

				//Raymarch box
				float2 rayInfo = rayBoxDist(_BoundsMin, _BoundsMax, _WorldSpaceCameraPos, normalize(i.viewDir));
				float distToBox = rayInfo.x;
				float distInsideBox = rayInfo.y;

				if (distInsideBox > 0 && distToBox < linearDepth) 
				{
					float3 startPos = _WorldSpaceCameraPos + (normalize(i.viewDir) * distToBox);
					float4 fog = raymarchFog(startPos, normalize(i.viewDir), distInsideBox, linearDepth - distToBox);

					col.rgb = lerp(col.rgb, fog, fog.a);
				}

				return col;
            }
            ENDCG
        }
    }
}
