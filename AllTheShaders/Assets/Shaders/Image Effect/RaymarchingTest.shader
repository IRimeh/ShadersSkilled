Shader "Hidden/RaymarchingTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_3DNoiseTex("3D Noise Texture", 3D) = "white" {}
		_NoiseTiling("Noise Tiling", Vector) = (1,1,1)
		_CutOff("Cut-Off Value", Range(0, 0.99)) = 0.5
		_Density("Density", Range(0, 1)) = 0.1
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
			float3 _BoundsMin;
			float3 _BoundsMax;
			float3 _NoiseTiling;
			float _CutOff;
			float _Density;

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

			float raymarchSampleTex(float3 originPos, float3 viewDir, float distToBox, float distInsideBox)
			{
				viewDir = normalize(viewDir);
				float3 startPos = originPos + (viewDir * distToBox);
				float stepSize = 0.1f;

				float result = 0;
				float cutOff = 0.5;

				for (float i = 0; i < 10; i += stepSize)
				{
					float3 currentPos = startPos + (viewDir * i);
					float4 texSample = tex3D(_3DNoiseTex, currentPos * _NoiseTiling);

					if (texSample.r >= _CutOff)
					{
						float maxDiff = 1 - _CutOff;
						float ColorVal01 = (texSample.r - _CutOff) / maxDiff;
						result += stepSize * _Density * ColorVal01;
					}

					//unroll loop
					if (i >= distInsideBox)
						i = 10;
				}

				return result;
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
					//float4 sampleTexCol = raymarchSampleTex(_WorldSpaceCameraPos, i.viewDir, distToBox, distInsideBox);// averageColFromBox(_WorldSpaceCameraPos, i.viewDir, distToBox, distInsideBox, 1);
					//col.rgb = lerp(col.rgb, _Color.rgb, sampleTexCol.a);


					///////////////////////
					// Show 3D Noise Tex //
					///////////////////////
					float3 pos = _WorldSpaceCameraPos + (normalize(i.viewDir) * distToBox);
					col = tex3D(_3DNoiseTex, pos * _NoiseTiling);
				}

                return col;
            }
            ENDCG
        }
    }
}
