Shader "Custom/RadianceTreeLit"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [HDR]_EmissionColor("Emission", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "white" {}
        _EmissionIntensity("Emission Intensity", Float) = 1.0
    }

    SubShader
    {

        Pass
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./RadianceTreeLighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : POSITION1;
                float3 normalWS : NORMAL2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_EmissionMap);
            SAMPLER(sampler_EmissionMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            
                float4 _BaseMap_ST;

                half4 _EmissionColor;

                float _EmissionIntensity;

            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionHCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                half4 litColor = RadiancePBR(color, input.positionWS, input.normalWS) + color * 0.4;
                litColor.rgb += SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionColor * _EmissionIntensity;
                return litColor;
            }
            ENDHLSL
        }

        Pass
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "LightMode" = "RadianceTreeWrite" }

            

            Cull Off
            ColorMask 0
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
 
            #pragma target 5.0
            #pragma require geometry
            #pragma require randomwrite
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry Geometry

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./RadianceTreeGeneration.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Intermediates {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };


            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_EmissionMap);
            SAMPLER(sampler_EmissionMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;

                float4 _BaseMap_ST;

                half4 _EmissionColor;
                float _EmissionIntensity;

            CBUFFER_END

            Intermediates vert(Attributes input)
            {
                Intermediates output;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionWS = vertexInput.positionWS;

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            [maxvertexcount(9)]
            void Geometry(triangle Intermediates input[3], inout TriangleStream<Varyings> stream) {
                Varyings output;

                float3 A = input[0].positionWS;
                float3 B = input[1].positionWS;
                float3 C = input[2].positionWS;

                float3 faceNormal = abs(normalize(cross(A - B, B - C)));
                [unroll] for (int i = 0; i < 3; i++)
                {
                    Intermediates inputVertex = input[i];
                    output.uv = inputVertex.uv;
                    output.positionWS = inputVertex.positionWS;
                    output.normalWS = inputVertex.normalWS;
                    float3 transformedPosition = inputVertex.positionWS;
                    transformedPosition -= _Tree_Write_PositionWS;

                    transformedPosition = faceNormal.y > faceNormal.z ? transformedPosition.xzy : transformedPosition;
                    transformedPosition = faceNormal.x > faceNormal.y ? transformedPosition.zyx : transformedPosition;

                    transformedPosition += _Tree_Write_PositionWS;
                    output.positionHCS = TransformWorldToHClip(transformedPosition);
                    stream.Append(output);
                }
                stream.RestartStrip();
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                half4 litColor = RadiancePBR(color, input.positionWS, input.normalWS);
                litColor.rgb *= 0.1;
                litColor.rgb += SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionColor * _EmissionIntensity;

                float3 positionWS = input.positionWS;
                WriteTransmittance(float3(1,1,1) * (1.0 - litColor.a), positionWS);
                WriteEmission(litColor.rgb, positionWS, 0);

                return litColor;
            }
            ENDHLSL
        }
    }
}
