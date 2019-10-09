﻿Shader "Hidden/ObjectPlacerShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (0,0,0,0)
		_MousePos ("Mouse Position", Vector) = (0,0,0,0)
		_Radius ("Radius", float) = 10
		_ShowRadius("Show Radius", float) = 0
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimSize("Rim Size", float) = 0.5
    }
		SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

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
				float2 uv_depth : TEXCOORD1;
				float4 interpolatedRay : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
			};

			float4x4 _FrustumCorners;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;
				o.uv_depth = v.uv.xy;
				o.interpolatedRay = v.ray;
				o.screenPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
				return o;
			}

			sampler2D _MainTex;
			sampler2D_float _CameraDepthTexture;
			fixed4 _Color;
			fixed4 _RimColor;
			float3 _MousePos;
			float _Radius;
			float _ShowRadius;
			float _RimSize;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
				float linearDepth = Linear01Depth(rawDepth);
				float4 wsDir = linearDepth * i.interpolatedRay;
				float3 wsPos = _WorldSpaceCameraPos + wsDir;

				float dist = distance(wsPos, _MousePos);
				float4 fillCol = lerp(col, _Color, 0.75);
				float4 rimCol = lerp(col, _RimColor, 0.9);

				if (_ShowRadius >= 0.001f && dist < _Radius) 
				{
					return fillCol;
				}
				else if (_ShowRadius >= 0.001f && dist >= _Radius && dist < _Radius + _RimSize) 
				{
					if (dist < _Radius + (_RimSize * 0.5))
					{
						return lerp(fillCol, rimCol, (dist - _Radius) / (_RimSize * 0.5));
					}
					else 
					{
						return rimCol;
					}
					return rimCol;
				}

				return col;
			}
			ENDCG
		}
	}
}
