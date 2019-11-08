Shader "Unlit/GalaxyShader"
{
    Properties
    {
		_MainTex("MainTex", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_EdgeColor("Edge Color", Color) = (1,1,1,1)
		_NormalMap("Normal Map", 2D) = "bump" {}
		_EdgePower("Edge Power", Range(0, 3)) = 1

		[Header(Star Pass 1)]
		_StarQuantity("Star Quantity", Range(0, 1)) = 1
		_StarSize("Star Size", Range(0, 1)) = 0.5

		[Header(Star Pass 2)]
		_StarColor("Star Color", Color) = (1,1,1,1)
		_StarQuantity2("Star Quantity", Range(0, 1)) = 0.5
		_StarSize2("Star Size", Range(0, 1)) = 0.5
		_DistOut("Distance Out", Range(0, 2)) = 0.5
		_Reach("Reach", Range(0, 10)) = 5
		_AppearSpeed("Appear and disappear speed", Range(0, 10)) = 0.5
		_Seed("Random Seed", Range(0, 1)) = 0
		[Toggle]_ShowAllSpots("Show all spawn spots", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		ZWrite Off
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		//Depth pass
		Pass
		{
			Zwrite On
			ColorMask 0
		}


		//Body + Fresnel pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 nonClipVertex : TEXCOORD5;

				half3 tspace0 : TEXCOORD1; // tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD2; // tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD3; // tangent.z, bitangent.z, normal.z

				float3 viewDir : TEXCOORD4;
			};

			sampler2D _NormalMap;
			sampler2D _MainTex;
            float4 _NormalMap_ST;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed4 _EdgeColor;
			float _EdgePower;
			float _StarQuantity;
			float _StarSize;
			float _UseTexture;

			float random(float2 st) {
				float val = sin(dot(st.xy,
					float2(12.9898, 78.233))) *
					43758.5453123;
				return val - floor(val);
			}

            v2f vert (appdata v)
            {
                v2f o;
				o.nonClipVertex = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NormalMap);
				o.normal = UnityObjectToWorldNormal(v.normal);

				half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(o.normal, wTangent) * tangentSign;
				o.tspace0 = half3(wTangent.x, wBitangent.x, o.normal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, o.normal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, o.normal.z);

				o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				//Normal calculations
				float3 normal = UnpackNormal(tex2D(_NormalMap, i.uv));
				float3 worldNormal;
				worldNormal.x = dot(i.tspace0, normal);
				worldNormal.y = dot(i.tspace1, normal);
				worldNormal.z = dot(i.tspace2, normal);

				//Fresnel
				float fresnel = 1 - dot(worldNormal, normalize(i.viewDir));
				fresnel = pow(fresnel, _EdgePower);

				fixed4 startCol = tex2D(_MainTex, abs(float2(0, 1) - i.nonClipVertex.xy * 0.001 * _MainTex_ST.xy)) * _Color;
				//Return result
				fixed4 col = lerp(startCol, _EdgeColor, fresnel);

				return col;
            }
            ENDCG
        }

		//Stars on body pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

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
				float4 vertex : SV_POSITION;
				float3 wpos : TEXCOORD5;
			};

			sampler2D _NormalMap;
			float4 _NormalMap_ST;
			fixed4 _Color;
			fixed4 _EdgeColor;
			float _EdgePower;
			float _StarQuantity;
			float _StarSize;

			float random(float3 st) {
				float val = sin(dot(st.xyz,
					float3(12.9898, 78.233, 34.4932))) *
					43758.5453123;
				return val - floor(val);
			}

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex + v.normal * 0.01);
				o.uv = TRANSFORM_TEX(v.uv, _NormalMap);
				o.wpos = mul(unity_ObjectToWorld, v.vertex.xyz).xyz;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//Stars Pass 1
				float3 origCoords = i.wpos.xyz * (100 * (1 - _StarSize));
				origCoords += _Time.xxx * 10;
				float3 coords = floor(origCoords);
				float stars = random(coords);
				stars = step(_StarQuantity, stars);
				stars = saturate(stars * ((1 - max(length(origCoords.xy - (coords.xy + 0.5)), max(length(origCoords.yz - (coords.yz + 0.5)), length(origCoords.zx - (coords.zx + 0.5)))) * 2)));

				//Return result
				fixed4 col = fixed4(1,1,1,stars);

				return col;
			}
			ENDCG
		}
	
		//Big seperate star pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

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
				float3 wpos : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float3 normal : NORMAL;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 relativePos : TEXCOORD1;
			};

			sampler2D _NormalMap;
			float4 _NormalMap_ST;
			fixed4 _Color;
			fixed4 _EdgeColor;
			fixed4 _StarColor;
			float _EdgePower;
			float _StarQuantity2;
			float _StarSize2;
			float _Seed;
			float _DistOut;
			float _Reach;
			float _AppearSpeed;
			float _ShowAllSpots;

			float random(float3 st) {
				float val = sin(dot(st.xyz,
					float3(12.9898, 78.233, 34.4932))) *
					43758.5453123;
				return val - floor(val);
			}

			v2g vert(appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.uv = TRANSFORM_TEX(v.uv, _NormalMap);
				o.wpos = mul(unity_ObjectToWorld, v.vertex.xyz).xyz;
				o.viewDir = WorldSpaceViewDir(v.vertex);
				return o;
			}

			[maxvertexcount(18)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				float3 centerVertex = (IN[0].vertex.xyz + IN[1].vertex.xyz + IN[2].vertex.xyz) / 3;
				float3 center = (IN[0].wpos.xyz + IN[1].wpos.xyz + IN[2].wpos.xyz) / 3;
				float3 normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3;
				float maxDiff = max(length(IN[0].vertex.xyz - IN[1].vertex.xyz), max(length(IN[1].vertex.xyz - IN[2].vertex.xyz), length(IN[2].vertex.xyz - IN[0].vertex.xyz)));
				float rand = random(center + (_Seed * 1000));
				//Star size multiplier
				maxDiff *= _StarSize2 * 2;

				if (rand > 0.9 + (0.1 * (1 - _StarQuantity2)))
				{
					//Star time sin multiplier
					maxDiff *= max(max(sin((_Time.y * _AppearSpeed) * random(normal)) - 0.9, 0) * 10, _ShowAllSpots);

					g2f o;
					o.uv = IN[0].uv;
					float3 dir = normalize(IN[0].vertex.xyz - centerVertex);
					float3 right = mul(unity_WorldToObject, mul((float3x3)unity_CameraToWorld, float3(1, 0, 0)));
					float3 up = mul(unity_WorldToObject, mul((float3x3)unity_CameraToWorld, float3(0, 1, 0)));
					centerVertex += normal * _DistOut;

					//Square
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff) + (up * maxDiff));
					o.relativePos = float2(length(right), length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff) - (up * maxDiff));
					o.relativePos = float2(length(right), -length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff) - (up * maxDiff));
					o.relativePos = float2(-length(right), -length(up));
					triStream.Append(o);
					triStream.RestartStrip();
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff) + (up * maxDiff));
					o.relativePos = float2(-length(right), length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff) + (up * maxDiff));
					o.relativePos = float2(length(right), length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff) - (up * maxDiff));
					o.relativePos = float2(-length(right), -length(up));
					triStream.Append(o);
					triStream.RestartStrip();

					//Top
					o.vertex = UnityObjectToClipPos(centerVertex + (up * maxDiff * _Reach));
					o.relativePos = float2(0, length(up * _Reach));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff) + (up * maxDiff));
					o.relativePos = float2(length(right), length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff) + (up * maxDiff));
					o.relativePos = float2(-length(right), length(up));
					triStream.Append(o);
					triStream.RestartStrip();
					//Right
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff) + (up * maxDiff));
					o.relativePos = float2(length(right), length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff * _Reach));
					o.relativePos = float2(length(right * _Reach), 0);
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff) - (up * maxDiff));
					o.relativePos = float2(length(right), -length(up));
					triStream.Append(o);
					triStream.RestartStrip();
					//Down
					o.vertex = UnityObjectToClipPos(centerVertex - (up * maxDiff * _Reach));
					o.relativePos = float2(0, -length(up * _Reach));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex + (right * maxDiff) - (up * maxDiff));
					o.relativePos = float2(length(right), -length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff) - (up * maxDiff));
					o.relativePos = float2(-length(right), -length(up));
					triStream.Append(o);
					triStream.RestartStrip();
					//Left
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff * _Reach));
					o.relativePos = float2(-length(right * _Reach), 0);
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff) + (up * maxDiff));
					o.relativePos = float2(-length(right), length(up));
					triStream.Append(o);
					o.vertex = UnityObjectToClipPos(centerVertex - (right * maxDiff) - (up * maxDiff));
					o.relativePos = float2(-length(right), -length(up));
					triStream.Append(o);
					triStream.RestartStrip();
				}
			}

			fixed4 frag(g2f i) : SV_Target
			{
				//Return result
				fixed4 col = fixed4(0,0,0,1);
				
				float dist = length(i.relativePos) * (_Reach * min(abs(i.relativePos.x), abs(i.relativePos.y)));
				col = lerp(_StarColor, fixed4(_Color.rgb, 0), clamp(dist * 0.25, 0, 1));
				return col;
			}
			ENDCG
		}
    }
}
