Shader "Unlit/BillboardFont" {
    Properties {
        _MainTex ("Font Texture", 2D) = "white" {}
        _Color ("Text Color", Color) = (1,1,1,1)
    }

    SubShader {
    Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True" }
        
        Lighting Off Cull back ZTest LEqual ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ UNITY_SINGLE_PASS_STEREO STEREO_INSTANCING_ON STEREO_MULTIVIEW_ON
            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform fixed4 _Color;

            v2f vert (appdata_t v)
            {
                v2f o;
                
                float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));

                #if defined(USING_STEREO_MATRICES)
                    float3 cameraPos = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * .5;
                #else
                    float3 cameraPos = _WorldSpaceCameraPos;
                #endif

                float dist = distance(objPos.xyz, cameraPos)*0.002;
                v.vertex *= dist;
                
                float3 scale = float3(length(mul(unity_ObjectToWorld, float4(1, 0, 0, 0)).xyz), length(mul(unity_ObjectToWorld, float4(0, 1, 0, 0)).xyz), length(mul(unity_ObjectToWorld, float4(0, 0, 1, 0)).xyz));
                
                float3 direction = normalize(cameraPos - objPos.xyz);

                float4x4 billboardMatrix = 0;
                billboardMatrix._m02 = direction.x;
                billboardMatrix._m12 = direction.y;
                billboardMatrix._m22 = direction.z;
                float3 xAxis = normalize(float3(-direction.z, 0, direction.x));
                billboardMatrix._m00 = xAxis.x;
                billboardMatrix._m10 = 0;
                billboardMatrix._m20 = xAxis.z;
                float3 yAxis = normalize(cross(xAxis, direction));
                billboardMatrix._m01 = yAxis.x;
                billboardMatrix._m11 = yAxis.y;
                billboardMatrix._m21 = yAxis.z;
                
                o.vertex = mul(UNITY_MATRIX_VP, mul(billboardMatrix, v.vertex * float4(scale, 0)) + objPos);

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.color = v.color * _Color;
                o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = i.color;
                col.a *= tex2D(_MainTex, i.texcoord).a;
                return col;
            }
            ENDCG
        }
    }
}
