Shader "Custom/TriPlanarShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Top Texture", 2D) = "white" {}
		_SideTex("Side Texture", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _SideTex;
		float4 _MainTex_ST;
		float4 _SideTex_ST;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

        struct Input
        {
            float2 uv_MainTex;
			float3 wpos : POSITION;
        };

		void vert(inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			fixed4 c = _Color;

			float3 x;
			float3 y;
			float3 z;
			//Mirror texture when necessary
			if(o.Normal.x > 0)
				x = tex2D(_SideTex, float2(IN.wpos.z, IN.wpos.y + 0.5) * _SideTex_ST.xy).rgb;
			else
				x = tex2D(_SideTex, float2(-IN.wpos.z, IN.wpos.y + 0.5) * _SideTex_ST.xy).rgb;
			if(o.Normal.y > 0)
				y = tex2D(_MainTex, float2(IN.wpos.xz) * _MainTex_ST.xy).rgb;
			else
				y = tex2D(_MainTex, float2(-IN.wpos.x, IN.wpos.z) * _MainTex_ST.xy).rgb;
			if(o.Normal.z > 0)
				z = tex2D(_SideTex, float2(IN.wpos.x + 0.5, IN.wpos.y) * _SideTex_ST.xy).rgb;
			else
				z = tex2D(_SideTex, float2(-IN.wpos.x + 0.5, IN.wpos.y) * _SideTex_ST.xy).rgb;

			//Calculate weight of the axi (axi? axises? axees??? idk)
			float3 weight = abs(o.Normal);
			weight /= (weight.x + weight.y + weight.z);

			c = float4((x * weight.x + y * weight.y + z * weight.z), 1) + ((_Color - 0.5) * 2);


            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
