Shader "Unlit/WaterShaderV2.0"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

		GrabPass
		{
			"_GrabTexture"
		}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _GrabTexture;
			sampler2D _CameraDepthTexture;
			float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
            };

			float UnderWaterDepth(float4 scrPos)
			{
				float2 uvs = scrPos.xy / scrPos.w;
				float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uvs));
				float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(scrPos.z);

				return (backgroundDepth - surfaceDepth) * 0.25;
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				float3 diffVec = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, i.vertex).xyz;
				float dist = length(diffVec);

				float depth = UnderWaterDepth(i.screenPos);

				fixed4 col = lerp(tex2Dproj(_GrabTexture, i.screenPos), float4(1, 1, 1, 1), depth);// *((1 - depth)* float4(1, 1, 1, 1));
                return col;
            }
            ENDCG
        }
    }
}
