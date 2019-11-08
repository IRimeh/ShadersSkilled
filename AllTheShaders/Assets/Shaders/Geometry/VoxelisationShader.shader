Shader "Unlit/VoxelisationShader"
{
    Properties
    {
		[Header(Maps)]
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("NoiseTex", 2D) = "white" {}

		[Header(Parameters)]
		_CubeSize("Cube Size", Range(0, 2)) = 1
		_Stretch("Stretch", Range(0, 1)) = 1
		_BottomYPos("Bottom y pos", float) = 0
		_BottomYPos2("Bottom y pos2", float) = 0
    }
    SubShader
    {
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent"}
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off

		////////////////
		// TRI STREAM //
		////////////////
		Pass
		{
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

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
			sampler2D _NoiseTex;
			float4 _MainTex_ST;
			float4 _NoiseTex_ST;
			float _BottomYPos;
			float _BottomYPos2;
			float _Stretch;
			float _CubeSize;

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
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceBottom(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, -1, 0);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceRight(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(1, 0, 0);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceLeft(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(-1, 0, 0);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceForward(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 0, 1);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, 1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, 1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				triStream.RestartStrip();
			}

			void FaceBackward(g2f o, inout TriangleStream<g2f> triStream, float3 startPos, float maxDiff, float yStretch)
			{
				o.normal = float3(0, 0, -1);

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				triStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, 1, -1) * maxDiff) + float3(0, yStretch, 0), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(1, -1, -1) * maxDiff), 1)));
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(mul(unity_WorldToObject, float4(startPos + (float3(-1, -1, -1) * maxDiff), 1)));
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
				float yDiff2 = _BottomYPos - 3 - wpos.y;
				float yDiff2Step = step(1, yDiff2) * yDiff2;

				cubeSize *= yDiff * pow(((1 - (abs(clamp(yDiff, 0, 1) - 0.5) * 2)) + 1), 2);

				//Calculate stretch value
				float stretch = 1 - (abs(yDiff - 0.5) * 2);
				stretch *= random * _Stretch;

				//Calculate starting position
				float3 startingPos = wpos;
				startingPos += float3((1 - yDiff) * (random - 0.5), (1 - yDiff) * 2 * ((random2 + 1) * 0.5), 0);


				//Create original mesh
				for (int i = 0; i < 3; i++)
				{
					o.uv = IN[i].uv;
					o.vertex = UnityObjectToClipPos(IN[i].vertex);
					o.normal = mul(unity_ObjectToWorld, IN[i].normal);
					o.alpha = saturate(yDiff2);
					triStream.Append(o);
				}
				triStream.RestartStrip();

				//Create cubes
				o.alpha = saturate(1 - yDiff2Step);
				CalcCubeFacesOrigin(o, triStream, startingPos, cubeSize * saturate(1 - yDiff2), stretch);
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float3 shadowCol = float3(0, 0, 0);
				float lightVal = dot(-i.lightDir, i.normal);

				float3 col = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

				// sample the texture
				fixed4 returnVal = float4(col * lightVal, i.alpha);
				return returnVal;
			}
			ENDCG
		}
    }
}
