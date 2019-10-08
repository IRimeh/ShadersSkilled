Shader "Unlit/ForcefieldShader"
{
    Properties
    {
		_Color ("Color", Color) = (1,1,1,1)

		_EdgeRadius("Edge Radius", Range(0, 1)) = 0.5
		_FillOpacity("Fill Opacity", Range(0, 0.5)) = 0.2

		[Header(Truchet Variables)]
		_LineColor("Line Color", Color) = (1,1,1,1)
		_GridSize("Grid Size", Range(1, 500)) = 50
		_LineSize("Line Size", Range(1, 100)) = 5

		[Header(Wave Variables)]
		[Toggle]
		_WaveBool("Enable Wave", float) = 0
		_WaveFrequency("Wave Frequency", Range(1, 10)) = 2
		_WaveSpeed("Wave Speed", Range(1, 100)) = 2
		_WaveSize("Wave Size", Range(0, 1)) = 0.5

		[Header(Impact Variables)]
		_ImpactWidth("Impact Width", float) = 3
		_ImpactFallOff("Impact Falloff Distance", float) = 5
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 3.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 viewDir : TEXCOORD1;
				float4 wpos : TEXCOORD2;
            };

			fixed4 _Color;

			sampler2D _CameraDepthTexture;
			float _EdgeRadius;
			float _FillOpacity;

			fixed4 _LineColor;
			float _GridSize;
			float _LineSize;

			float _WaveFrequency;
			float _WaveSpeed;
			float _WaveSize;
			float _WaveBool;

			float3 _ImpactPos;
			float4 _ImpactPositions[100];
			float _CurrentImpactCount;

			float _ImpactDist;
			float _ImpactWidth;
			float _ImpactFallOff;

			float rand(float2 co) {
				float val = sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453;
				return val - floor(val);
			}

            v2f vert (appdata v, out float4 vertex : SV_POSITION)
            {
                v2f o;
                vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
				o.wpos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i, UNITY_VPOS_TYPE vpos : VPOS) : SV_Target
            {
				//Intersection detection
				float2 screenuv = vpos.xy / _ScreenParams.xy;
				float screenDepth = Linear01Depth(tex2D(_CameraDepthTexture, screenuv));
				float diff = screenDepth - Linear01Depth(vpos.z);
				float intersect = 0;

				if (diff > 0)
					intersect = 1 - smoothstep(0, _ProjectionParams.w * _EdgeRadius, diff);

				//Rim effect
				float rim = 1 - abs(dot(i.normal, normalize(i.viewDir))) * (10 - (10 * _EdgeRadius));
				
				//Combined
				float glow = max(intersect, rim);

				fixed4 edgeCol = fixed4(lerp(_Color.rgb, fixed3(1, 1, 1), pow(glow, 2)), 1);
				fixed4 fillCol = fixed4(_Color.rgb, _FillOpacity);
				float4 col = (edgeCol * glow) + (fillCol * (1 - glow));


				//Truchet
				float2 defaultUv = i.uv;
				i.uv.xy += _Time.x;
				float2 eUv = i.uv * _GridSize;
				eUv = float2(eUv.x - floor(eUv.x), eUv.y - floor(eUv.y));
				
				float line1 = 0;
				float line2 = 0;
				float random = rand(float2(floor(i.uv.x * _GridSize), floor(i.uv.y * _GridSize)));

				if (random > 0.5) {
					line1 = smoothstep(0, 1, 1 - abs((eUv.x + eUv.y) - 0.5) * _LineSize);
					line2 = smoothstep(0, 1, 1 - abs((eUv.x + eUv.y) - 1.5) * _LineSize);
				}
				else {
					line1 = smoothstep(0, 1, 1 - abs((eUv.x - eUv.y) - 0.5) * _LineSize);
					line2 = smoothstep(0, 1, 1 - abs((eUv.x - eUv.y) + 0.5) * _LineSize);
				}


				//Impact
				float4 worldPos = i.wpos;
				float2 uvs = i.uv;
				for (float i = 0; i < _CurrentImpactCount; i++)
				{
					float dist = distance(worldPos, _ImpactPositions[i].xyz);
					float fallOff = 1;
					if (dist < _ImpactPositions[i].w && dist > _ImpactPositions[i].w - _ImpactWidth)
					{
						float fallOff = 1;
						if (dist > _ImpactFallOff)
							fallOff = 1 - saturate((dist - _ImpactFallOff) / 1);

						float percentageDist = 1 - (abs(((dist - (_ImpactPositions[i].w - _ImpactWidth)) / _ImpactWidth) - 0.5) * 2);

						float4 lines = (_LineColor * (line1 + line2)) * (1 - glow) * clamp(uvs.y, 0, 1);
						col = lerp(col, _LineColor, (lines * percentageDist * (1 - glow)) * fallOff);
					}
				}

				//Wave
				if (_WaveBool > 0)
				{
					float prefloor = uvs.y * _GridSize * _WaveSize + (_Time.x * _WaveSpeed);
					if (floor(prefloor) % _WaveFrequency == 0)
					{
						float gradient = prefloor - floor(prefloor);
						gradient = 1 - (abs(gradient - 0.5) * 2);
						gradient = pow(gradient, 1);

						float4 lines = (_LineColor * (line1 + line2)) * (1 - glow) * clamp(uvs.y, 0, 1);
						col = lerp(col, _LineColor, lines * gradient * (1 - glow));
					}
				}
				float4 lines = (_LineColor * (line1 + line2)) * (1 - glow) * clamp(uvs.y, 0, 1);
				col = lerp(col, lines, _FillOpacity * (1 - glow));

                return col;
            }
            ENDCG
        }
    }
}
