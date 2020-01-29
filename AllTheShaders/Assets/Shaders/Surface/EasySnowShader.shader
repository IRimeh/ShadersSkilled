// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/EasySnowShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		//_SnowColor("Snow Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		//_NormalMap("Normal Map", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Bump("Bump", 2D) = "bump" {}
        _Snow("Snow Level", Range(0,1)) = 0
        _SnowColor("Snow Color", Color) = (1.0,1.0,1.0,1.0)
        _SnowDirection("Snow Direction", Vector) = (0,1,0)
        _SnowDepth("Snow Depth", Range(-1,1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _Bump;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _Snow;
        float4 _SnowColor;
        float4 _SnowDirection;
        float _SnowDepth;

        struct Input {
            float2 uv_MainTex;
            float2 uv_Bump;
            float3 worldNormal;
            INTERNAL_DATA
        };

        void vert(inout appdata_full v) {
            //Convert the normal to world coortinates
            float3 snormal = normalize(_SnowDirection.xyz);
            float3 sn = mul((float3x3)unity_WorldToObject, snormal).xyz;

            if (dot(v.normal, sn) >= lerp(1, -1, (_Snow * 2) / 3))
            {
                v.vertex.xyz += normalize(sn + v.normal) * _SnowDepth * _Snow;
            }
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float4 col = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            fixed4 c = col;

            o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));
            if (dot(WorldNormalVector(IN, o.Normal), _SnowDirection.xyz) >= lerp(1, -1, _Snow))
            {
                o.Albedo = _SnowColor.rgb;
            }
            else {
                o.Albedo = c.rgb;
            }

           // o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
			//o.Emission = snowVal;
		}
        ENDCG
    }
    FallBack "Diffuse"
}
