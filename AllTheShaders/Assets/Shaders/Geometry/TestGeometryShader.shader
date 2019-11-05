Shader "Unlit/TestGeometryShader"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_NoiseTexScrollSpeed("Noise Texture Scroll Speed", float) = 1
		_ExtrusionFactor("Extrusion factor", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
		Cull Off
        LOD 100

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
				float3 normal : NORMAL;
            };

            struct v2g
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 lightDir : TEXCOORD1;
            };

			struct g2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 lightDir : TEXCOORD1;
			};

            sampler2D _MainTex;
			sampler2D _NoiseTex;
            float4 _MainTex_ST;
			float4 _NoiseTex_ST;
			float _ExtrusionFactor;
			float _NoiseTexScrollSpeed;
			fixed4 _Color;

            v2g vert (appdata v)
            {
                v2g o;
				o.vertex = v.vertex;
				o.uv = v.uv;
				o.normal = v.normal;
				o.lightDir = normalize(_WorldSpaceLightPos0);
                return o;
            }

			float rand(float2 co) {
				float val = sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453;
				return val - floor(val);
			}

			[maxvertexcount(24)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				o.lightDir = IN[0].lightDir;

				float4 center = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;
				float3 normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3;

				float2 uvX = center.zy * _NoiseTex_ST.xy; // x plane
				float2 uvY = center.xz * _NoiseTex_ST.xy; // y plane
				float2 uvZ = center.xy * _NoiseTex_ST.xy; // z plane
				float2 uvOffset = float2(_Time.x * _NoiseTexScrollSpeed, _Time.x * _NoiseTexScrollSpeed);

				//Texturing
				float3 x = tex2Dlod(_NoiseTex, float4(uvX + uvOffset, 0, 0));
				float3 y = tex2Dlod(_NoiseTex, float4(uvY + uvOffset, 0, 0));
				float3 z = tex2Dlod(_NoiseTex, float4(uvZ + uvOffset, 0, 0));

				//Calculate weight of the axi (axi? axises? axees??? idk)
				float3 weight = pow(abs(normal), 128);
				weight /= dot(weight, float3(1, 1, 1));
				float4 c = float4((x * weight.x + y * weight.y + z * weight.z), 1);

				float extrusion = _ExtrusionFactor * c.r;// *abs(sin(_Time.y + center.x));

				for (int i = 0; i < 3; i++)
				{
					int nextIndex = (i + 1) % 3;
					
					float3 sideNormal = cross(normal, normalize(IN[i].vertex - IN[nextIndex].vertex));
					float sideLightVal = dot(IN[0].lightDir, sideNormal);
					o.normal = sideNormal;
					
					o.vertex = UnityObjectToClipPos(IN[i].vertex);
					UNITY_TRANSFER_FOG(o,o.vertex);
					o.uv = TRANSFORM_TEX(IN[i].uv, _MainTex);
					triStream.Append(o);

					o.vertex = UnityObjectToClipPos(IN[i].vertex + float4(normal, 0.0) * extrusion);
					UNITY_TRANSFER_FOG(o, o.vertex);
					o.uv = TRANSFORM_TEX(IN[i].uv, _MainTex);
					triStream.Append(o);

					o.vertex = UnityObjectToClipPos(IN[nextIndex].vertex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					o.uv = TRANSFORM_TEX(IN[nextIndex].uv, _MainTex);
					triStream.Append(o);
					
					triStream.RestartStrip();

					o.vertex = UnityObjectToClipPos(IN[i].vertex + float4(normal, 0.0) * extrusion);
					UNITY_TRANSFER_FOG(o, o.vertex);
					o.uv = TRANSFORM_TEX(IN[i].uv, _MainTex);
					triStream.Append(o);

					o.vertex = UnityObjectToClipPos(IN[nextIndex].vertex + float4(normal, 0.0) * extrusion);
					UNITY_TRANSFER_FOG(o, o.vertex);
					o.uv = TRANSFORM_TEX(IN[i].uv, _MainTex);
					triStream.Append(o);

					o.vertex = UnityObjectToClipPos(IN[nextIndex].vertex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					o.uv = TRANSFORM_TEX(IN[nextIndex].uv, _MainTex);
					triStream.Append(o);

					triStream.RestartStrip();
				}


				for (int i = 0; i < 3; i++)
				{
					o.vertex = UnityObjectToClipPos(IN[i].vertex + float4(normal, 0.0) * extrusion);
					UNITY_TRANSFER_FOG(o, o.vertex);
					o.uv = TRANSFORM_TEX(IN[i].uv, _MainTex);
					o.normal =  IN[i].normal;
					triStream.Append(o);
				}

				triStream.RestartStrip();
			}

            fixed4 frag (g2f i) : SV_Target
            {
				float3 shadowCol = lerp(_Color.rgb, float3(0,0,0), 0.5);
				float3 lightCol = _Color.rgb;
				float lightVal = dot(i.lightDir, i.normal);

                // sample the texture
				fixed4 col = fixed4(lerp(shadowCol, lightCol, lightVal), 1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
