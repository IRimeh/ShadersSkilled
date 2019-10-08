Shader "Unlit/DeepFriedMeme"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_BlurIterations("Blur Iterations", float) = 8
		_BlurStepSize("Blur Step Size", Range(0, 1)) = 0.5
	}
		SubShader
		{
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

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
				#define E 2.71828182846

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
				};

				sampler2D _MainTex;
				sampler2D _CameraDepthTexture;
				sampler2D _GrabPass;
				float4 _MainTex_ST;
				float4 _CameraDepthTexture_ST;
				fixed4 _Color;
				float _BlurIterations;
				float _BlurStepSize;

				float rand(float2 co) {
					float val = sin(dot(co.xy, float2(12.9898, 78.233))) * 438.5453;
					return val - floor(val);
				}

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.screenPos = ComputeScreenPos(o.vertex);
					o.grabPos = ComputeGrabScreenPos(o.vertex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					float4 g = i.grabPos;
					float4 scrPos = i.screenPos;

					fixed4 col = tex2D(_MainTex, i.uv);
					//Sample depth tex
					float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos)) / _ProjectionParams.z;
					//Sample grab pass
					float4 grabPass = tex2Dproj(_GrabPass, g);

					//Box blur
					float4 blurredGrabPass = float4(0, 0, 0, 1);
					float depthVal = (1 - depth);
					for (float i = 0; i < _BlurIterations; i++)
					{
						for (float j = 0; j < _BlurIterations; j++)
						{
							float x = i - (_BlurIterations * 0.5);
							float y = j - (_BlurIterations * 0.5);
							float randomVal = rand(g.xy + float2(x, y));
							blurredGrabPass += tex2Dproj(_GrabPass, g + float4(x * 0.1 * _BlurStepSize * randomVal, y * 0.1 * _BlurStepSize * randomVal, 0, 0));
						}
					}
					blurredGrabPass /= (_BlurIterations * _BlurIterations);

					col = lerp(grabPass, blurredGrabPass, 1 - _ProjectionParams.z);
					return col;
				}
				ENDCG
			}
		}
}
