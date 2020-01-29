Shader "Unlit/StencilMask"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		ColorMask 0
		ZWrite Off
		Stencil
		{
			Ref 1
			Pass replace
		}

		Pass
		{
			Cull Front
			ZTest Less

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			struct appdata { float4 vertex : POSITION; };
			struct v2f { float4 vertex : SV_POSITION; };

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return float4(1,1,1,1);
			}
			ENDCG
		}

		Pass
		{
			Cull Back
			ZTest Greater

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			struct appdata { float4 vertex : POSITION; };
			struct v2f { float4 vertex : SV_POSITION; };

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return float4(1,1,1,1);
			}
			ENDCG
		}
    }
}
