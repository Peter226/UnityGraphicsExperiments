Shader "Custom/Leaves"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset] [MainTexture] _BaseMap("Base Map", 2DArray) = "white" {}
        [NoScaleOffset] _NormalMap("Normal Map", 2DArray) = "white" {}
        [NoScaleOffset] _HeightMap("Height Map", 2DArray) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            AlphaToMask On

            HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D_ARRAY(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D_ARRAY(_NormalMap);
            SAMPLER(sampler_NormalMap);

            TEXTURE2D_ARRAY(_HeightMap);
            SAMPLER(sampler_HeightMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END

            Varyings Vertex(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 Fragment(Varyings IN) : SV_Target
            {
                float3 cameraPositionWS = _WorldSpaceCameraPos;
                half4 color = SAMPLE_TEXTURE2D_ARRAY(_BaseMap, sampler_BaseMap, IN.uv.xy, 0) * _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
