Shader "Custom/TransitionShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

		[Header(Transition Variables)]
		[Toggle]
		_StartAlpha("Start Transparent", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

		////////////////////
		// QUEUE TUTORIAL //
		////////////////////
		// 1. Starting opaque objects always queue 3100
		// 2. Starting transparent objects that are replacements queue 3000
		// 3. Starting transparent objects that appear from nothing queue 3110

		Pass
		{
			ColorMask 0
		}

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert alpha:fade
        #pragma target 4.0

        sampler2D _MainTex;
		sampler2D _NormalMap;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

		//Transition variables
		sampler2D _TransitionTexture;
		float2 _TransitionTextureTiling;
		fixed4 _TransitionColor;
		fixed4 _TransitionSecondaryColor;
		float3 _OriginPosition = (0,0,0);
		float _StartAlpha;
		float _TransitionRange;
		float _TransitionWidth;
		float _TransitionOppositeWidth;
		float _Thickening;
		float _Thinning;

        struct Input
        {
            float2 uv_MainTex;
			float3 wpos;
			float3 vertex;
        };

		void vert(inout appdata_full v, out Input IN)
		{
			UNITY_INITIALIZE_OUTPUT(Input, IN)
			IN.vertex = v.vertex;
			IN.wpos = mul(unity_ObjectToWorld, v.vertex);
		}

		float AlphaTransition(Input IN, out float4 col)
		{
			float alpha = 0;
			col = float4(0, 0, 0, 0);

			float dist = distance(IN.wpos.xz, _OriginPosition.xz);
			float tex = tex2D(_TransitionTexture, IN.wpos.xz * _TransitionTextureTiling).r;
			float perc = pow(1 - pow((dist - (_TransitionRange - (_TransitionWidth))) / _TransitionWidth, max(_Thinning, 1)), max(_Thickening, 1));
			if (_StartAlpha > 0.5)
			{
				//Transparent start
				if (dist < _TransitionRange)
				{
					alpha = 1;
					if (dist > _TransitionRange - _TransitionWidth)
					{
						if (tex > perc)
							col = _TransitionColor;
						else if (tex > perc - 0.3)
							col = float4(lerp(col.rgb, _TransitionSecondaryColor.rgb, 1 - perc), 1 - perc);
					}
				}
				else
				{
					alpha = 0;
				}
			}
			else
			{
				//Opaque start
				if (dist > _TransitionRange)
				{
					if (dist < _TransitionRange + (_TransitionWidth * _TransitionOppositeWidth))
					{
						perc = 1 - pow(1 - pow((dist - _TransitionRange) / (_TransitionWidth * _TransitionOppositeWidth), max(_Thinning, 1)), max(_Thickening, 1));
						if (tex > perc)
							col = _TransitionColor;
						else if (tex > perc - 0.3)
							col = float4(lerp(col.rgb, _TransitionSecondaryColor.rgb, 1 - perc), 1 - perc);
					}
					alpha = 1;
				}
				else
				{
					alpha = 0;
					if (dist > _TransitionRange - _TransitionWidth)
					{
						if (tex > perc)
						{
							col = _TransitionColor;
							alpha = 1;
						}
						else if (tex > perc - 0.3) 
						{
							col = float4(lerp(col.rgb, _TransitionSecondaryColor.rgb, 1 - perc), 1 - perc);
							alpha = 0;
						}
					}
				}
			}

			return alpha;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1 - _StartAlpha;

			float4 newCol;
			o.Alpha = AlphaTransition(IN, newCol);
			o.Albedo = lerp(o.Albedo, newCol, newCol.a);
			o.Emission = newCol;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
