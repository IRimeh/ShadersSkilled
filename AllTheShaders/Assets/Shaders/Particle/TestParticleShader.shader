Shader "Unlit/TestParticleShader"
{
    Properties
    {
		[HDR]
		_Color("Color", Color) = (1,1,1,1)
        _MainNoiseTex ("Main Noise Tex", 2D) = "white" {}
		_SecondNoiseTex("Second Noise Tex", 2D) = "white" {}
		_MaskTex("Mask Tex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

			fixed4 _Color;
            sampler2D _MainNoiseTex;
			sampler2D _SecondNoiseTex;
			sampler2D _MaskTex;
            float4 _MainNoiseTex_ST;
			float4 _SecondNoiseTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				float4 tex1Col = tex2D(_MainNoiseTex, i.uv * _MainNoiseTex_ST.xy + _MainNoiseTex_ST.zw);
				float4 tex2Col = tex2D(_SecondNoiseTex, i.uv * _SecondNoiseTex_ST.xy + _SecondNoiseTex_ST.zw);
				float4 combined = tex1Col + tex2Col - i.uv.z;

				float mask = tex2D(_MaskTex, i.uv).r;

				combined = smoothstep(i.uv.z, i.uv.z + 1, combined);

				// sample the texture
				fixed4 col = _Color * clamp(((combined - 0.5) * 2), 0, 1);
				col.a = combined.r * mask;
                return col;
            }
            ENDCG
        }
    }
}
