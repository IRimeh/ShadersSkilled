Shader "Hidden/KuwaharaShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Radius("Radius", Range(0, 10)) = 7
		_DepthMultiplier("DepthMultiplier", Range(0.001, 1)) = 0.01
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			float _Radius;
			float _DepthMultiplier;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = 0;
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				depth = min(Linear01Depth(depth), _DepthMultiplier) * (1.0 / _DepthMultiplier);
				int radius = round(_Radius);

				//Kuwahara
				float2 scrSize = (1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
				float2 uvs = i.uv;
				float n = float((radius + 1) * (radius + 1));
				float3 m0 = float3(0, 0, 0); float3 m1 = float3(0, 0, 0); float3 m2 = float3(0, 0, 0); float3 m3 = float3(0, 0, 0);
				float3 s0 = float3(0, 0, 0); float3 s1 = float3(0, 0, 0); float3 s2 = float3(0, 0, 0); float3 s3 = float3(0, 0, 0);
				float3 c;

				for (int j = -radius; j <= 0; j++)
				{
					for (int i = -radius; i <= 0; i++)
					{
						c = tex2D(_MainTex, uvs + float2(i, j) * scrSize * depth).rgb;
						m0 += c;
						s0 += c * c;
					}
				}

				for (int j = -radius; j <= 0; j++)
				{
					for (int i = 0; i <= radius; i++)
					{
						c = tex2D(_MainTex, uvs + float2(i, j) * scrSize * depth).rgb;
						m1 += c;
						s1 += c * c;
					}
				}

				for (int j = 0; j <= radius; j++)
				{
					for (int i = 0; i <= radius; i++)
					{
						c = tex2D(_MainTex, uvs + float2(i, j) * scrSize * depth).rgb;
						m2 += c;
						s2 += c * c;
					}
				}

				for (int j = 0; j <= radius; j++)
				{
					for (int i = -radius; i <= 0; i++)
					{
						c = tex2D(_MainTex, uvs + float2(i, j) * scrSize * depth).rgb;
						m3 += c;
						s3 += c * c;
					}
				}

				float min_sigma2 = 1e+2;
				float sigma2;
				
				m0 /= n;
				s0 = abs(s0 / n - m0 * m0);
				sigma2 = s0.r + s0.g + s0.b;
				if (sigma2 < min_sigma2)
				{
					min_sigma2 = sigma2;
					col = float4(m0, 1);
				}

				m1 /= n;
				s1 = abs(s1 / n - m1 * m1);
				sigma2 = s1.r + s1.g + s1.b;
				if (sigma2 < min_sigma2)
				{
					min_sigma2 = sigma2;
					col = float4(m1, 1);
				}

				m2 /= n;
				s2 = abs(s2 / n - m2 * m2);
				sigma2 = s2.r + s2.g + s2.b;
				if (sigma2 < min_sigma2)
				{
					min_sigma2 = sigma2;
					col = float4(m2, 1);
				}

				m3 /= n;
				s3 = abs(s3 / n - m3 * m3);
				sigma2 = s3.r + s3.g + s3.b;
				if (sigma2 < min_sigma2)
				{
					min_sigma2 = sigma2;
					col = float4(m3, 1);
				}



				//Normal texturing
                //col = tex2D(_MainTex, i.uv);
                col.rgb = col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
