Shader "Unlit/DissolveFromPointShader"
{
    Properties
    {
		[Header(Maps)]
        _MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("NoiseTex", 2D) = "white" {}
		_yGradient("yGradient", 2D) = "white" {}

		[Header(Colors)]
		_Color("Color", Color) = (1,1,1,1)
		_LineColor("Line Color", Color) = (1,1,1,1)
		_FadeColor("Fade Color", Color) = (0,0,1,1)

		[Header(Parameters)]
		_TimeScale("Time", Range(0, 1.5)) = 1
		_Stretch("Stretch", Range(0.0, 100)) = 50
		_TriDistance("Tri Start Distance", float) = 1
		_NormalImpact("Normal Impact", Range(0, 10)) = 3
		_LineAlpha("Line Alpha", Range(0, 1)) = 1
    }
    SubShader
    {
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent"}
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

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
				fixed4 col : COLOR0;
				float3 normal : NORMAL;
				float3 lightDir : TEXCOORD1;
				float mixVal : TEXCOORD2;
			};

			sampler2D _MainTex;
			sampler2D _NoiseTex;
			sampler2D _yGradient;
			float4 _MainTex_ST;
			float4 _NoiseTex_ST;
			float4 _yGradient_ST;
			float3 _DissolvePoint;
			float _TimeScale;
			float _Stretch;
			float _TriDistance;
			float _NormalImpact;
			fixed4 _FadeColor;
			fixed4 _Color;

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

			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				o.lightDir = IN[0].lightDir;
				o.mixVal = 1;

				float3 normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3;
				float3 pos = (IN[0].vertex + IN[1].vertex + IN[2].vertex).xyz / 3;

				for (int i = 0; i < 3; i++)
				{
					o.normal = IN[i].normal;
					o.uv = IN[i].uv;
					int next = (i + 1) % 3;

					fixed4 texVal = tex2Dlod(_NoiseTex, float4(IN[i].vertex.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw, 0, 0));
					float yNoise = 1 - tex2Dlod(_yGradient, float4(0, mul(unity_ObjectToWorld, IN[i].vertex).y * _yGradient_ST.y, 0, 0));
					float time = clamp((_TimeScale * 2) - yNoise, 0, 1);
					float endTime = clamp(2 - clamp((_TimeScale * 2) - yNoise, 0, 2) * 2, 0, 1);

					float4 pointPos = mul(unity_WorldToObject, float4(_DissolvePoint, 1));
					float3 dir = normalize((pointPos.xyz - IN[i].vertex.xyz) + (normal * _NormalImpact));

					o.col.rgb = lerp(IN[i].col.rgb, _FadeColor.rgb, endTime);
					o.col.a = pow(1 - endTime, 0.1);
					o.mixVal = pow(1 - endTime, 10);

					o.vertex = UnityObjectToClipPos(IN[i].vertex + (dir * endTime * _TriDistance));
					triStream.Append(o);
				}
				triStream.RestartStrip();
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float3 shadowCol = float3(0, 0, 0);
				float lightVal = dot(i.lightDir, i.normal);

				// sample the texture
				fixed4 col = float4(lerp(lerp(tex2D(_MainTex, i.uv).rgb * _Color.rgb, i.col.rgb, 1 - i.mixVal), shadowCol, lightVal * i.mixVal), i.col.a);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}

		///////////////
		// LINE PASS //
		///////////////
        Pass
        {
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
            };

            struct v2g
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

			struct g2f
			{
				float uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float time : TEXCOORD1;
			};

            sampler2D _MainTex;
			sampler2D _NoiseTex;
			sampler2D _yGradient;
            float4 _MainTex_ST;
			float4 _NoiseTex_ST;
			float4 _yGradient_ST;
			float3 _DissolvePoint;
			float _TimeScale;
			float _Stretch;
			float _FadeTime;
			float _LineAlpha;
			fixed4 _LineColor;

            v2g vert (appdata v)
            {
                v2g o;
				o.vertex = v.vertex;// UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

			[maxvertexcount(6)]
			void geom(triangle v2g IN[3], inout LineStream<g2f> lineStream)
			{
				g2f o;
				o.uv = IN[0].uv;

				for (int i = 0; i < 3; i++)
				{
					int next = (i + 1) % 3;

					fixed4 texVal = tex2Dlod(_NoiseTex, float4(IN[i].vertex.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw, 0, 0));
					float yNoise = 1 - tex2Dlod(_yGradient, float4(0, mul(unity_ObjectToWorld, IN[i].vertex).y * _yGradient_ST.y, 0, 0));
					float time = clamp((_TimeScale * 2) - yNoise, 0, 1);
					o.time = 2 - clamp((_TimeScale * 2) - yNoise, 0, 2);

					//startPos
					float4 pointPos = mul(unity_WorldToObject, float4(_DissolvePoint, 1));

					float4 dir = normalize(IN[i].vertex - pointPos);
					float diff = length(pointPos - IN[i].vertex);
					float size = diff * texVal;

					float4 startPos = lerp(pointPos, IN[0].vertex, time);
					float4 endPos = lerp(pointPos, lerp(pointPos + (dir * size), IN[next].vertex, pow(time, _Stretch * texVal)), time);

					o.vertex = UnityObjectToClipPos(startPos);
					lineStream.Append(o);
					o.vertex = UnityObjectToClipPos(endPos);
					lineStream.Append(o);

					lineStream.RestartStrip();
				}
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float time = clamp(1 - abs((i.time * 2 - (_LineAlpha)) - 1), 0, 1);
				// sample the texture
				fixed4 col = fixed4(_LineColor.rgb, time);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
