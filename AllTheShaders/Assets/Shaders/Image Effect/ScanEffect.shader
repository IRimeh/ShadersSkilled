Shader "Hidden/ScanEffect"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Distance("Distance", float) = 0
		_RimStartColor("RimStartColor", Color) = (0,0,0,0)
		_RimEndColor("RimEndColor", Color) = (0,0,0,0)
		_RimWidth("RimWidth", float) = 1
		_BackgroundColor("BackgroundColor", Color) = (0,0,0,0)
		_BackgroundFadeColor("BackgroundFadeColor", Color) = (0,0,0,0)
		_LineColor("LineColor", Color) = (0,0,0,0)
		_BackgroundWidth("BackgroundWidth", float) = 3
		_LineDensity("LineDensity", float) = 2
		_LineSize("LineSize", Range(0, 100)) = 100
	}
		SubShader
		{
			Cull Off 
			ZWrite Off 
			ZTest Always

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
					float4 ray : TEXCOORD1;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float2 uv : TEXCOORD0;
					float4 interpolatedRay : TEXCOORD1;
					float4 screenPos : TEXCOORD2;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv.xy;
					o.interpolatedRay = v.ray;
					o.screenPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
					return o;
				}

				sampler2D _MainTex;
				sampler2D_float _CameraDepthTexture;
				float4 _WorldSpaceScannerPos;

				float _Distance;

				//Rim variables
				float _RimWidth;
				float4 _RimStartColor;
				float4 _RimEndColor;
				//Background variables
				float4 _BackgroundColor;
				float4 _BackgroundFadeColor;
				float4 _LineColor;
				float _LineDensity;
				float _LineSize;
				float _BackgroundWidth;

				float4 horizBars(float y)
				{
					return 1 - saturate(round(abs(frac(y * (100 - _LineSize)) * _LineDensity)));
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv);

					float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv));
					float linearDepth = Linear01Depth(rawDepth);
					float4 wsDir = linearDepth * i.interpolatedRay;
					float3 wsPos = _WorldSpaceCameraPos + wsDir;

					float dist = distance(wsPos, _WorldSpaceScannerPos);

					//Rim
					if (dist < _Distance && dist > _Distance - _RimWidth)
					{
						float sat = max((dist - (_Distance - _RimWidth)), 0);
						if (sat > 0)
							sat = sat / _RimWidth;
						col.rgb = lerp(col.rgb, lerp(_RimStartColor, _RimEndColor, sat), 0.9f);
					}

					//Background
					if (dist < _Distance - _RimWidth && dist > _Distance - _RimWidth - _BackgroundWidth)
					{
						float sat = max((dist - (_Distance - _RimWidth - _BackgroundWidth)), 0);
						if (sat > 0)
							sat = sat / _BackgroundWidth;

						_BackgroundFadeColor.rgb = lerp(col.rgb, _BackgroundFadeColor, sat);
						col.rgb = lerp(col.rgb, _BackgroundColor, sat);
						col.rgb = lerp(col.rgb, _BackgroundFadeColor, i.screenPos.y / 2);

						//Horizontal bars
						col.rgb += horizBars(i.screenPos.y) * _LineColor.rgb * sat * _LineColor.a;
					}

					return col;
				}
				ENDCG
			}
		}
}
