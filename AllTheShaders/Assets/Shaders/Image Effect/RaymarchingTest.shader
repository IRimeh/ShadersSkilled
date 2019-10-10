Shader "Hidden/RaymarchingTest"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
		[NoScaleOffset]
		_3DNoiseTex("3D Noise Texture", 3D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_ShadowColor("Shadow Color", Color) = (1,1,1,1)
		_CutOff("Cut-Off Value", Range(0, 0.99)) = 0.5
		_Density("Density", Range(0, 1)) = 0.1

		[Header(Movement Variables)]
		_MovementDirection("Movement Direction", Vector) = (1, 1, 0, 0)
		_MovementSpeed("Movement Speed", Range(0, 1)) = 0.5
		_DetailMovementSpeed("Detail Movement Speed", Range(0, 2)) = 1

		[Header(Channel Specific Variables)]
		_Channel0("Channel0 Weight", Range(0, 1)) = 0.8
		_Channel0Tiling("Channel0 Tiling", Vector) = (1,1,1)
		_Channel1("Channel1 Weight", Range(0, 1)) = 0.4
		_Channel1Tiling("Channel1 Tiling", Vector) = (1,1,1)
		_Channel2("Channel2 Weight", Range(0, 1)) = 0.2
		_Channel2Tiling("Channel2 Tiling", Vector) = (1,1,1)
		_DetailWeight("Detail Weight", Range(0, 1)) = 0.5
		_DetailTiling("Detail Tiling", Vector) = (1,1,1)

		[Header(Debug Mode)]
		[Toggle]_Debug("Debug", int) = 0
	}
		SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler3D _3DNoiseTex;
			float4 _Color;
			float4 _ShadowColor;
			float3 _BoundsMin;
			float3 _BoundsMax;
			float3 _NoiseTiling;
			float _CutOff;
			float _Density;

			//Movement variables
			float3 _MovementDirection;
			float _MovementSpeed;
			float _DetailMovementSpeed;

			//Channel vairables
			float _Channel0;
			float3 _Channel0Tiling;
			float _Channel1;
			float3 _Channel1Tiling;
			float _Channel2;
			float3 _Channel2Tiling;
			float _DetailWeight;
			float3 _DetailTiling;

			//Debug
			int _Debug;

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

            v2f vert (appdata v)
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

			float4 raymarchSampleTex(float3 originPos, float3 viewDir, float distToBox, float distInsideBox)
			{
				viewDir = normalize(viewDir);
				float3 startPos = originPos + (viewDir * distToBox);
				float stepSize = 0.05f;
				int stepsTaken = 0;

				float4 result = 0;
				for (float i = 0; i < 10; i += stepSize)
				{
					stepsTaken++;
					float3 currentPos = startPos + (viewDir * i);

					//Time movement offset
					float3 offset = _MovementDirection * _Time.x * _MovementSpeed * 3;
					float3 detailOffset = _MovementDirection * _Time.x * _MovementSpeed * 3 * (_DetailMovementSpeed * 5);

					//Sample texture
					float channel0Sample = tex3D(_3DNoiseTex, currentPos * _Channel0Tiling + offset).r;
					float channel1Sample = tex3D(_3DNoiseTex, currentPos * _Channel1Tiling + offset).g;
					float channel2Sample = tex3D(_3DNoiseTex, currentPos * _Channel2Tiling + offset).b;
					float detailSample = tex3D(_3DNoiseTex, currentPos * _DetailTiling + detailOffset).a;

					//Combine samples
					float totalWeight = _Channel0 + _Channel1 + _Channel2;
					float weight = (channel0Sample * _Channel0 + channel1Sample * _Channel1 + channel2Sample * _Channel2) / totalWeight;
					float density = weight - (detailSample * _DetailWeight);

					//Check density
					if (density >= _CutOff)
					{
						float maxDiff = 1 - _CutOff;
						float ColorVal01 = (density - _CutOff) / maxDiff;
						float val = stepSize * _Density * ColorVal01;
						float height = (currentPos.y - _BoundsMin.y) / (_BoundsMax - _BoundsMin).y;

						if(height > 0.5)
							result += lerp(_Color, _LightColor0, height) * val;
						else
							result += lerp(_Color, _ShadowColor, ( 1- height)) * val;

						/*return result / val;*/
					}

					//unroll loop
					if (i >= distInsideBox)
						i = 10;
				}

				//result /= stepsTaken * (1 - _Density);
				return saturate(result);
			}

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

				//Sample depth
				float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				float linearDepth = Linear01Depth(nonLinearDepth) * length(i.viewDir);

				//Raymarch box
				float2 rayBoxInfo = rayBoxDist(_BoundsMin, _BoundsMax, _WorldSpaceCameraPos, normalize(i.viewDir));
				float distToBox = rayBoxInfo.x;
				float distInsideBox = rayBoxInfo.y;

				if (distInsideBox > 0 && distToBox < linearDepth)
				{
					//3D tex
					float4 sampleTexCol = raymarchSampleTex(_WorldSpaceCameraPos, i.viewDir, distToBox, distInsideBox);// averageColFromBox(_WorldSpaceCameraPos, i.viewDir, distToBox, distInsideBox, 1);
					col.rgb = lerp(col.rgb, sampleTexCol.rgb, sampleTexCol.a);


					///////////////////////
					// Show 3D Noise Tex //
					///////////////////////
					if (_Debug > 0.5)
					{
						float3 pos = _WorldSpaceCameraPos + (normalize(i.viewDir) * distToBox);
						float3 offset = _MovementDirection * _Time.x * _MovementSpeed * 3;
						float channel0Sample = tex3D(_3DNoiseTex, pos * _Channel0Tiling + offset).r;
						float channel1Sample = tex3D(_3DNoiseTex, pos * _Channel1Tiling + offset).g;
						float channel2Sample = tex3D(_3DNoiseTex, pos * _Channel2Tiling + offset).b;

						//Combine samples
						float totalWeight = _Channel0 + _Channel1 + _Channel2;
						float3 colSample = float3(channel0Sample * _Channel0, channel1Sample * _Channel1, channel2Sample * _Channel2);
						col = float4(colSample.rgb, 1);
					}
				}

                return col;
            }
            ENDCG
        }
    }
}
