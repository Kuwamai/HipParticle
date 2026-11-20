Shader "Custom/HipParticle"
{
    Properties
    {
        [HDR] _Pos ("Pos", 2D) = "white" {}
        [HDR] _Col ("Col", 2D) = "white" {}
        [HDR] _Mag ("Mag", 2D) = "white" {}

        [Header(Star Size)]
        _Mag_param ("Star size: 星のサイズ", Range(0, 250)) = 100
        _Mag_min ("Minimum star size: 星の最小サイズ", Range(0, 1)) = 0.025
        _MinimumAngularRadius ("Minimum star angular radius: 星の見かけの最小サイズ", Range(0.01, 2)) = 0.12

        [Header(Star Brightness)]
        _GlowIntensity ("Glow intensity: 星の光量に掛ける倍率", Range(0, 100)) = 1.8
        _BrightnessPower ("Brightness response: 星の明暗の強弱", Range(0.1, 3)) = 0.35

        [Header(Star Color)]
        _Saturation ("Saturation: 鮮やかさ", Range(0, 1)) = 0.7

        [Header(Light Shape)]
        _GlowFalloff ("Glow falloff: 光の広がりの減衰具合", Range(4, 100)) = 12
        _CoreBoost ("Core boost: 星の中心の明るい部分のサイズ", Range(0, 100)) = 1.25
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent+1" }
        Blend One One
        ZWrite Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 color : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _Pos;
            float4 _Pos_HDR;
            float4 _Pos_TexelSize;
            sampler2D _Col;
            float4 _Col_HDR;
            sampler2D _Mag;
            float4 _Mag_HDR;
            float _Mag_param;
            float _Mag_min;
            float _GlowIntensity;
            float _GlowFalloff;
            float _CoreBoost;
            float _MinimumAngularRadius;
            float _BrightnessPower;
            float _Saturation;
            
            // 位置データのビット列を復元する
            float3 ReadStarPosition(float2 uv) {
                float texWidth = _Pos_TexelSize.z;
                float2 e = float2(-1.0/texWidth/2, 1.0/texWidth/2);
                uint3 v0 = uint3(DecodeHDR(tex2Dlod(_Pos, float4(uv + e.xy,0,0)), _Pos_HDR).xyz * 255.) << 0;
                uint3 v1 = uint3(DecodeHDR(tex2Dlod(_Pos, float4(uv + e.yy,0,0)), _Pos_HDR).xyz * 255.) << 8;
                uint3 v2 = uint3(DecodeHDR(tex2Dlod(_Pos, float4(uv + e.xx,0,0)), _Pos_HDR).xyz * 255.) << 16;
                uint3 v3 = uint3(DecodeHDR(tex2Dlod(_Pos, float4(uv + e.yx,0,0)), _Pos_HDR).xyz * 255.) << 24;
                uint3 v = v0 + v1 + v2 + v3;
                return asfloat(v);
            }
            
            // RGBに分けて保存された明るさを、0以上1未満の値へ復元する
            float ReadStarBrightness(float2 uv) {
                float3 bytes = DecodeHDR(tex2Dlod(_Mag, float4(uv, 0, 0)), _Mag_HDR).rgb * 255.0;
                return dot(bytes, float3(65536.0, 256.0, 1.0)) / 16777216.0;
            }
            
            float3 ComputeAlignAxisX() 
            {
#if defined(USING_STEREO_MATRICES)
                return normalize(unity_StereoCameraToWorld[0]._m00_m10_m20 + unity_StereoCameraToWorld[1]._m00_m10_m20);
#else
                return unity_CameraToWorld._m00_m10_m20;
#endif
            }
            float3 ComputeAlignAxisY()
            {
#if defined(USING_STEREO_MATRICES)
                return normalize(unity_StereoCameraToWorld[0]._m01_m11_m21 + unity_StereoCameraToWorld[1]._m01_m11_m21);
#else
                return unity_CameraToWorld._m01_m11_m21;
#endif
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                // メッシュのXYから星データのUVを取得する。
                float2 dataUV = v.vertex.xy;

                float3 starPosition = ReadStarPosition(dataUV).xzy;
                float3 starColor = DecodeHDR(tex2Dlod(_Col, float4(dataUV, 0, 0)), _Col_HDR).rgb;
                float catalogBrightness = ReadStarBrightness(dataUV);
                float3 worldPos = mul(unity_ObjectToWorld, float4(starPosition, 1));

                // 光量を色に反映させる
                float starIntensity = pow(max(catalogBrightness, 0.000001), _BrightnessPower) * _GlowIntensity;
                // 明るさを保ちながら彩度を下げる。
                float luminance = dot(starColor, float3(0.2126, 0.7152, 0.0722));
                float3 displayColor = lerp(luminance.xxx, starColor, saturate(_Saturation));
                o.color = displayColor * starIntensity;

                // サイズには元の星表データを使い、光量の設定とは分ける。
                float starSize = catalogBrightness * _Mag_param + _Mag_min;
                starSize *= pow(determinant((float3x3)UNITY_MATRIX_M), 1 / 3.0);
                if(length(starColor) < 0.1 && length(starPosition) < 0.1) starSize = 0;

                float3 xAxis = ComputeAlignAxisX();
                float3 yAxis = ComputeAlignAxisY();
                float3x2 triVert = float3x2(
                    float2(0, 1),
                    float2(-0.9, -0.5),
                    float2(0.9, -0.5));

                // メッシュのZから三角形の頂点番号を取得する。
                o.uv = triVert[(int)v.vertex.z];

                // 星の見かけの大きさを計算し、最小値以下の星を大きくする
                float distanceToStar = max(distance(worldPos, _WorldSpaceCameraPos), 0.0001);
                float minimumRadius = distanceToStar * tan(radians(_MinimumAngularRadius));
                float renderedSize = starSize > 0.0 ? max(starSize, minimumRadius * 2.0) : 0.0;

                float2 offset = o.uv * renderedSize;
                o.vertex = UnityWorldToClipPos(worldPos + xAxis * offset.x + yAxis * offset.y);
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                float radiusSq = dot(i.uv, i.uv);
                // 円形に光を広げ、縁をぼかしてちらつきを抑える
                float edgeWidth = max(fwidth(radiusSq), 0.0001);
                half coverage = 1.0 - smoothstep(0.25 - edgeWidth, 0.25 + edgeWidth, radiusSq);
                clip(coverage - (1.0 / 255.0));

                // 中心から離れるほど光を弱め、中心付近をさらに明るくする。
                half halo = exp2(-radiusSq * _GlowFalloff);
                half core = exp2(-radiusSq * _GlowFalloff * 8.0);
                half lightProfile = halo + core * _CoreBoost;
                half3 emission = i.color * lightProfile * coverage;
                return half4(emission, 0.0);
            }
            ENDCG
        }
    }
}
