Shader "Unlit/DepthBasedBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_BlurIterations("Blur Iterations", float) = 8
		_BlurStepSize("Blur Step Size", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

		GrabPass
		{
			"_GrabPass"
		}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
				float4 grabPos : TEXCOORD2;
				float3 dist : TEXCOORD3;
				half3 worldRefl : TEXCOORD4;
            };

            sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler2D _GrabPass;
            float4 _MainTex_ST;
			float4 _CameraDepthTexture_ST;
			fixed4 _Color;
			float _BlurIterations;
			float _BlurStepSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.grabPos = ComputeGrabScreenPos(o.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				o.dist = distance(mul(unity_ObjectToWorld, v.vertex), _WorldSpaceCameraPos);
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				//Sample depth tex
				float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos)) / _ProjectionParams.z;

				//Sample grab pass
				float4 grabPass = tex2Dproj(_GrabPass, i.grabPos);
				

				//Blurring
				float dist = i.dist * 0.05;
				float4 gPos = i.grabPos;
				float4 blur = 0;
				float halfIterations = (_BlurIterations * 0.5);
				for (float i = 0; i < _BlurIterations; i++)
				{
					for (float j = 0; j < _BlurIterations; j++)
					{
						float x = i - halfIterations;
						float y = j - halfIterations;
						blur += tex2Dproj(_GrabPass, gPos + float4(_BlurStepSize * x * dist, _BlurStepSize * y * dist, 0, 0));
					}
				}
				blur /= (_BlurIterations * _BlurIterations);

				col = blur;
				return col;
            }
            ENDCG
        }
    }
}
