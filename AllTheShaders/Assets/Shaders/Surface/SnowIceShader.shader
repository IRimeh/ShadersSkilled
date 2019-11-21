Shader "Custom/SnowIceShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_Tess("Increased Tessellation", Range(1,64)) = 32

		[Header(Snow Parameters)]
		_SnowNoise("Snow Noise Texture", 2D) = "white" {}
		_SnowThickness("Snow Thickness", Range(0, 0.25)) = 0.1
		_SnowCutOff("Snow Cut-Off", Range(-0.5, 1)) = 0.5
		_SnowSmoothing("Snow Smoothing", Range(0, 1)) = 0.25

		[Header(Ice Parameters)]
		_IcicleNoise("Icicle Noise Texture", 2D) = "white" {}
		_MaxIceLength("Maximum Icicle Length", float) = 1
		_HighlightCutOff("Highlight Cut-Off", Range(0, 1)) = 0.5
		_HighlightSmoothing("Highlight Smoothing", Range(0, 1)) = 0.25
		_IcicleNormalBlending("Icicle Normal Blending", Range(0, 1)) = 0.05
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard tessellate:tessFixed vertex:vert fullforwardshadows addshadow
		#pragma target 5.0
		#include "Tessellation.cginc"

        sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _SnowNoise;
		sampler2D _IcicleNoise;
		float4 _SnowNoise_ST;
		float4 _IcicleNoise_ST;
        half _Glossiness;
        half _Metallic;
		float _Tess;
        fixed4 _Color;

		//snow
		float _SnowThickness;
		float _SnowCutOff;
		float _SnowSmoothing;
		//ice
		float _MaxIceLength;
		float _HighlightCutOff;
		float _HighlightSmoothing;
		float _IcicleNormalBlending;

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
			float4 color : COLOR;
			float4 tangent : TANGENT;
		};

        struct Input
        {
            float2 uv_MainTex;
			float4 color : COLOR;
			float3 normal : NORMAL;
        };

		float4 tessFixed()
		{
			return _Tess;
		}

		void vert(inout appdata v)
		{
			float snow01 = v.color.r;

			float4 wpos = mul(unity_ObjectToWorld, v.vertex);
			float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			float dotVal = dot(worldNormal, float3(0, -1, 0));
			float snowNoiseVal = 1 - tex2Dlod(_SnowNoise, float4(wpos.xz * _SnowNoise_ST.xy, 0, 0)) * 0.2;
			float icicleNoiseVal = 1 - tex2Dlod(_IcicleNoise, float4(wpos.xz * _IcicleNoise_ST.xy, 0, 0)) * 0.5;

			//Vertex displacement
			wpos.xyz += worldNormal.xyz * snow01 * _SnowThickness * snowNoiseVal;
			wpos.y -= snow01 * step(0.25, dotVal) * _MaxIceLength * icicleNoiseVal;
			v.vertex = mul(unity_WorldToObject, wpos);

			v.color = float4(worldNormal, v.color.r);
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			//Snow
			float3 worldNormal = IN.color.xyz;
			float dotVal = dot(worldNormal, float3(0, 1, 0));
			float snow = dotVal;
			float highlight = dot(worldNormal, float3(0, -1, 0));

            // Albedo comes from a texture tinted by color
			float4 defaultCol = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			float4 correctedCol = defaultCol;
			correctedCol = lerp(correctedCol, float4(0.5, 0.5, 1, 1), step(0.001, IN.color.a));
			correctedCol = lerp(correctedCol, float4(1.0, 1.0, 1, 1), smoothstep(_SnowCutOff, _SnowCutOff + _SnowSmoothing, snow) * step(0.001, IN.color.a));
			correctedCol = lerp(correctedCol, float4(1.5, 1.5, 3, 1), smoothstep(_HighlightCutOff, _HighlightCutOff + _HighlightSmoothing, highlight) * step(0.001, IN.color.a));

			fixed4 c = correctedCol;
			o.Normal = lerp(o.Normal, UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex)), smoothstep(1 - _IcicleNormalBlending, 1, 1 - IN.color.a));
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = lerp(_Glossiness, 0, smoothstep(_SnowCutOff, _SnowCutOff + _SnowSmoothing, snow));
        }
        ENDCG
    }
    FallBack "Diffuse"
}
