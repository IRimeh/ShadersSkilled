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

		struct appdata
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;

			// we will use this to pass custom data to the surface function
			fixed4 color : COLOR;
		};

        struct Input
        {
            float2 uv_MainTex;
			float4 color : COLOR;
        };

		float4 tessFixed(appdata v0, appdata v1, appdata v2)
		{
			float tess = _DefaultTess;
			float boxSize = 16;
			float stepSize = 0.01;

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

		void vert(inout appdata v)
		{
			float halfMax = _MaxDepth * 0.5;
			float noiseDepth = halfMax * _NoiseDepth;

			//Blur on reading of depth tex
			float boxSize = _BlurStepAmount;
			float stepSize = _BlurStepSize;
			float depth = 0;
			float noise = 0;

			for (float i = 0; i < boxSize; i++)
			{
				for (float j = 0; j < boxSize; j++)
				{
					//Calculate depth around vertex
					float depthVal = tex2Dlod(_SnowDepthTex, float4(float2(1 - v.texcoord.x + ((i - (boxSize / 2)) * stepSize), v.texcoord.y + ((j - (boxSize / 2)) * stepSize)), v.texcoord.zw)).r;					
					depth += depthVal;
					
					float noiseVal = tex2Dlod(_NoiseTex, float4(float2(v.texcoord.x + ((i - (boxSize / 2)) * stepSize), v.texcoord.y + ((j - (boxSize / 2)) * stepSize)) * _NoiseTiling, v.texcoord.zw)) * noiseDepth;
					noiseVal += tex2Dlod(_NoiseTex, float4(float2(v.texcoord.x + ((i - (boxSize / 2)) * stepSize), v.texcoord.y + ((j - (boxSize / 2)) * stepSize)) * _SecondNoiseTiling, v.texcoord.zw)) * _SecondNoiseDepth;

					if (abs(depthVal < 0.001))
						noise += noiseVal;
				}
			}
			depth /= (boxSize * boxSize);
			noise /= (boxSize * boxSize);

			depth -= noise;

			//Vertex displacement based on depth
			float addedHeight = (_MaxDepth * (1 - depth));
			v.vertex.y += addedHeight;

			//Pass depth to surf
			v.color.r = depth;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float depth = IN.color.r;
			float noise = tex2D(_NoiseTex, IN.uv_MainTex * 100);

			//Change color depending on noise and depth
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			c = lerp(float4(c.rgb, 1), float4(_TrampledSnowColor.rgb, 1), noise * 0.5);

			o.Albedo = lerp(float4(c.rgb, 1), float4(_TrampledSnowColor.rgb,1), depth).rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
