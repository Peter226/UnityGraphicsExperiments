using System;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;

public class RadianceCascadeData : IDisposable
{
    public Vector3 position;
    public float size;

    public RTHandle emissionCascade;
    public RTHandle transmittanceCascade;
    public CascadeDescriptor[] cascadeDescriptors = new CascadeDescriptor[7];

    public int emissionReadID;
    public int transmittanceReadID;

    public int emissionWriteID = 1;
    public int transmittanceWriteID = 2;

    public void Allocate()
    {
        emissionReadID = Shader.PropertyToID("_Cascade_Read_Emission");
        transmittanceReadID = Shader.PropertyToID("_Cascade_Read_Transmittance");

        var emissionDescriptor = new RenderTextureDescriptor();
        emissionDescriptor.bindMS = false;
        emissionDescriptor.msaaSamples = 1;
        emissionDescriptor.colorFormat = RenderTextureFormat.RGB111110Float;
        emissionDescriptor.enableRandomWrite = true;
        emissionDescriptor.dimension = TextureDimension.Tex3D;

        int cascadeDepth = 0;
        for (int i = 0;i < 7;i++)
        {
            var descriptor = new CascadeDescriptor(i);
            
            cascadeDescriptors[i] = descriptor;

            emissionDescriptor.width = descriptor.targetTextureSize.x;
            emissionDescriptor.height = descriptor.targetTextureSize.y;
            cascadeDepth += descriptor.targetTextureSize.z;
        }
        emissionDescriptor.volumeDepth = cascadeDepth;

        var transmittanceDescriptor = emissionDescriptor;
        transmittanceDescriptor.colorFormat = RenderTextureFormat.ARGBHalf;

        emissionCascade = RTHandles.Alloc(emissionDescriptor, FilterMode.Bilinear);
        transmittanceCascade = RTHandles.Alloc(transmittanceDescriptor, FilterMode.Bilinear);
    }

    public void Dispose()
    {
        RTHandles.Release(emissionCascade);
        RTHandles.Release(transmittanceCascade);
    }
}
