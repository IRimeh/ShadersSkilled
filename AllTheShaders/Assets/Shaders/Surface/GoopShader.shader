Shader "Custom/GoopShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpTex("Height Map", 2D) = "black" {}
		_NormalTex("Normal Map", 2D) = "bump" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_Parallax("Parallax", Range(-1, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _BumpTex;
		sampler2D _NormalTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		float _Parallax;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_BumpTex;
			float2 uv_NormalTex;
			float3 viewDir;
        };

		void vert(inout appdata_full v, out Input IN) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, IN);
			IN.viewDir = normalize((_WorldSpaceCameraPos.xyz - v.vertex).xyz);
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {

			float2 offset = ParallaxOffset(tex2D(_BumpTex, IN.uv_BumpTex).r, -_Parallax, IN.viewDir);

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex + offset) * _Color;
			o.Albedo = c.rgb;
			o.Normal = UnpackNormal(tex2D(_NormalTex, IN.uv_NormalTex + offset));
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
