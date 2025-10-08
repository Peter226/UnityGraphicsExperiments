Shader "Custom/RadianceTreeLitDebugger"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Pass
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "LightMode" = "RadianceTreeDebug" }

            

            Cull Off
            //ColorMask 0
            //ZWrite Off
            //ZTest Always
            //Blend One One

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
                uint vertexID : SV_VertexID;
            };

            struct Intermediates {
                float3 positionWS : TEXCOORD0;
                float3 sizeWS : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 color : COLOR0;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END

            Intermediates vert(Attributes input)
            {
                Intermediates output;
                TransmittanceTreeNode transmittanceNode = _Tree_Read_Transmittance[input.vertexID];
                float3 nodePosition = transmittanceNode.nodePosition;
                nodePosition -= 0.5;
                nodePosition *= _Tree_Read_Size;
                nodePosition += _Tree_Read_PositionWS;
                int nodeDepth = transmittanceNode.treeDepth;
                float nodeSize = 1.0 / pow(2, nodeDepth) * _Tree_Read_Size;
                output.positionWS = nodePosition;
                output.sizeWS = transmittanceNode.parentIndex >= 0 ? nodeSize : -1;
                return output;
            }

            [maxvertexcount(36)]
            void Geometry(point Intermediates input[1], inout LineStream<Varyings> stream) {

                Intermediates vertexData = input[0];
                if (vertexData.sizeWS.x < 0) return;
                float3 mn = vertexData.positionWS - vertexData.sizeWS * 0.5;
                float3 mx = vertexData.positionWS + vertexData.sizeWS * 0.5;

                float3 color = 0.5 / vertexData.sizeWS;

                float3 verts[8] = {
                    float3(mn.x, mn.y, mn.z),
                    float3(mx.x, mn.y, mn.z),
                    float3(mx.x, mx.y, mn.z),
                    float3(mn.x, mx.y, mn.z),
                    float3(mn.x, mn.y, mx.z),
                    float3(mx.x, mn.y, mx.z),
                    float3(mx.x, mx.y, mx.z),
                    float3(mn.x, mx.y, mx.z),
                };

                int edgePairs[24] = {
                    0,1, 1,2, 2,3, 3,0, // back rectangle
                    4,5, 5,6, 6,7, 7,4, // front rectangle
                    0,4, 1,5, 2,6, 3,7  // connecting edges
                };

                for (int i = 0; i < 24; i += 2)
                {
                    Varyings outputA;
                    Varyings outputB;

                    outputA.positionHCS = TransformWorldToHClip(float4(verts[edgePairs[i + 0]], 1.0));
                    outputB.positionHCS = TransformWorldToHClip(float4(verts[edgePairs[i + 1]], 1.0));

                    outputA.color = color;
                    outputB.color = color;

                    stream.Append(outputA);
                    stream.Append(outputB);

                    stream.RestartStrip();
                }

            }
            
            half4 frag(Varyings input) : SV_Target
            {
               return half4(1 * input.color.r,0,0,1);
            }
            ENDHLSL
        }
    }
}
