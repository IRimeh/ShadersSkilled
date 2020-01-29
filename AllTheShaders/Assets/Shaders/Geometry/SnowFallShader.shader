Shader "Unlit/SnowFallShader"
{
    Properties
    {
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_DepthTexture("Depth Texture", 2D) = "black" {}
		_DropletCount("Droplet count", Range(0, 34)) = 3
		_RainDropDistance("Drop distance", float) = 1
		_RainSpeed("Speed", Range(0, 1)) = 1

		[Header(Movement)]
		_MovementNoiseTex("Movement Noise Texture", 2D) = "white" {}
		_NoiseSpeed("Noise Speed", Range(0, 1)) = 0.25
		_NoiseStrength("Noise Strength", Range(0, 5)) = 1
		
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
			Tags { "RenderType" = "Transparent" "RenderType" = "Transparent" }
			LOD 100
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma geometry geom

				#include "UnityCG.cginc"
				#include "Lighting.cginc"

			sampler2D _CameraDepthTexture;
			sampler2D _NoiseTex;
			sampler2D _DropMask;
			float4 _NoiseTex_ST;
			float _DropWidth;
			float _DropHeight;
			float _DropletCount;
			float _RainDropDistance;
			float _RainSpeed;

			sampler2D _MovementNoiseTex;
			float4 _MovementNoiseTex_ST;
			float _NoiseSpeed;
			float _NoiseStrength;

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
				//float4 screenPos : TEXCOORD2;
            };

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 wpos : TEXCOORD1;
				//float4 screenPos : TEXCOORD2;
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
				//o.screenPos = ComputeScreenPos(v.vertex);
                return o;
            }

			[maxvertexcount(64)]
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
					float distanceVal = _RainDropDistance;
					float noiseVal = tex2Dlod(_NoiseTex, float4(centerWpos.xz + offset.xz, 0, 0)) * 3;

					//Caluclate time
					float time = _Time.y * clamp(rand(offset.zx), 0.75, 1); //Time multiplied by random speed
					time *= ((_RainSpeed * 100) / distanceVal); //Time multiplied by _RainSpeed divided by distance so the speed is independant from distance
					time += noiseVal;

					//Final offset
					offset.y -= (time % 1) * distanceVal;
					offset.xz *= maxDist;
					offset.xz += (tex2Dlod(_MovementNoiseTex, float4((float2(_Time.x * _NoiseSpeed, _Time.x * _NoiseSpeed) + (centerWpos.xz + offset.xz)) * _MovementNoiseTex_ST, 0, 0)).r - 0.5) * _NoiseStrength;

					//Add offset to position
					pos += mul(unity_WorldToObject, offset);

					//Check if droplet should be spawned
					if (-(depthVal * distanceVal) < offset.y)
					{
						//Tri 1
						o.uv = float2(0, 0);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * -0.5, _DropHeight, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * -0.5, _DropHeight, 0, 0);
						triStream.Append(o);

						o.uv = float2(0, 1);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * -0.5, -_DropHeight, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * -0.5, -_DropHeight, 0, 0);
						triStream.Append(o);

						o.uv = float2(1, 0);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * 0.5, _DropHeight, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * 0.5, _DropHeight, 0, 0);
						triStream.Append(o);
						triStream.RestartStrip();


						//Tri 2
						o.uv = float2(0, 1);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * -0.5, -_DropHeight, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * -0.5, -_DropHeight, 0, 0);
						triStream.Append(o);

						o.uv = float2(1, 1);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * 0.5, -_DropHeight, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * 0.5, -_DropHeight, 0, 0);
						triStream.Append(o);

						o.uv = float2(1, 0);
						o.vertex = UnityObjectToClipPos(pos) + float4(_DropWidth * 0.5, _DropHeight, 0, 0);
						o.wpos = mul(unity_ObjectToWorld, pos) + float4(_DropWidth * 0.5, _DropHeight, 0, 0);
						triStream.Append(o);
						triStream.RestartStrip();
					}
				}
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float texVal = tex2D(_DropMask, i.uv);
				//float dist = distance(i.wpos.xyz, _WorldSpaceCameraPos.xyz);
				//float2 uvs = i.screenPos.xy;

				//float4 scrPos = ComputeScreenPos(i.vertex);
				//float4 dist2 = tex2D(_CameraDepthTexture, uvs).r;

				//float occlusion = step(dist2, dist);


			fixed4 col = /*float4(uvs.x, 0, 0, 1);*/ float4(1, 1, 1, 0.8) * texVal;// *occlusion;
				return col;
            }
            ENDCG
        }
    }
}
