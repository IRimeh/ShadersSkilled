Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Water Color", Color) = (1,1,1,1)
		_UnderWaterColor("Underwater Color", Color) = (1,1,1,1)
        _UvSwayTex ("UV Sway Texture", 2D) = "white" {}
		_NoiseTex("Intersection Noise Texture", 2D) = "white" {}
		_RippleTex("Water Ripples Texture", 2D) = "white" {}
		_Intersection("Intersection Size", Range(0, 1)) = 0.5
		_WaterFade("Water Depth Fade Multiplier", Range(0.01, 1)) = 0.5
		_RippleSize("Ripple Size", Range(0, 5)) = 1.5
		_RippleWidth("Ripple Width", Range(0, 1)) = 0.4
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
		GrabPass
		{
			"_GrabPass"
		}

        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows alpha:fade finalcolor:finalColor
        #pragma target 4.0

        sampler2D _UvSwayTex;
		sampler2D _CameraDepthTexture;
		sampler2D _NoiseTex;
		sampler2D _GrabPass;
		sampler2D _RippleTex;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed4 _UnderWaterColor;
		float _Intersection;
		float _WaterFade;
		float _RippleSize;
		float _RippleWidth;
		float4 _RippleTex_ST;

		//Ripples
		int _rippleCount;
		float4 _ripples[500];

        struct Input
        {
            float2 uv_UvSwayTex;
			float2 uv_NoiseTex;
			float2 uv_RippleTex;
			float4 screenPos;
			float4 grabPos;
			float4 wpos;
        };

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.screenPos = ComputeScreenPos(v.vertex);
			o.grabPos = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex));
			o.wpos = mul(unity_ObjectToWorld, v.vertex);
		}

		float UnderWaterDepth(float4 scrPos) 
		{
			float2 uvs = scrPos.xy / scrPos.w;
			float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uvs));
			float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(scrPos.z);

			return (backgroundDepth - surfaceDepth) * 0.1;
		}

		float Intersection(float4 scrPos) 
		{
			//Intersection detection
			float screenDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, scrPos));
			float intersectionMultiplier = 1.0 + ((1 - _Intersection) * 0.1 - 0.025);
			return 1 - saturate(intersectionMultiplier * screenDepth - scrPos.w);
		}

		float rand(float2 co) {
			float val = sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453;
			return val - floor(val);
		}

		float GetAngle(float2 dirVec, float2 startPoint)
		{
			float random = rand(startPoint);
			dirVec = normalize(dirVec);
			float angle = atan2(dirVec.x, dirVec.y);
			angle = (angle + (UNITY_PI * 0.5)) / UNITY_PI;

			if (dirVec.x < 0)
				angle = 1 - angle;
			//Add random
			/*angle += random;
			while (angle > 1)
				angle -= 1;*/

			return angle;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			fixed4 c = float4(0,0,0,0);
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1;
        }

		void finalColor(Input IN, SurfaceOutputStandard o, inout fixed4 color)
		{
			//Sample depth texture
			float depth = UnderWaterDepth(IN.screenPos);

			//Sample grabpass
			fixed4 c = tex2Dproj(_GrabPass, IN.screenPos);

			//Lerp grabpass to color based on depth of the water
			c = lerp(c, _Color, 1 - UnderWaterDepth(IN.screenPos));

			//Lerp to the underwater color based on depth of the water
			color = lerp(c, _UnderWaterColor, saturate(UnderWaterDepth(IN.screenPos) * _WaterFade));

			//Set color on intersections based on noise
			float intersect = Intersection(IN.screenPos);
			float x = tex2D(_UvSwayTex, IN.uv_UvSwayTex + float2(_Time.x * .431512, _Time.x * .32193));
			float y = tex2D(_UvSwayTex, IN.uv_UvSwayTex - float2(_Time.x * .331512, _Time.x * .42193));
			IN.uv_NoiseTex += float2(sin(x), sin(y));
			if (intersect > 0)
				color.rgb += (lerp(tex2D(_NoiseTex, IN.uv_NoiseTex).rgb, float3(1, 1, 1), intersect * 1)) * intersect;

			//Ripples
			for (int i = 0; i < _rippleCount; i++)
			{
				float size = _RippleSize * _ripples[i].w;
				float width = _RippleWidth * _ripples[i].w;

				float dist = length(float2(IN.wpos.xz - _ripples[i].xy));
				float newLength = lerp(0.45f * _ripples[i].w, 1.0 * size, _ripples[i].z);
				float timeMultiplier = newLength / size;
				float cutOff = 0.5f;
				if (timeMultiplier < cutOff)
				{
					timeMultiplier = lerp(0, 1, timeMultiplier / cutOff);
				}
				else
				{
					timeMultiplier = lerp(1, 0, (timeMultiplier - cutOff) / (1 - cutOff));
				}

				if (dist < newLength && dist > newLength - width)
				{
					float xUv = GetAngle(IN.wpos.xz - _ripples[i].xy, _ripples[i].xy);
					float yUv = ((newLength - dist) / width) * timeMultiplier;
					float2 rippleUvs = float2(xUv * _RippleTex_ST.x, yUv * _RippleTex_ST.y);
					
					color = lerp(color, float4(1, 1, 1, 1), tex2D(_RippleTex, rippleUvs));
				}
			}
		}
        ENDCG
    }
    FallBack "Diffuse"
}
