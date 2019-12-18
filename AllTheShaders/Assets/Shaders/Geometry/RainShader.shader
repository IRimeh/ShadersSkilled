Shader "Unlit/RainShader"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" {}
		_DropletCount("Rain droplet count", Range(0, 34)) = 3
		_RainDropDistance("Rain drop distance", float) = 1
		_RainSpeed("Rain speed", Range(0, 1)) = 1

		_DepthTexture("Depth Texture", 2D) = "black" {}
		
		[Header(Rain droplets)]
		_DropMask("Rain drop mask", 2D) = "white" {}
		_DropWidth("Rain drop width", float) = 0.1
		_DropHeight("Rain drop height", float) = 0.3

		[Header(Lighting)]
		_HighlightDensity("Highlight density", Range(0, 1)) = 0.5
		_HighlightIntensity("Highlight intensity", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderType"="Transparent" }
        LOD 100
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geom

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _NoiseTex;
			sampler2D _DropMask;
			float4 _NoiseTex_ST;
			float _DropWidth;
			float _DropHeight;
			float _DropletCount;
			float _RainDropDistance;
			float _RainSpeed;

			float _HighlightDensity;
			float _HighlightIntensity;

			sampler2D _DepthTexture;
			float2 _UVscale;
			float2 _BottomRightCorner;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 wpos : TEXCOORD1;
            };

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 wpos : TEXCOORD1;
			};

			float rand(float2 n) 
			{
				float val = sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453;
				val -= floor(val);
				return val;
			}

            v2g vert (appdata v)
            {
                v2g o;
				o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
				o.wpos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

			[maxvertexcount(102)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				float4 center = float4(0, 0, 0, 0);
				float4 centerWpos = float4(0, 0, 0, 0);
				float2 uvs = float2(0, 0);

				for (int i = 0; i < 3; i++)
				{
					center += IN[i].vertex;
					centerWpos += IN[i].wpos;
					uvs += IN[i].uv;
				}
				center /= 3;
				centerWpos /= 3;
				uvs /= 3;


				for (int i = 0; i < _DropletCount; i++)
				{
					float4 pos = center;
					float4 offset = float4(0,0,0,0);
					float maxDist = max(distance(IN[0].wpos.xz, IN[1].wpos.xz), max(distance(IN[1].wpos.xz, IN[2].wpos.xz), distance(IN[2].wpos.xz, IN[0].wpos.xz)));
					offset.x = rand(IN[0].wpos.xz + float2(i * 0.005, i * 0.005)) - 0.5;
					offset.z = rand(IN[0].wpos.zx + float2(i * 0.005, i * 0.005)) - 0.5;

					float4 tempPos = pos + mul(unity_WorldToObject, offset * maxDist);
					float depthVal = 1 - tex2Dlod(_DepthTexture, float4(1 - uvs.xy,0,0)).r;
					float distanceVal = _RainDropDistance;// *depthVal;
					float noiseVal = tex2Dlod(_NoiseTex, float4(centerWpos.xz + offset.xz, 0, 0)) * 3;

					//Caluclate time
					float time = _Time.y * clamp(rand(offset.zx), 0.75, 1); //Time multiplied by random speed
					time *= ((_RainSpeed * 100) / distanceVal); //Time multiplied by _RainSpeed divided by distance so the speed is independant from distance
					time += noiseVal;

					//Final offset
					offset.y -= (time % 1) * distanceVal;
					offset.xz *= maxDist;

					//Add offset to position
					pos += mul(unity_WorldToObject, offset);

					if (-(depthVal * distanceVal) < offset.y)
					{
						o.uv = float2(0.5, 1);
						o.vertex = UnityObjectToClipPos(pos) + float4(0, -_DropHeight, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(0, -_DropHeight, 0, 0);
						triStream.Append(o);

						o.uv = float2(0, 0);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * -0.5, 0, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * -0.5, 0, 0, 0);
						triStream.Append(o);

						o.uv = float2(1, 0);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * 0.5, 0, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * 0.5, 0, 0, 0);
						triStream.Append(o);
						triStream.RestartStrip();
					}
				}
			}

            fixed4 frag (g2f i) : SV_Target
            {
				float texVal = tex2D(_DropMask, i.uv);

				/*float3 lightPos = _WorldSpaceLightPos0.xyz * ((1 - _HighlightDensity) * 10);
				float3 dir = lightPos - i.wpos.xyz;
				float alphaVal = clamp(dot(dir, -_WorldSpaceLightPos0.xyz), 1 - _HighlightIntensity, 1);*/

				fixed4 col = float4(1, 1, 1, texVal * 0.5);// float4(lerp(float3(1, 1, 1), _LightColor0, alphaVal), clamp(min(texVal, alphaVal), 0, 0.9));
                return col;
            }
            ENDCG
        }
    }
}
