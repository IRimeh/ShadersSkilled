Shader "Unlit/PortalCard"
{
	Properties
	{

		_FogColor("Fog Color", Color) = (1,1,1,1)
		_FogLength("Fog Density", Range(0.01, 1)) = 0.01
		_FadeLength("Fade Distance", Range(0, 1)) = 0.5
	}
		SubShader
	{
		Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		LOD 200
		Blend SrcAlpha OneMinusSrcAlpha
		Lighting Off ZWrite Off

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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 dist :TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float3 wpos : TEXCOORD3;
			};

			sampler2D _CameraDepthTexture;
			float4 _CameraDepthTexture_ST;
			fixed4 _FogColor;
			float _FogLength;
			float _FadeLength;

			v2f vert(appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _CameraDepthTexture);
				o.dist = UnityObjectToViewPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				o.wpos =  mul(unity_ObjectToWorld, v.vertex).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos)) * 0.1 * _FogLength;

				float dist = distance(i.wpos, _WorldSpaceCameraPos);
				float newDepth = saturate(depth - (dist * 0.1 * _FogLength));
				float partZ = length(i.dist);

				float clampedPartZ = clamp((partZ * ((1 - _FadeLength) * 0.5)), 0, 1);

				newDepth = newDepth * clampedPartZ;

				return float4(_FogColor.xyz, min(newDepth, 1));
			}
			ENDCG
		}
	}
}