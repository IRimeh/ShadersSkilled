Shader "Custom/EasySnowShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_SnowColor("Snow Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _NormalMap;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		fixed4 _SnowColor;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float4 normal = tex2D(_NormalMap, IN.uv_MainTex);
			o.Normal = UnpackNormal(normal);

			float snowVal = clamp(dot(o.Normal, float4(0, -1, 0, 0)), 0, 1);

			float4 col = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			fixed4 c = col;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
			o.Emission = snowVal;
		}
        ENDCG
    }
    FallBack "Diffuse"
}
