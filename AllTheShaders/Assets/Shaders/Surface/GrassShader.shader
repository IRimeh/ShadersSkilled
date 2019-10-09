Shader "Custom/GrassShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        //_MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

		_GrassMaxDisplacement("Max Grass Displacement", Range(0, 5)) = 1
		[Header(Grass Movement Options)]
		_WindColor("Wind Color", Color) = (1,1,1,1)
		_WindWaveTex("Wind Wave Texture", 2D) = "black" {}
		_WindChangeAmount("Wind Change Amount", Range(0, 50)) = 1
		_WindChangeSpeed("Wind Change Speed", Range(0, 5)) = 1

		[Header(Grass Blade Movement Options)]
		_NoiseTex("Noise Texture", 2D) = "black" {}
		_WobbleSpeed("Wobble Speed", Range(0, 1)) = 0.2
		_WobbleAmount("Wobble Amount", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows addshadow
        #pragma target 3.0

        //sampler2D _MainTex;
		sampler2D _NoiseTex;
		sampler2D _WindWaveTex;
		
		float4 _NoiseTex_ST;
		float4 _WindWaveTex_ST;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		fixed4 _WindColor;

		float _GrassMaxDisplacement;
		float _WindChangeAmount;
		float _WindChangeSpeed;
		float _WindScale;

		float _WobbleSpeed;
		float _WobbleAmount;
		
		//Global
		float _GrassHeight;
		float3 _WindDirection;
		float _WindStrength;

		struct Input
		{
			float2 uv_NoiseTex;
			float yVal;
			float windVal;
		};

		float4 WindDisplacement(appdata_full v, inout Input IN)
		{
			//Save start position
			float4 startVertexPos = v.vertex;
			float4 startwpos = mul(unity_ObjectToWorld, v.vertex);
			float4 wpos = startwpos;

			//Grass direction wobble
			float4 uvOffset1 = float4((_Time.x * _WindChangeSpeed) * -normalize(_WindDirection).y, (_Time.x * _WindChangeSpeed) * normalize(_WindDirection).x, 0, 0);
			IN.windVal = tex2Dlod(_WindWaveTex, float4(startwpos.x * 0.01 * _WindWaveTex_ST.x, startwpos.z * 0.01 * _WindWaveTex_ST.y, 0, 0) + uvOffset1);
			float tempVal = tex2Dlod(_WindWaveTex, float4(startwpos.x * 0.01 * _WindWaveTex_ST.x, startwpos.z * 0.01 * _WindWaveTex_ST.y, 0, 0) + uvOffset1) - 0.5;
			tempVal *= IN.yVal * _WindChangeAmount;
			float2 directionOffset = float2(-_WindDirection.y, _WindDirection.x) * tempVal;
			_WindDirection.xy += directionOffset.xy;

			//Grass blade wobble
			float4 uvOffset2 = float4(_Time.x * _WobbleSpeed, _Time.x * _WobbleSpeed, 0, 0);
			float val = tex2Dlod(_NoiseTex, float4(startwpos.x * _NoiseTex_ST.x * 0.01, startwpos.z * _NoiseTex_ST.y * 0.01, 0, 0) + uvOffset2) - 0.5;
			val *= IN.yVal * _WobbleAmount * 5;
			float2 tempOffset = float2(-_WindDirection.y, _WindDirection.x) * val;
			_WindDirection.xy += tempOffset.xy;
			//wpos += float4(displacementOffset.x, 0, displacementOffset.y, 0);

			//Set vertex displacement based on direction and wind strength
			float2 windOffset = (normalize(_WindDirection.xy) * _WindStrength) * IN.yVal * _GrassHeight * _GrassMaxDisplacement;
			wpos += float4(windOffset.x, 0, windOffset.y, 0);

			//Subtract old position from new to get the displacement value
			float4 displacement = mul(unity_WorldToObject, wpos) - startVertexPos;

			return displacement;
		}

		float4 AvoidObjects(appdata_full v, Input IN)
		{
			//Save start position
			float4 startVertexPos = v.vertex;
			float4 startwpos = mul(unity_ObjectToWorld, v.vertex);
			float4 wpos = startwpos;
			
			return float4(0, 0, 0, 0);
		}

		void vert(inout appdata_full v, out Input IN)
		{
			UNITY_INITIALIZE_OUTPUT(Input, IN);

			//0 to 1 value of height of grass
			IN.yVal = (v.vertex.y / _GrassHeight);
			IN.yVal = pow(IN.yVal, 2);
			
			v.vertex += WindDisplacement(v, IN);
			v.vertex += AvoidObjects(v, IN);
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = _Color;
			c = lerp(c, c - float4(0.2, 0.2, 0.2, 0), 1 - IN.yVal);

			o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
