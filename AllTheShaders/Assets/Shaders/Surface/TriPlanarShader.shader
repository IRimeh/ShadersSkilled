Shader "Custom/TriPlanarShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Top Texture", 2D) = "white" {}
		_TopNormal("Top Normal Map", 2D) = "bump" {}
		_SideTex("Side Texture", 2D) = "white" {}
		_SideNormal("Side Normal Map", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_BlendPower("Blend Power", float) = 8
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _TopNormal;
		sampler2D _SideTex;
		sampler2D _SideNormal;
		float4 _MainTex_ST;
		float4 _SideTex_ST;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		float _BlendPower;

        struct Input
        {
            float2 uv_MainTex;
			float3 wpos : POSITION;
			float3 worldNormal : NORMAL; INTERNAL_DATA
        };

		void vert(inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			fixed4 c = _Color;

			//Triplanar uvs
			float2 uvX = IN.wpos.zy * _SideTex_ST.xy; // x plane
			float2 uvY = IN.wpos.xz * _MainTex_ST.xy; // y plane
			float2 uvZ = IN.wpos.xy * _SideTex_ST.xy; // z plane

			//Tangent space normal maps
			half3 tnormalX = UnpackNormal(tex2D(_SideNormal, uvX));
			half3 tnormalY = UnpackNormal(tex2D(_TopNormal, uvY));
			half3 tnormalZ = UnpackNormal(tex2D(_SideNormal, uvZ));

			// Swizzle world normals into tangent space and apply Whiteout blend
			tnormalX = half3(
				tnormalX.xy + IN.worldNormal.zy,
				abs(tnormalX.z) * IN.worldNormal.x
				);
			tnormalY = half3(
				tnormalY.xy + IN.worldNormal.xz,
				abs(tnormalY.z) * IN.worldNormal.y
				);
			tnormalZ = half3(
				tnormalZ.xy + IN.worldNormal.xy,
				abs(tnormalZ.z) * IN.worldNormal.z
				);


			//Texturing
			float3 x = tex2D(_SideTex, uvX);
			float3 y = tex2D(_MainTex, uvY);
			float3 z = tex2D(_SideTex, uvZ);

			//Calculate weight of the axi (axi? axises? axees??? idk)
			float3 weight = pow(abs(o.Normal), _BlendPower);
			weight /= dot(weight, float3(1, 1, 1));


			IN.worldNormal = normalize(
				tnormalX.zyx * weight.x +
				tnormalY.xzy * weight.y +
				tnormalZ.xyz * weight.z
			);

			//Dont use normal yet idk help

			c = float4((x * weight.x + y * weight.y + z * weight.z), 1) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
