Shader "Hidden/VolumetricFogShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		[Toggle]_Use3DFogTexture("Use 3D Fog Texture", float) = 0
		_FogVolume("Fog Volume Texture", 3D) = "white" {}
		_CookieTextures("Cookie Textures", 2DArray) = "" {}
		_FogColor("Fog Color", Color) = (1,1,1,1)
		[Toggle]_SingleFogColor("Single Fog Color", float) = 0
		_FogDensity("Fog Density", Range(0.001, 0.05)) = 0.1
		_StepSize("Step Size", Range(0.001, 5)) = 0.1
		_MaxSteps("Max Steps", float) = 64
		_CutOff("Cut-Off Value", Range(0, 0.99)) = 0.5

		[Header(Movement Variables)]
		_MovementDirection("Movement Direction", Vector) = (1, 1, 0, 0)
		_MovementSpeed("Movement Speed", Range(0, 1)) = 0.5
		_DetailMovementSpeed("Detail Movement Speed", Range(0, 2)) = 1

		[Header(Channel Specific Variables)]
		_Tiling("Tiling", Range(0.001, 0.1)) = 0.01
		_Channel0("Channel0 Weight", Range(0, 1)) = 0.8
		_Channel1("Channel1 Weight", Range(0, 1)) = 0.4
		_Channel2("Channel2 Weight", Range(0, 1)) = 0.2
		_DetailWeight("Detail Weight", Range(0, 1)) = 0.5
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
			#pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler3D _FogVolume;
			float3 _BoundsMin;
			float3 _BoundsMax;
			fixed4 _FogColor;
			float _FogDensity;
			float _StepSize;
			float _MaxSteps;
			bool _Use3DFogTexture;
			float _SingleFogColor;

			//Spotlights
			uniform int _NumSpotLights;
			float3 _SpotLightPositions[16];
			float3 _SpotLightDirections[16];
			float3 _SpotLightUpDirections[16];
			float3 _SpotLightRangeAngles[16];
			float4 _SpotLightColors[16];
			int _CookieIndices[16];
			//Point lights
			uniform int _NumPointLights;
			float3 _PointLightPositions[16];
			float4 _PointLightColors[16];
			float4 _PointLightRangeIntensity[16];

			float _CutOff;
			//Movement variables
			float3 _MovementDirection;
			float _MovementSpeed;
			float _DetailMovementSpeed;

			//Channel vairables
			float _Tiling;
			float _Channel0;
			float _Channel1;
			float _Channel2;
			float _DetailWeight;

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


			UNITY_DECLARE_TEX2DARRAY(_CookieTextures);

			void NoFogVolume(float3 originPos, float3 viewDir, float maxDist, float secondaryMaxDist, out float4 result, out float step)
			{
				result = 0;
				step = 0;

				[loop]
				while (step < _MaxSteps)
				{
					step++;
					float3 pos = originPos + (viewDir * (step * _StepSize)); //Current world position
					bool isInsideLight = false;

					//Iterate over spot lights
					for (int i = 0; i < _NumSpotLights; i++)
					{
						float3 a = normalize(_SpotLightDirections[i].xyz);
						float3 b = pos - _SpotLightPositions[i].xyz;
						float dotVal = dot(a, normalize(b));

						float3 midSpotPos = 0;

						float hypotenuse = distance(pos, _SpotLightPositions[i].xyz);
						float adjecent = dot(b, a);
						float angle = acos(adjecent / hypotenuse);

						//Check if inside range of spotlight
						if (angle * (180.0 / UNITY_PI) < _SpotLightRangeAngles[i].y * 0.5)
						{
							//Cookie calculation
							float texVal = 1;
							if (_CookieIndices[i] < 999.0)
							{
								float3 middlePos = _SpotLightPositions[i].xyz + (_SpotLightDirections[i].xyz * adjecent);
								float3 diffVec = pos - middlePos;
								float3 spotLightRightDirection = cross(_SpotLightUpDirections[i].xyz, _SpotLightDirections[i].xyz);
								float h = length(diffVec);
								float o = dot(diffVec, _SpotLightUpDirections[i].xyz);
								float a = dot(diffVec, normalize(spotLightRightDirection));
								float divisionValue = (tan((_SpotLightRangeAngles[i].y * 0.5) * (UNITY_PI / 180.0)) * adjecent) * 2;
								float2 uvs = ((float2(a, o) / divisionValue) + float2(0.5, 0.5));
								texVal = UNITY_SAMPLE_TEX2DARRAY(_CookieTextures, float3(uvs.x, uvs.y, round(_CookieIndices[i])));
							}

							//Strength calculation
							float strength = (1 - min((adjecent / _SpotLightRangeAngles[i].x), 1));
							result.rgb += lerp(_FogColor.rgb, _SpotLightColors[i].rgb, _SpotLightColors[i].a * _SpotLightRangeAngles[i].z * strength * texVal.r);
							isInsideLight = true;
						}
					}

					//Iterate over point lights
					for (int i = 0; i < _NumPointLights; i++)
					{
						float dist = distance(pos, _PointLightPositions[i].xyz);
						if (dist < _PointLightRangeIntensity[i].x)
						{
							float strength = 1 - (dist / _PointLightRangeIntensity[i].x);
							result.rgb += lerp(_FogColor.rgb, _PointLightColors[i].rgb, _PointLightColors[i].a * _PointLightRangeIntensity[i].y * strength);
							isInsideLight = true;
						}
					}

					//Check if current position isn't inside light cone
					if (!isInsideLight)
					{
						result.rgb += _FogColor.rgb;
					}
					result.a += _FogDensity;

					if (step * _StepSize > maxDist || step * _StepSize > secondaryMaxDist || result.a >= 1)
						break;
				}
			}

			void WithFogVolume(float3 originPos, float3 viewDir, float maxDist, float secondaryMaxDist, out float4 result, out float stepVal, out float densityStepVal)
			{
				result = 0;
				stepVal = 0;
				densityStepVal = 0;

				float3 offset = _MovementDirection * _Time.x * _MovementSpeed * 3;
				float3 detailOffset = _MovementDirection * _Time.x * _MovementSpeed * 3 * (_DetailMovementSpeed * 5);

				[loop]
				while (stepVal < _MaxSteps)
				{
					float3 pos = originPos + (viewDir * (stepVal * _StepSize)); //Current world position
					float insideLightVal = 1;

					//Calculate density
					float4 texVal = float4(1, 1, 1, 1) - tex3D(_FogVolume, pos * _Tiling + offset);
					float totalWeight = _Channel0 + _Channel1 + _Channel2 - _DetailWeight;
					float weight = (texVal.r * _Channel0 + texVal.g * _Channel1 + texVal.b * _Channel2 - (1 - texVal.a) * _DetailWeight) / totalWeight;
					float density = weight;

					//Iterate over spot lights
					for (int i = 0; i < _NumSpotLights; i++)
					{
						float3 a = normalize(_SpotLightDirections[i].xyz);
						float3 b = pos - _SpotLightPositions[i].xyz;
						float dotVal = dot(a, normalize(b));

						float3 midSpotPos = 0;

						float hypotenuse = distance(pos, _SpotLightPositions[i].xyz);
						float adjecent = dot(b, a);
						float angle = acos(adjecent / hypotenuse);

						//Check if inside range of spotlight
						if (angle * (180.0 / UNITY_PI) < _SpotLightRangeAngles[i].y * 0.5)
						{
							//Cookie calculation
							float texVal = 1;
							if (_CookieIndices[i] < 999.0)
							{
								float3 middlePos = _SpotLightPositions[i].xyz + (_SpotLightDirections[i].xyz * adjecent);
								float3 diffVec = pos - middlePos;
								float3 spotLightRightDirection = cross(_SpotLightUpDirections[i].xyz, _SpotLightDirections[i].xyz);
								float h = length(diffVec);
								float o = dot(diffVec, _SpotLightUpDirections[i].xyz);
								float a = dot(diffVec, normalize(spotLightRightDirection));
								float divisionValue = (tan((_SpotLightRangeAngles[i].y * 0.5) * (UNITY_PI / 180.0)) * adjecent) * 2;
								float2 uvs = ((float2(a, o) / divisionValue) + float2(0.5, 0.5));
								texVal = UNITY_SAMPLE_TEX2DARRAY(_CookieTextures, float3(uvs.x, uvs.y, round(_CookieIndices[i])));
							}

							//Strength calculation
							float strength = (1 - min((adjecent / _SpotLightRangeAngles[i].x), 1));
							float val = _SpotLightColors[i].a * _SpotLightRangeAngles[i].z * strength * texVal.r * density;
							result.rgb += lerp(_FogColor.rgb * density, _SpotLightColors[i].rgb, val);
							insideLightVal = 0;
						}
					}

					//Iterate over point lights
					for (int i = 0; i < _NumPointLights; i++)
					{
						float dist = distance(pos, _PointLightPositions[i].xyz);
						if (dist < _PointLightRangeIntensity[i].x)
						{
							float strength = pow(min(max(1 - (dist / _PointLightRangeIntensity[i].x), 0), 1), 1);
							float val = _PointLightColors[i].a * _PointLightRangeIntensity[i].y * strength * density;
							result.rgb += lerp(float3(0,0,0), _PointLightColors[i].rgb, val);
							insideLightVal = 1 - val;// step(dist, _PointLightRangeIntensity[i].x);
						}
					}

					result.rgb += lerp(float3(0, 0, 0), _FogColor.rgb * density, insideLightVal);
					result.a += _FogDensity * density;
					stepVal++;
					densityStepVal += density;

					if (stepVal * _StepSize > maxDist || stepVal * _StepSize > secondaryMaxDist || result.a >= 2)
						break;
				}
			}

			float4 raymarchFog(float3 originPos, float3 viewDir, float maxDist, float secondaryMaxDist)
			{
				float4 result = 0;
				float stepVal = 0;
				float densityStepVal = 0;

				if (_Use3DFogTexture)
				{
					WithFogVolume(originPos, viewDir, maxDist, secondaryMaxDist, result, stepVal, densityStepVal);
				}
				else
				{
					NoFogVolume(originPos, viewDir, maxDist, secondaryMaxDist, result, stepVal);
				}

				result.rgb /= lerp(stepVal, densityStepVal, step(0.5, _SingleFogColor));
				return clamp(result, 0, 1);
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				//Sample depth
				float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				float linearDepth = Linear01Depth(nonLinearDepth)* length(i.viewDir);

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
