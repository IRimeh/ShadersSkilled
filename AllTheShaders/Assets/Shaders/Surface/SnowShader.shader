Shader "Custom/SnowShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

		_DefaultTess("Default Tessellation", Range(1, 64)) = 16
		_Tess("Increased Tessellation", Range(1,64)) = 32
		_TrampledSnowColor("Trampled Snow Color", Color) = (1,1,1,1)
		_SnowDepthTex("Depth Texture", 2D) = "white" {}
		_MaxDepth("Max Snow Depth", Range(0, 5)) = 1

		_NoiseTex("Noise Texture", 2D) = "white" {}
		_NoiseDepth("Noise Depth", Range(0, 1)) = 0.5
		_NoiseTiling("Noise Tiling", Range(0, 10)) = 0.5
		_SecondNoiseDepth("Second Noise Depth", Range(0, 2)) = 0.25
		_SecondNoiseTiling("Second Noise Tiling", Range(0, 10)) = 3

		_BlurStepAmount("Blur Step Amount", Range(0, 10)) = 6
		_BlurStepSize("Blur Step Size", float) = 0.002

		_VectorLength("Vector Length (norm calc)", float) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert tessellate:tessFixed fullforwardshadows addshadow
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _SnowDepthTex;
		sampler2D _NoiseTex;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed4 _TrampledSnowColor;
		float _DefaultTess;
		float _Tess;
		float _MaxDepth;
		float _NoiseDepth;
		float _NoiseTiling;
		float _SecondNoiseDepth;
		float _SecondNoiseTiling;
		float _BlurStepAmount;
		float _BlurStepSize;

		float _VectorLength;

		struct appdata
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;

			// we will use this to pass custom data to the surface function
			fixed4 color : COLOR0;
		};

        struct Input
        {
            float2 uv_MainTex;
			float4 color : COLOR;
			float3 normal : NORMAL;
        };

		float4 tessFixed(appdata v0, appdata v1, appdata v2)
		{
			float tess = _DefaultTess;
			float boxSize = 8;
			float stepSize = 0.02;

			//Check if drawn on the depth map close to the vertex
			for (float i = 0; i < boxSize; i++)
			{
				for (float j = 0; j < boxSize; j++)
				{
					float4 txcoord = v0.texcoord + float4(i * stepSize, j * stepSize, 0, 0);

					if (tex2Dlod(_SnowDepthTex, float4(1 - txcoord.x, txcoord.y, txcoord.z, txcoord.w)).r > 0.01) 
					{
						//Return the higher tessellation value
						return _Tess;
					}
				}
			}
			return tess;
		}

		float CalculateSnowHeight(float2 uvs, out float depth)
		{
			float halfMax = _MaxDepth * 0.5;
			float noiseDepth = halfMax * _NoiseDepth;

			//float depth = 0;
			float noise = 0;

			for (float i = 0; i < _BlurStepAmount; i++)
			{
				for (float j = 0; j < _BlurStepAmount; j++)
				{
					float xStep = (i - (_BlurStepAmount / 2)) * _BlurStepSize;
					float yStep = (j - (_BlurStepAmount / 2)) * _BlurStepSize;

					//Sample depth texture
					float depthVal = tex2Dlod(_SnowDepthTex, float4(1 - uvs.x + xStep, uvs.y + yStep, 0, 0)).r;
					depth += depthVal;

					//Sample noise texture
					float firstNoiseVal = tex2Dlod(_NoiseTex, float4(float2(uvs.x + xStep, uvs.y + yStep) * _NoiseTiling, 0, 0)).r;
					float secondNoiseVal = tex2Dlod(_NoiseTex, float4(float2(uvs.x + xStep, uvs.y + yStep) * _SecondNoiseTiling, 0, 0)).r;
					float noiseVal = (firstNoiseVal * noiseDepth) + (secondNoiseVal * _SecondNoiseDepth);

					//Add noise if nothing touched the snow yet
					if (abs(depthVal < 0.001))
						noise += noiseVal;
				}
			}

			//Divide by amount of samples taken
			depth /= (_BlurStepAmount * _BlurStepAmount);
			noise /= (_BlurStepAmount * _BlurStepAmount);
			depth -= noise;

			return _MaxDepth * (1 - depth);
		}

		void vert(inout appdata v)
		{
			float depth;

			float4 v0 = v.vertex;
			float4 v1 = v0 + mul(unity_WorldToObject, float4(_VectorLength, 0.0, 0.0, 0.0));
			float4 v2 = v0 + mul(unity_WorldToObject, float4(0.0, 0.0, _VectorLength, 0.0));

			v0.y += CalculateSnowHeight(v.texcoord.xy, depth);
			v1.y += CalculateSnowHeight(v.texcoord.xy + float2(0.01, 0), depth);
			v2.y += CalculateSnowHeight(v.texcoord.xy + float2(0, 0.01), depth);

			float3 norm = cross(v2.xyz - v0.xyz, v1.xyz - v0.xyz);
			v.normal = normalize(norm);

			v.vertex.y += v0.y;

			//Pass depth to surf
			v.color.g = depth;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float depth = IN.color.g;

			//Change color depending on noise and depth
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

			o.Albedo = lerp(float4(c.rgb, 1), float4(_TrampledSnowColor.rgb,1), depth).rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
