Shader "Custom/IceShader"
{
    Properties
    {
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

		_Parallax("Parallax Offset", float) = 0
		_ParallaxStrength("Parallax Strength", Range(0, 10)) = 2
		_Iterations("Iterations", float) = 5
		_ParallaxMap("Parallax Map", 2D) = "white" {}

		_SnowTex("Snow Texture", 2D) = "white" {}
		_SnowNormal("Snow Normal Map", 2D) = "white" {}

		_RoughnessMap("Roughness Map", 2D) = "white" {}
		_RoughnessStrength("Roughness Strength", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows
		#pragma target 3.0

		samplerCUBE _Cube;

		sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _ParallaxMap;
		sampler2D _RoughnessMap;

		sampler2D _SnowTex;
		sampler2D _SnowNormal;

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		float _Parallax;
		float _ParallaxStrength;
		float _Iterations;
		float _RoughnessStrength;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_RoughnessMap;
			float2 uv_Normal;
			float2 uv_ParallaxMap;
			float2 uv_SnowTex;
			float2 uv_SnowNormal;
			float3 viewDir;
        };

		void vert(inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			//Calculate the view direction
			float4 cameraObj = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.)); //Camera position in object space
			float3 viewDirection = v.vertex.xyz - cameraObj.xyz;

			o.viewDir = normalize(viewDirection);
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			//Parallaxing
			float parallax = 0;
			for (float i = 0; i < _Iterations; i++)
			{
				float ratio = i / _Iterations;
				float offset = lerp(0, _Parallax, ratio);

				float parallaxVal = tex2D(_ParallaxMap, IN.uv_ParallaxMap + offset * IN.viewDir);
				parallaxVal *= (1 - ratio);

				parallax += parallaxVal * _ParallaxStrength;
			}
			parallax /= _Iterations;

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			fixed4 snow = tex2D(_SnowTex, IN.uv_SnowTex);
			fixed4 roughness = tex2D(_RoughnessMap, IN.uv_RoughnessMap) * _RoughnessStrength;

			o.Albedo = c.rgb + snow + roughness;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness * (1 - snow) * (1 - roughness);
            o.Alpha = c.a;

			//Add parallax to the albedo
			o.Albedo += parallax;
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_ParallaxMap + parallax));
		}
        ENDCG
    }
    FallBack "Diffuse"
}
