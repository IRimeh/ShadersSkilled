Shader "Custom/WaterShader_V2.0"
{
    Properties
    {
        _Color ("Water Color", Color) = (1,1,1,1)
		_FogColor ("Fog Color", Color) = (1,1,1,1)
		_FogDensity("Fog Density", Range(0, 3)) = 0.1
		_RefractionStrength("Refraction Strength", Range(0, 1)) = 0.25

		[Header(Ripples)]
		_RipplesTex("Ripples Texture", 2D) = "black" {}
		_RippleStrength("Ripple Strength", float) = 3

		[Header(Waves)]
		_WaveHeight("Wave Height", float) = 0.1
		_VectorLength("Vector Length", Range(0.0001, 1)) = 0.1

		[Header(Wave 1)]
		_NoiseTex("Noise Texture", 2D) = "white" { }
		_Wave1Speed("Wave Speed", float) = 1
		_Wave1Direction("Wave Direction", Vector) = (1,1,1,1)
		_Wave1Weight("Wave Weight", Range(0, 1)) = 1

		[Header(Wave 2)]
		_NoiseTex2("Noise Texture", 2D) = "white" { }
		_Wave2Speed("Wave Speed", float) = 1
		_Wave2Direction("Wave Direction", Vector) = (1,1,1,1)
		_Wave2Weight("Wave Weight", Range(0, 1)) = 1

		[Header(Wave 3)]
		_NoiseTex3("Noise Texture", 2D) = "white" { }
		_Wave3Speed("Wave Speed", float) = 1
		_Wave3Direction("Wave Direction", Vector) = (1,1,1,1)
		_Wave3Weight("Wave Weight", Range(0, 1)) = 1


		[Header(Default Variables)]
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 200
		Cull Off

		GrabPass
		{
			"_GrabTexture"
		}

        CGPROGRAM
        #pragma surface surf Standard vertex:vert alpha:fade finalcolor:ResetAlpha 
        #pragma target 3.0

		sampler2D _CameraDepthTexture;
		sampler2D _GrabTexture;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed4 _FogColor;
		float _FogDensity;
		float4 _CameraDepthTexture_TexelSize;
		float _RefractionStrength;

		//Ripples
		sampler2D _RipplesTex;
		float _RippleStrength;

		//Waves
		float _WaveHeight;
		float _VectorLength;

		//Wave 1
		sampler2D _NoiseTex;
		float4 _NoiseTex_ST;
		float _Wave1Speed;
		float2 _Wave1Direction;
		float _Wave1Weight;

		//Wave 2
		sampler2D _NoiseTex2;
		float4 _NoiseTex2_ST;
		float _Wave2Speed;
		float2 _Wave2Direction;
		float _Wave2Weight;

		//Wave 3
		sampler2D _NoiseTex3;
		float4 _NoiseTex3_ST;
		float _Wave3Speed;
		float2 _Wave3Direction;
		float _Wave3Weight;

        struct Input
        {
			float4 vertex : POSITION;
            float2 uv_MainTex;
			float4 screenPos;
			float4 rippleCol;
        };

		float2 AlignWithGrabTexel(float2 uv) {
			return
				(floor(uv * _CameraDepthTexture_TexelSize.zw) + 0.5) *
				abs(_CameraDepthTexture_TexelSize.xy);
		}

		float UnderWaterDepth(float4 screenPos, float2 uvs)
		{
			//Sample depth tex
			float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uvs));
			float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
			return (backgroundDepth - surfaceDepth) * 0.5;
		}

		float4 UnderWaterDepthAdjustedUvs(float4 screenPos, float3 tangentSpaceNormal)
		{
			//Uvs
			float2 offset = tangentSpaceNormal.xy * _RefractionStrength;
			offset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
			float2 uvs = AlignWithGrabTexel((screenPos.xy + offset) / screenPos.w);

			//Sample camera depth texture
			float depthDifference = UnderWaterDepth(screenPos, uvs);

			offset *= saturate(depthDifference);
			uvs = AlignWithGrabTexel((screenPos.xy + offset) / screenPos.w);
			return UnderWaterDepth(screenPos, uvs);
		}

		float4 ColorBelowWater(float4 screenPos, float3 tangentSpaceNormal) 
		{
			//Uvs
			float2 offset = tangentSpaceNormal.xy * _RefractionStrength;
			offset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
			float2 uvs = AlignWithGrabTexel((screenPos.xy + offset) / screenPos.w);

			//Sample camera depth texture
			float depthDifference = UnderWaterDepth(screenPos, uvs);

			offset *= saturate(depthDifference);
			uvs = AlignWithGrabTexel((screenPos.xy + offset) / screenPos.w);
			depthDifference = UnderWaterDepth(screenPos, uvs);

			//Sample grab pass
			float4 backgroundColor = saturate(tex2D(_GrabTexture, uvs));
			float fogFactor = exp2(-_FogDensity * depthDifference);
			return lerp(_FogColor, backgroundColor, fogFactor);
		}

		float2 VertexDisplacement(float2 pos, float2 uvs)
		{
			_Wave1Direction = normalize(_Wave1Direction);
			_Wave2Direction = normalize(_Wave2Direction);
			_Wave3Direction = normalize(_Wave3Direction);
			float noise1 = tex2Dlod(_NoiseTex, float4((pos + (float2(_Wave1Direction.x * _Time.x, _Wave1Direction.y * _Time.x) * _Wave1Speed)) * _NoiseTex_ST.xy, 0, 0)).r * _Wave1Weight;
			float noise2 = tex2Dlod(_NoiseTex2, float4((pos + (float2(_Wave2Direction.x * _Time.x, _Wave2Direction.y * _Time.x) * _Wave2Speed)) * _NoiseTex2_ST.xy, 0, 0)).r * _Wave2Weight;
			float noise3 = tex2Dlod(_NoiseTex3, float4((pos + (float2(_Wave3Direction.x * _Time.x, _Wave3Direction.y * _Time.x) * _Wave3Speed)) * _NoiseTex3_ST.xy, 0, 0)).r * _Wave3Weight;

			float totalWeight = _Wave1Weight + _Wave2Weight + _Wave3Weight;
			float totalNoise = (noise1 + noise2 + noise3) / totalWeight;

			totalNoise *= max(1 - tex2Dlod(_RipplesTex, float4(uvs, 0, 0)).r, 0);
			totalNoise += tex2Dlod(_RipplesTex, float4(uvs, 0, 0)).r * _RippleStrength;

			return totalNoise;
		}

		void vert(inout appdata_full v, out Input IN) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, IN);
			IN.screenPos = ComputeScreenPos(v.vertex);


			float4 v0 = v.vertex;
			float4 v1 = v0 + mul(unity_WorldToObject, float4(_VectorLength, 0.0, 0.0, 0.0));
			float4 v2 = v0 + mul(unity_WorldToObject, float4(0.0, 0.0, _VectorLength, 0.0));

			v0.y += VertexDisplacement(mul(unity_ObjectToWorld, v0).xz, v.texcoord) * _WaveHeight;
			v1.y += VertexDisplacement(mul(unity_ObjectToWorld, v1).xz, v.texcoord + float2(0.0005, 0)) * _WaveHeight;
			v2.y += VertexDisplacement(mul(unity_ObjectToWorld, v2).xz, v.texcoord + float2(0, 0.0005)) * _WaveHeight;

			float3 vn = cross(v2.xyz - v0.xyz, v1.xyz - v0.xyz);
			v.normal = normalize(vn);

			v.vertex = v0;
			IN.vertex = v.vertex;
			IN.rippleCol = tex2Dlod(_RipplesTex, v.texcoord);
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			fixed4 c = _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

			//Fog
			float fog = ColorBelowWater(IN.screenPos, o.Normal);

			o.Emission = fog * _FogColor + (IN.rippleCol * 0.25);
        }

		void ResetAlpha(Input IN, SurfaceOutputStandard o, inout fixed4 color) 
		{
			color.a = lerp(0.5, 1, step(mul(unity_ObjectToWorld, IN.vertex).y, _WorldSpaceCameraPos.y));
		}
        ENDCG
    }
}
