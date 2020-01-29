Shader "Custom/ToonShader"
{
    Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_Glossiness("Smoothness", Range(0, 1)) = 0.5
		[HDR]_Emission("Emission", Color) = (0, 0, 0, 0)
		[Header(Light Variables)]
		_LightingSteps("Light Steps", Range(1, 8)) = 2
		_LightIntensity("Light Intensity", Range(0, 1)) = 0.5
		[Header(Shadow Variables)]
		_ShadowColor("Shadow Color", Color) = (0,0,0,0)
		_InitialShadowIntensity("Initial Shadow Intensity", Range(0, 1)) = 0.75
		_ShadowIntensity("Shadow Intensity", Range(0, 1)) = 0.5
		[Header(Outline Variables)]
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineSize("Outline Size", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Toon vertex:vert fullforwardshadows
        #pragma target 3.0
		#pragma lighting Toon
		#include "Lighting.cginc"
		#include "AutoLight.cginc"

        sampler2D _MainTex;
		sampler2D _BumpMap;
        half _Glossiness;
        half _Metallic;
		fixed4 _Emission;
        fixed4 _Color;
		fixed4 _OutlineColor;
		fixed4 _ShadowColor;
		float _LightingSteps;
		float _LightIntensity;
		float _ShadowSteps;
		float _ShadowIntensity;
		float _InitialShadowIntensity;
		float _OutlineSize;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 viewDir;
        };

		struct SurfaceOutputCustom 
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			half Specular;
			fixed Gloss;
			fixed Alpha;
			float3 viewDir;
			float rimDot;
			float3 halfVector;
			float NdotH;
		};

		half4 LightingToon(SurfaceOutputCustom s, half3 lightDir, half atten)
		{
			//Base color
			fixed4 c = lerp(_ShadowColor, float4(s.Albedo.rgb * _LightColor0.rgb, 1), 0);

			//Dot of the normal and light direction
			float dotVal = dot(lightDir, s.Normal);

			//Calculate intensity and comparing values
			float4 lightStep = _LightColor0.rgba * float4(s.Albedo, 1) * float4(_LightIntensity / _LightingSteps, _LightIntensity / _LightingSteps, _LightIntensity / _LightingSteps, 0);
			float lightCompareStep = 0.75 / _LightingSteps;

			//Lighting steps
			float currentCompareStep = 0;// lightCompareStep;
			float4 attenLightStep = atten > 0.1 ? lightStep : lightStep * 0.0f; //Significantly reduce the light step if in the shadow
			float4 light;
			for (int i = 0; i < _LightingSteps; i++)
			{
				if (dotVal > currentCompareStep)
				{
					light += attenLightStep * atten;
				}
				currentCompareStep += lightCompareStep;
			}
			c += light;

			//Specular highlight
			float NdotL = dot(_WorldSpaceLightPos0, s.Normal);
			float lightIntensity = smoothstep(0, 0.01, NdotL);
			float specularIntensity = pow(s.NdotH * (dotVal * lightIntensity), _Glossiness * _Glossiness * 100);
			float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
			float4 specular = specularIntensitySmooth * float4(1,1,1,1);
			c += specular * light;

			//Outline
			float OutlineIntensity = smoothstep((1 - _OutlineSize) - 0.01, (1 - _OutlineSize) + 0.01, s.rimDot);
			float4 Outline = OutlineIntensity * _OutlineColor;
			c = lerp(c, Outline, OutlineIntensity);
			return c;
		}

		void vert(inout appdata_full v, out Input IN) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, IN);
			IN.viewDir = normalize((_WorldSpaceCameraPos.xyz - v.vertex).xyz);
		}

        void surf (Input IN, inout SurfaceOutputCustom o)
        {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Gloss = _Glossiness;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			o.Emission = _Emission;
			o.Alpha = c.a;

			//Pass values to lighting calculations
			o.viewDir = normalize(IN.viewDir);
			o.rimDot = 1 - dot(IN.viewDir, o.Normal);
			o.halfVector = normalize(_WorldSpaceLightPos0 + o.viewDir);
			o.NdotH = dot(o.Normal, o.halfVector);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
