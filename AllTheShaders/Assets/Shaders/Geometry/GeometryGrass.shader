Shader "Unlit/GeometryGrass"
{
    Properties
    {
		_GroundColor("Ground Color", Color) = (1,1,1,1)
		_MaxGrassBlades("Maximum Grass Blades", Range(0, 5)) = 10
		_GrassOffsetDistance("Grass Offset Distance", float) = 0.5

		[Header(Individual Grass Blades)]
		_GrassBladesBaseColor("Grass Blades Base Color", Color) = (1,1,1,1)
		_GrassBladesTipColor("Grass Blades Tip Color", Color) = (1,1,1,1)
		_MaxGrassHeight("Max Grass Height", float) = 1
		_GrassWidth("Grass Width", float) = 0.1

		[Header(Wind Parameters)]
		_MinimumWind("Minimum Wind", Range(0, 0.9)) = 0.4
		_WindSpeed("Wind Speed", float) = 1
		_WindTexture("Wind Texture", 2D) = "white"
		//_WindNoiseTexture("Wind Noise Texture", 2D) = "white"
		_WindDirection("Wind Direction", Vector) = (1,0,0,0)

		[Header(Optimisation)]
		_RenderDistance("Render Distance", float) = 100
		_ShadowDistance("Shadow Distance", float) = 30
		[Toggle]_CastShadow("Cast Shadows", float) = 0
    }
    SubShader
    {
		Cull Off

        Pass
        {
			Tags{ "LightMode" = "ForwardBase" "RenderType" = "Opaque" "Queue" = "Opaque"}
			ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geom
			#pragma multi_compile_fwdbase

			#include "AutoLight.cginc"
            #include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _GroundColor;
			float _MaxGrassBlades;
			float _GrassOffsetDistance;

			fixed4 _GrassBladesBaseColor;
			fixed4 _GrassBladesTipColor;
			float _MaxGrassHeight;
			float _GrassWidth;

			float _MinimumWind;
			float _WindSpeed;
			sampler2D _WindTexture;
			float4 _WindTexture_ST;
			sampler2D _WindNoiseTexture;
			float4 _WindNoiseTexture_ST;
			float3 _WindDirection;

			float _RenderDistance;

            struct appdata
            {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 color : COLOR0;
            };

            struct v2g
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				float4 color : COLOR0;
				float3 normal : NORMAL;
				SHADOW_COORDS(1)
            };

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float4 color : COLOR0;
				SHADOW_COORDS(1)
			};

			v2g vert(appdata v)
			{
				v2g o;
				o.pos = v.pos;
				o.uv = v.uv;
				o.color = v.color;
				o.normal = v.normal;
				TRANSFER_SHADOW(o)
				return o;
			}

			float rand(float3 co)
			{
				float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
				return val - floor(val);
			}

			void CreateOriginalMesh(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				for (int i = 0; i < 3; i++)
				{
					o.uv = IN[i].uv;
					o.pos = UnityObjectToClipPos(IN[i].pos);
					o.normal = IN[i].normal;
					o.color = float4(IN[i].color.rgb, 0);
					TRANSFER_SHADOW(o)
						triStream.Append(o);
				}
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage1(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				float3 wpos;
				float3 windOffset1 = windOffset * 0.1 * grassHeight;

				//Normal calculation
				float3 pos1 = startPos - rotationDirection;
				float3 pos2 = startPos + rotationDirection;
				float3 pos3 = startPos + (worldNormal * grassHeight * 0.25) - (rotationDirection) + windOffset1;
				float3 norm = normalize(cross(pos2 - pos1, pos3 - pos1));
				o.normal = mul(unity_WorldToObject, float4(norm, 0.0));


				//1
				wpos = startPos;
				wpos -= rotationDirection;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = _GrassBladesBaseColor;
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.25;
				wpos -= rotationDirection * 0.75;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.25);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = _GrassBladesBaseColor;
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				//2
				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.25;
				wpos -= rotationDirection * 0.75;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.25);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += rotationDirection * 0.75;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.25);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = _GrassBladesBaseColor;
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage2(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				o.color = float4(((IN[0].color + IN[1].color + IN[2].color) / 3).rgb, 1);

				float3 wpos;
				float3 windOffset1 = windOffset * 0.1 * grassHeight;
				float3 windOffset2 = windOffset * 0.3 * grassHeight;

				//Normal calculation
				float3 pos1 = startPos - rotationDirection + windOffset1;
				float3 pos2 = startPos + rotationDirection + windOffset1;
				float3 pos3 = startPos + (worldNormal * grassHeight * 0.25) - (rotationDirection) + windOffset2;
				float3 norm = normalize(cross(pos2 - pos1, pos3 - pos1));
				o.normal = mul(unity_WorldToObject, float4(norm, 0.0));

				//1
				wpos = startPos;
				wpos -= rotationDirection * 0.75;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.25);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.5;
				wpos -= rotationDirection * 0.5;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.5);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.75;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.25);
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				//2
				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += rotationDirection * 0.5;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.5);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.5;
				wpos -= rotationDirection * 0.5;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.5);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.75;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.25);
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage3(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				o.color = float4(((IN[0].color + IN[1].color + IN[2].color) / 3).rgb, 1);

				float3 wpos;
				float3 windOffset1 = windOffset * 0.3 * grassHeight;
				float3 windOffset2 = windOffset * 0.65 * grassHeight;

				//Normal calculation
				float3 pos1 = startPos - rotationDirection + windOffset1;
				float3 pos2 = startPos + rotationDirection + windOffset1;
				float3 pos3 = startPos + (worldNormal * grassHeight * 0.25) - (rotationDirection) + windOffset2;
				float3 norm = normalize(cross(pos2 - pos1, pos3 - pos1));
				o.normal = mul(unity_WorldToObject, float4(norm, 0.0));

				//1
				wpos = startPos;
				wpos -= rotationDirection * 0.5;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.5);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.8;
				wpos -= rotationDirection * 0.25;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.75);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.5;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.5);
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				//2
				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.8;
				wpos += rotationDirection * 0.25;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.75);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.8;
				wpos -= rotationDirection * 0.25;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.75);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.5;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.5);
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage4(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				o.color = float4(((IN[0].color + IN[1].color + IN[2].color) / 3).rgb, 1);

				float3 wpos;
				float3 windOffset1 = windOffset * 0.65 * grassHeight;
				float3 windOffset2 = windOffset * grassHeight;

				//Normal calculation
				float3 pos1 = startPos - rotationDirection + windOffset1;
				float3 pos2 = startPos + rotationDirection + windOffset1;
				float3 pos3 = startPos + (worldNormal * grassHeight * 0.25) - (rotationDirection) + windOffset2;
				float3 norm = normalize(cross(pos2 - pos1, pos3 - pos1));
				o.normal = mul(unity_WorldToObject, float4(norm, 0.0));

				wpos = startPos;
				wpos -= rotationDirection * 0.25;
				wpos += worldNormal * grassHeight * 0.8;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.75);
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = _GrassBladesTipColor;
				TRANSFER_SHADOW(o)
					triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.25;
				wpos += worldNormal * grassHeight * 0.8;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = lerp(_GrassBladesBaseColor, _GrassBladesTipColor, 0.75);
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBlade(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight)
			{
				worldNormal = normalize(worldNormal);
				float3 normal = cross(worldNormal, rotationDirection);
				rotationDirection = (rotationDirection * _GrassWidth * 0.5);
				CreateGrassBladeStage1(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
				CreateGrassBladeStage2(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
				CreateGrassBladeStage3(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
				CreateGrassBladeStage4(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
			}

			[maxvertexcount(60)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				CreateOriginalMesh(IN, triStream);

				float3 wPos0 = mul(unity_ObjectToWorld, IN[0].pos);
				float3 wPos1 = mul(unity_ObjectToWorld, IN[1].pos);
				float3 wPos2 = mul(unity_ObjectToWorld, IN[2].pos);

				if(distance(wPos0, _WorldSpaceCameraPos) < _RenderDistance)
				{
					float3 middleWPos = (wPos0 + wPos1 + wPos2) / 3;
					float4 avgCol = (IN[0].color + IN[1].color + IN[2].color) / 3;
					float3 worldNormal = mul(unity_ObjectToWorld, float4(IN[0].normal.xyz, 0.0)).xyz;

					float3 dir1 = normalize(middleWPos - wPos0);
					float3 dir2 = cross(dir1, worldNormal);

					g2f o;
					float numGrassBlades = round(avgCol.r * _MaxGrassBlades);
					for (int i = 0; i < numGrassBlades; i++)
					{
						float3 startPos = middleWPos;

						startPos += dir1 * (rand(middleWPos * (i + 1)) - 0.5) * _GrassOffsetDistance;
						startPos += dir2 * (rand(middleWPos * 2.64 * (i + 1)) - 0.5) * _GrassOffsetDistance;
						float3 rotationDirection = normalize((dir1 * rand(middleWPos * (i + 1))) + (dir2 * rand(middleWPos * 8.83 * (i + 1))));

						float3 grassHeight = _MaxGrassHeight * (1 - avgCol.b);
						float windTextureSample = tex2Dlod(_WindTexture, float4((startPos.x + _Time.y * -_WindDirection.x * _WindSpeed) * _WindTexture_ST.x, (startPos.z + _Time.y * -_WindDirection.z * _WindSpeed) * _WindTexture_ST.y, 0, 0));
						float3 windOffset = _WindDirection * ((windTextureSample * (1 - _MinimumWind)) + _MinimumWind);

						CreateGrassBlade(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight);
					}
				}
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float3 worldNormal = mul(unity_ObjectToWorld, float4(i.normal, 0.0));

				//Initial color
				fixed4 col = float4(i.color.rgb, 1);
				if (i.color.a <= 0.1)
					col = float4(_GroundColor.rgb, 1);

				//Light calculation
				float light = max(abs(dot(_WorldSpaceLightPos0, worldNormal)), 0.3);
				float atten = LIGHT_ATTENUATION(i);

				col.rgb *= _LightColor0.rgb * (max(light * atten, 0.15) * 2);
				return col;
            }
            ENDCG
        }

		/////////////////
		// SHADOW PASS //
		/////////////////
		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
				"RenderType" = "Transparent"
				"Queue" = "AlphaTest"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma target 4.6
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _MaxGrassBlades;
			float _GrassOffsetDistance;

			float _MaxGrassHeight;
			float _GrassWidth;

			float _MinimumWind;
			float _WindSpeed;
			sampler2D _WindTexture;
			float4 _WindTexture_ST;
			sampler2D _WindNoiseTexture;
			float4 _WindNoiseTexture_ST;
			float3 _WindDirection;

			float _ShadowDistance;
			float _CastShadow;

			struct appdata
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR0;
				float3 normal : NORMAL;
			};

			struct v2g
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 color : COLOR0;
				float3 normal : NORMAL;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float4 color : COLOR0;
			};

			v2g vert(appdata v)
			{
				v2g o;
				o.pos = v.pos;
				o.uv = v.uv;
				o.color = v.color;
				o.normal = v.normal;
				return o;
			}

			float rand(float3 co)
			{
				float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
				return val - floor(val);
			}

			void CreateOriginalMesh(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				for (int i = 0; i < 3; i++)
				{
					o.uv = IN[i].uv;
					o.pos = UnityObjectToClipPos(IN[i].pos);
					o.normal = IN[i].normal;
					o.color = float4(IN[i].color.rgb, 0);
					triStream.Append(o);
				}
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage1(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				o.normal = mul(unity_WorldToObject, float4(normal, 0.0));
				float3 wpos;

				float3 windOffset1 = windOffset * 0.1 * grassHeight;

				//1
				wpos = startPos;
				wpos -= rotationDirection;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = float4(0, 0.7, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.25;
				wpos -= rotationDirection * 0.75;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0, 0.775, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = float4(0, 0.7, 0, 1);
				triStream.Append(o);
				triStream.RestartStrip();

				//2
				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.25;
				wpos -= rotationDirection * 0.75;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0, 0.775, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += rotationDirection * 0.75;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0, 0.775, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = float4(0, 0.7, 0, 1);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage2(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				o.color = float4(((IN[0].color + IN[1].color + IN[2].color) / 3).rgb, 1);
				o.normal = mul(unity_WorldToObject, float4(normal, 0.0));
				float3 wpos;

				float3 windOffset1 = windOffset * 0.1 * grassHeight;
				float3 windOffset2 = windOffset * 0.3 * grassHeight;

				//1
				wpos = startPos;
				wpos -= rotationDirection * 0.75;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = float4(0, 0.775, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.5;
				wpos -= rotationDirection * 0.5;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0, 0.85, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.75;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = float4(0, 0.775, 0, 1);
				triStream.Append(o);
				triStream.RestartStrip();

				//2
				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += rotationDirection * 0.5;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0, 0.85, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.5;
				wpos -= rotationDirection * 0.5;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0, 0.85, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.75;
				wpos += worldNormal * grassHeight * 0.25;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = float4(0, 0.775, 0, 1);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage3(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				o.color = float4(((IN[0].color + IN[1].color + IN[2].color) / 3).rgb, 1);
				o.normal = mul(unity_WorldToObject, float4(normal, 0.0));
				float3 wpos;

				float3 windOffset1 = windOffset * 0.3 * grassHeight;
				float3 windOffset2 = windOffset * 0.65 * grassHeight;

				//1
				wpos = startPos;
				wpos -= rotationDirection * 0.5;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = float4(0, 0.85, 0, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.8;
				wpos -= rotationDirection * 0.25;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0.15, 0.925, 0.15, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.5;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = float4(0, 0.85, 0, 1);
				triStream.Append(o);
				triStream.RestartStrip();

				//2
				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.8;
				wpos += rotationDirection * 0.25;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0.15, 0.925, 0.15, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight * 0.8;
				wpos -= rotationDirection * 0.25;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0.15, 0.925, 0.15, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.5;
				wpos += worldNormal * grassHeight * 0.5;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = float4(0, 0.85, 0, 1);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBladeStage4(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight, float3 normal)
			{
				g2f o;
				o.color = float4(((IN[0].color + IN[1].color + IN[2].color) / 3).rgb, 1);
				o.normal = mul(unity_WorldToObject, float4(normal, 0.0));
				float3 wpos;

				float3 windOffset1 = windOffset * 0.65 * grassHeight;
				float3 windOffset2 = windOffset * grassHeight;

				wpos = startPos;
				wpos -= rotationDirection * 0.25;
				wpos += worldNormal * grassHeight * 0.8;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0, 0);
				o.color = float4(0.15, 0.925, 0.15, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += worldNormal * grassHeight;
				wpos += windOffset2;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(0.5, 1);
				o.color = float4(0.3, 1, 0.3, 1);
				triStream.Append(o);

				wpos = startPos;
				wpos += rotationDirection * 0.25;
				wpos += worldNormal * grassHeight * 0.8;
				wpos += windOffset1;
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(wpos, 1.0)));
				o.uv = float2(1, 0);
				o.color = float4(0.15, 0.925, 0.15, 1);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void CreateGrassBlade(triangle v2g IN[3], inout TriangleStream<g2f> triStream, float3 startPos, float3 worldNormal, float3 rotationDirection, float3 windOffset, float grassHeight)
			{
				worldNormal = normalize(worldNormal);
				float3 normal = cross(worldNormal, rotationDirection);
				rotationDirection = (rotationDirection * _GrassWidth * 0.5);
				CreateGrassBladeStage1(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
				CreateGrassBladeStage2(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
				CreateGrassBladeStage3(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
				CreateGrassBladeStage4(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight, normal);
			}

			[maxvertexcount(60)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				CreateOriginalMesh(IN, triStream);

				if(_CastShadow)
				{
					float3 wPos0 = mul(unity_ObjectToWorld, IN[0].pos);
					float3 wPos1 = mul(unity_ObjectToWorld, IN[1].pos);
					float3 wPos2 = mul(unity_ObjectToWorld, IN[2].pos);

					if(distance(wPos0, _WorldSpaceCameraPos) < _ShadowDistance)
					{
						float3 middleWPos = (wPos0 + wPos1 + wPos2) / 3;
						float4 avgCol = (IN[0].color + IN[1].color + IN[2].color) / 3;
						float3 worldNormal = mul(unity_ObjectToWorld, float4(IN[0].normal.xyz, 0.0)).xyz;

						float3 dir1 = normalize(middleWPos - wPos0);
						float3 dir2 = cross(dir1, worldNormal);

						g2f o;
						float numGrassBlades = round(avgCol.r * _MaxGrassBlades);
						for (int i = 0; i < numGrassBlades; i++)
						{
							float3 startPos = middleWPos;
							startPos += dir1 * (rand(middleWPos * (i + 1)) - 0.5) * _GrassOffsetDistance;
							startPos += dir2 * (rand(middleWPos * 2.64 * (i + 1)) - 0.5) * _GrassOffsetDistance;
							float3 rotationDirection = normalize((dir1 * rand(middleWPos * (i + 1))) + (dir2 * rand(middleWPos * 8.83 * (i + 1))));

							float3 grassHeight = _MaxGrassHeight * (1 - avgCol.b);
							float windTextureSample = tex2Dlod(_WindTexture, float4((startPos.x + _Time.y * -_WindDirection.x * _WindSpeed) * _WindTexture_ST.x, (startPos.z + _Time.y * -_WindDirection.z * _WindSpeed) * _WindTexture_ST.y, 0, 0));
							float3 windOffset = _WindDirection * ((windTextureSample * (1 - _MinimumWind)) + _MinimumWind);

							CreateGrassBlade(IN, triStream, startPos, worldNormal, rotationDirection, windOffset, grassHeight);
						}
					}
				}
			}

			fixed4 frag(g2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
    }
}
