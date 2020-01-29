Shader "Hidden/CausticsShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_CausticAmount("Caustic Amount", Range(0, 1)) = 0.9
		_CausticsColor("Caustics Color", Color) = (1,1,1,1)
		_CausticsStrength("Caustics Strength", Range(-2, 2)) = 0.1
		_CausticsFallOffDist("Caustics Fall Off Distance", float) = 10

		[Header(Waves)]
		_WaveHeight("Wave Height", float) = 0.1
		_VectorLength("Vector Length", Range(0.0001, 1)) = 0.1

		[Header(Wave 1)]
		_NoiseTex("Noise Texture", 2D) = "white" { }
		_Wave1Speed("Wave Speed", float) = 1
		_Wave1Direction("Wave Direction", Vector) = (1,1,1,1)
		_Wave1Weight("Wave Weight", Range(0, 1)) = 1

		[Header(Wave 2)]
		_NoiseTex2("Noise Texture", 2D) = "white" { }
		_Wave2Speed("Wave Speed", float) = 1
		_Wave2Direction("Wave Direction", Vector) = (1,1,1,1)
		_Wave2Weight("Wave Weight", Range(0, 1)) = 1

		[Header(Wave 3)]
		_NoiseTex3("Noise Texture", 2D) = "white" { }
		_Wave3Speed("Wave Speed", float) = 1
		_Wave3Direction("Wave Direction", Vector) = (1,1,1,1)
		_Wave3Weight("Wave Weight", Range(0, 1)) = 1
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

            sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler2D _CameraDepthNormalsTexture;
			float3 _planePosition;
			float2 _planeExtents;
			float4x4 _viewToWorld;
			fixed4 _CausticsColor;
			float _CausticAmount;
			float _CausticsStrength;
			float _CausticsFallOffDist;

			//Waves
			float _WaveHeight;
			float _VectorLength;

			//Wave 1
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float _Wave1Speed;
			float2 _Wave1Direction;
			float _Wave1Weight;

			//Wave 2
			sampler2D _NoiseTex2;
			float4 _NoiseTex2_ST;
			float _Wave2Speed;
			float2 _Wave2Direction;
			float _Wave2Weight;

			//Wave 3
			sampler2D _NoiseTex3;
			float4 _NoiseTex3_ST;
			float _Wave3Speed;
			float2 _Wave3Direction;
			float _Wave3Weight;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float4 ray : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 interpolatedRay : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float4 ray : TEXCOORD3;
            };

			float2 VertexDisplacement(float2 pos)
			{
				_Wave1Direction = normalize(_Wave1Direction);
				_Wave2Direction = normalize(_Wave2Direction);
				_Wave3Direction = normalize(_Wave3Direction);
				float noise1 = tex2Dlod(_NoiseTex, float4((pos + (float2(_Wave1Direction.x * _Time.x, _Wave1Direction.y * _Time.x) * _Wave1Speed)) * _NoiseTex_ST.xy, 0, 0)).r * _Wave1Weight;
				float noise2 = tex2Dlod(_NoiseTex2, float4((pos + (float2(_Wave2Direction.x * _Time.x, _Wave2Direction.y * _Time.x) * _Wave2Speed)) * _NoiseTex2_ST.xy, 0, 0)).r * _Wave2Weight;
				float noise3 = tex2Dlod(_NoiseTex3, float4((pos + (float2(_Wave3Direction.x * _Time.x, _Wave3Direction.y * _Time.x) * _Wave3Speed)) * _NoiseTex3_ST.xy, 0, 0)).r * _Wave3Weight;

				float totalWeight = _Wave1Weight + _Wave2Weight + _Wave3Weight;
				float totalNoise = (noise1 + noise2 + noise3) / totalWeight;

				return totalNoise;
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.interpolatedRay = v.ray;
				o.screenPos = ComputeScreenPos(o.vertex);
				o.ray.xyz = mul(UNITY_MATRIX_MV, v.vertex).xyz * float3(-1.0, -1.0, 1.0);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				//Decode depth and normal from depthnormal texture
				float4 depthNormal = tex2D(_CameraDepthNormalsTexture, i.uv);
				float3 normal;
				float depth;
				DecodeDepthNormal(depthNormal, depth, normal);
				normal = normalize(mul((float3x3)_viewToWorld, normal));

				//Get world position
				float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv));
				float linearDepth = Linear01Depth(rawDepth);
				float4 wsDir = linearDepth * i.interpolatedRay;
				float3 wsPos = _WorldSpaceCameraPos + wsDir;

				//Plane collision
				float3 rayDir = _WorldSpaceLightPos0.xyz;
				float3 diffVec = _planePosition.xyz - wsPos.xyz;
				float3 collisionPoint = wsPos + (rayDir * diffVec.y);
				float xCollision = step(abs(_planePosition.x - collisionPoint.x), _planeExtents.x);
				float zCollision = step(abs(_planePosition.z - collisionPoint.z), _planeExtents.y);
				float collision = xCollision * zCollision;

				//Y collision thing
				float yOffset = VertexDisplacement(wsPos.xz) * _WaveHeight;
				float yCollision = step(wsPos.y, _planePosition.y + yOffset);

				//Dot product "shadow"
				float inShadow = clamp(dot(normal, rayDir), 0, 1);

				//Refraction distortion
				float4 v0 = float4(collisionPoint, 1);
				float4 v1 = v0 + float4(_VectorLength, 0.0, 0.0, 0.0);
				float4 v2 = v0 + float4(0.0, 0.0, _VectorLength, 0.0);
				v0.y += VertexDisplacement(v0.xz) * _WaveHeight;
				v1.y += VertexDisplacement(v1.xz) * _WaveHeight;
				v2.y += VertexDisplacement(v2.xz) * _WaveHeight;
				float3 waveNormal = normalize(cross(v2.xyz - v0.xyz, v1.xyz - v0.xyz));

				//Combine everything
				float fallOff = 1 - clamp(((abs(wsPos.y - (_planePosition.y + yOffset))) / _CausticsFallOffDist), 0, 1);
				float occlusion = collision * inShadow * yCollision;
				float caustics = smoothstep(1 - _CausticAmount, 1, VertexDisplacement(collisionPoint.xz + waveNormal.xz * _CausticsStrength));

				fixed4 col = tex2D(_MainTex, i.uv);
				return lerp(col, _CausticsColor, caustics * occlusion * fallOff);
            }
            ENDCG
        }
    }
}
