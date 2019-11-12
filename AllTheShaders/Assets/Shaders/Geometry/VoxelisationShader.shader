// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/VoxelisationShader"
{
    Properties
    {
		[Header(Maps)]
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		
		_CubeColor("Cube Color", Color) = (1,1,1,1)
		[Toggle]_UseTextureColor("Use Texture Colors 4 Cubes", float) = 0

		[Header(Parameters)]
		_CubeSize("Cube Size", Range(0, 2)) = 1
		_DropHeight("Drop Height", Range(0, 3)) = 0.5
		_Stretch("Stretch", Range(0, 1)) = 1
		_HeightDiff("Height Difference", float) = 3
		_BottomYPos("Bottom y pos", float) = 0
		_RandomStrength("Random Strength", Range(0, 1)) = 0.5
		_CutOffHarshity("Cut-Off Harshity", Range(1, 10)) = 3
    }
    SubShader
    {
		LOD 100
		Cull Off


		////////////////
		// TRI STREAM //
		////////////////
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" "RenderType" = "Transparent" "Queue" = "AlphaTest"}
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#include "AutoLight.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2g
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float3 lightDir : TEXCOORD2;
				fixed4 col : COLOR;
				SHADOW_COORDS(1)

				half3 tspace0 : TEXCOORD3; // tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD4; // tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD5; // tangent.z, bitangent.z, normal.z
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float3 lightDir : TEXCOORD2;
				float alpha : TEXCOORD3;
				float textureFrag : TEXCOORD7;
				SHADOW_COORDS(1)

				half3 tspace0 : TEXCOORD4; // tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD5; // tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD6; // tangent.z, bitangent.z, normal.z
			};

			fixed4 _Color;
			fixed4 _CubeColor;
			sampler2D _MainTex;
			sampler2D _NormalMap;
			float4 _MainTex_ST;
			float _BottomYPos;
			float _Stretch;
			float _CubeSize;
			float _HeightDiff;
			float _DropHeight;
			float _RandomStrength;
			float _CutOffHarshity;
			float _UseTextureColor;

			v2g vert(appdata v)
			{
				v2g o;
				o.pos = v.pos;
				o.uv = v.uv;
				o.normal = v.normal;
				o.lightDir = -_WorldSpaceLightPos0;
				TRANSFER_SHADOW(o)


				half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(o.normal, wTangent) * tangentSign;
				o.tspace0 = half3(wTangent.x, wBitangent.x, o.normal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, o.normal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, o.normal.z);
				return o;
			}

			float rand(float3 co) 
			{
				float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
				return val - floor(val);
			}


			void FaceTop(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 1, 0);

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceBottom(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, -1, 0);

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceRight(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(1, 0, 0);

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceLeft(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(-1, 0, 0);

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceForward(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 0, 1);

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceBackward(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 0, -1);

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();

				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				TRANSFER_SHADOW(o)
					triStream.Append(o);
				triStream.RestartStrip();
			}

			void CalcCubeFacesOrigin(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				FaceTop(o, triStream, startPos, maxDiff, yStretch);
				FaceBottom(o, triStream, startPos, maxDiff, yStretch);
				FaceRight(o, triStream, startPos, maxDiff, yStretch);
				FaceLeft(o, triStream, startPos, maxDiff, yStretch);
				FaceForward(o, triStream, startPos, maxDiff, yStretch);
				FaceBackward(o, triStream, startPos, maxDiff, yStretch);
			}

			[maxvertexcount(37)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				o.lightDir = IN[0].lightDir;
				o.tspace0 = IN[0].tspace0;
				o.tspace1 = IN[0].tspace1;
				o.tspace2 = IN[0].tspace2;
				o.alpha = 1;

				float3 normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3;
				float3 pos = (IN[0].pos + IN[1].pos + IN[2].pos).xyz / 3;
				float3 wpos = mul(unity_ObjectToWorld, float4(pos, 1));
				float maxDiff = max(length(IN[0].pos.xyz - IN[1].pos.xyz), max(length(IN[1].pos.xyz - IN[2].pos.xyz), length(IN[2].pos.xyz - IN[0].pos.xyz)));
				float random = rand(float3(wpos.xz, 1));
				float random2 = rand(float3(wpos.zx, 0.1));

				//Calculate size of cubes
				float cubeSize = maxDiff * 0.5 * _CubeSize;

				//Calculate distance
				float yDiff = _BottomYPos - wpos.y;
				yDiff = clamp(yDiff, 0, 1);
				float yDiff2 = _BottomYPos - _HeightDiff - wpos.y;
				float yDiff2Step = step(1, yDiff2) * yDiff2;

				cubeSize *= yDiff * pow(((1 - (abs(clamp(yDiff, 0, 1) - 0.5) * 2)) + 1), 2);

				//Calculate stretch value
				float stretch = 1 - (abs(yDiff - 0.5) * 2);
				stretch *= random * _Stretch;

				//Calculate starting position
				float3 startingPosOffset = (float3(rand(wpos.xyz) - 0.5, rand(wpos.yzx) - 0.5, rand(wpos.zxy) - 0.5) * (1 - clamp(yDiff2, 0, 1)) * _RandomStrength);
				float3 startingPos = wpos + (startingPosOffset * sin(_Time.y * random));
				startingPos += float3((1 - yDiff) * (random - 0.5), (1 - yDiff) * 2 * ((random2 + 1) * _DropHeight), 0);


				//Create original mesh
				for (int i = 0; i < 3; i++)
				{
					o.tspace0 = IN[i].tspace0;
					o.tspace1 = IN[i].tspace1;
					o.tspace2 = IN[i].tspace2;
					o.uv = IN[i].uv;
					o.pos = UnityObjectToClipPos(IN[i].pos);
					o.normal = mul(unity_ObjectToWorld, IN[i].normal);
					o.alpha = 1 - pow(saturate(1 - yDiff2), _CutOffHarshity);
					o.textureFrag = 1;
					TRANSFER_SHADOW(o)
					triStream.Append(o);
				}
				triStream.RestartStrip();

				//Create cubes
				o.alpha = saturate(1 - yDiff2Step);
				o.textureFrag = 0;
				CalcCubeFacesOrigin(o, triStream, startingPos, cubeSize * pow(saturate(1 - yDiff2), _CutOffHarshity), stretch);
			}

			fixed4 frag(g2f i) : SV_Target
			{
				//Normal caluclation
				float3 normal = UnpackNormal(tex2D(_NormalMap, i.uv));
				float3 worldNormal;
				worldNormal.x = dot(i.tspace0, normal);
				worldNormal.y = dot(i.tspace1, normal);
				worldNormal.z = dot(i.tspace2, normal);
				worldNormal = mul(unity_ObjectToWorld, worldNormal);
				i.normal = lerp(i.normal, worldNormal, i.textureFrag);

				//Lighting
				float4 lightVal = _LightColor0 * dot(-i.lightDir, i.normal);
				fixed shadow = SHADOW_ATTENUATION(i);

				//Combining
				float3 col = lerp(_CubeColor, tex2D(_MainTex, i.uv).rgb * _Color.rgb, max(i.textureFrag, _UseTextureColor));

				//Return
				fixed4 returnVal = float4(col * lightVal * shadow, i.alpha);
				return returnVal;
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

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2g
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 lightDir : TEXCOORD1;
				fixed4 col : COLOR;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 lightDir : TEXCOORD1;
				float alpha : TEXCOORD2;
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _BottomYPos;
			float _Stretch;
			float _CubeSize;
			float _HeightDiff;
			float _DropHeight;
			float _RandomStrength;
			float _CutOffHarshity;

			v2g vert(appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = v.uv;
				o.normal = v.normal;
				o.lightDir = -_WorldSpaceLightPos0;
				return o;
			}

			float rand(float3 co)
			{
				float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
				return val - floor(val);
			}

			void FaceTop(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 1, 0);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceBottom(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, -1, 0);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceRight(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(1, 0, 0);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceLeft(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(-1, 0, 0);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceForward(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 0, 1);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceBackward(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 0, -1);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void CalcCubeFacesOrigin(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				FaceTop(o, triStream, startPos, maxDiff, yStretch);
				FaceBottom(o, triStream, startPos, maxDiff, yStretch);
				FaceRight(o, triStream, startPos, maxDiff, yStretch);
				FaceLeft(o, triStream, startPos, maxDiff, yStretch);
				FaceForward(o, triStream, startPos, maxDiff, yStretch);
				FaceBackward(o, triStream, startPos, maxDiff, yStretch);
			}

			[maxvertexcount(40)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				o.lightDir = IN[0].lightDir;
				o.alpha = 1;

				float3 normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3;
				float3 pos = (IN[0].vertex + IN[1].vertex + IN[2].vertex).xyz / 3;
				float3 wpos = mul(unity_ObjectToWorld, float4(pos, 1));
				float maxDiff = max(length(IN[0].vertex.xyz - IN[1].vertex.xyz), max(length(IN[1].vertex.xyz - IN[2].vertex.xyz), length(IN[2].vertex.xyz - IN[0].vertex.xyz)));
				float random = rand(float3(wpos.xz, 1));
				float random2 = rand(float3(wpos.zx, 0.1));

				//Calculate size of cubes
				float cubeSize = maxDiff * 0.5 * _CubeSize;

				//Calculate distance
				float yDiff = _BottomYPos - wpos.y;
				yDiff = clamp(yDiff, 0, 1);
				float yDiff2 = _BottomYPos - _HeightDiff - wpos.y;
				float yDiff2Step = step(1, yDiff2) * yDiff2;

				cubeSize *= yDiff * pow(((1 - (abs(clamp(yDiff, 0, 1) - 0.5) * 2)) + 1), 2);

				//Calculate stretch value
				float stretch = 1 - (abs(yDiff - 0.5) * 2);
				stretch *= random * _Stretch;

				//Calculate starting position
				float3 startingPosOffset = (float3(rand(wpos.xyz) - 0.5, rand(wpos.yzx) - 0.5, rand(wpos.zxy) - 0.5) * (1 - clamp(yDiff2, 0, 1)) * _RandomStrength);
				float3 startingPos = wpos + (startingPosOffset * sin(_Time.y * random));
				startingPos += float3((1 - yDiff) * (random - 0.5), (1 - yDiff) * 2 * ((random2 + 1) * _DropHeight), 0);


				//Create original mesh
				for (int i = 0; i < 3; i++)
				{
					o.uv = IN[i].uv;
					o.vertex = UnityObjectToClipPos(IN[i].vertex * step(1, yDiff));
					o.normal = mul(unity_ObjectToWorld, IN[i].normal);
					o.alpha = saturate(yDiff2);
					o.vertex = UnityApplyLinearShadowBias(o.vertex);
					triStream.Append(o);
				}
				triStream.RestartStrip();

				//Create cubes
				o.alpha = saturate(1 - yDiff2Step);
				CalcCubeFacesOrigin(o, triStream, startingPos, cubeSize * pow(saturate(1 - yDiff2), _CutOffHarshity), stretch);
			}

			float4 frag(g2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
    }
}
