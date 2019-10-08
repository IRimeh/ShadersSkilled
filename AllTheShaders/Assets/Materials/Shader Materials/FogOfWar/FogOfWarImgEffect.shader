Shader "Hidden/FogOfWarImgEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_RenderTex("Render Texture", 2D) = "white" {}
		_ShowOld("Show Old?", Range(0, 1)) = 0
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 wpos : TEXCOORD1;
				float2 oldUv : TEXCOORD2;
            };


            sampler2D _MainTex;
			sampler2D _RenderTex;
			float _ShowOld;
			float3 _RenderCameraPos;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.wpos = mul(unity_ObjectToWorld, v.vertex);
				o.oldUv = o.uv;

				float dist = distance(_RenderCameraPos, _WorldSpaceCameraPos);
				float percDist = dist / _ProjectionParams.z;
				/*o.oldUv.x = (o.oldUv.x * (1 + dist));
				o.oldUv.y = (o.oldUv.y * (1 + dist));*/
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				if (_ShowOld > 0.5) 
				{
					col = tex2D(_RenderTex, i.oldUv);
				}
                return col;
            }
            ENDCG
        }
    }
}
