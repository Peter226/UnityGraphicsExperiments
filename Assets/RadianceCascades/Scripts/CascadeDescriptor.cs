using Unity.Mathematics;
using UnityEngine;

[System.Serializable]
public struct CascadeDescriptor
{
    public CascadeDescriptor(int cascadeIndex)
    {
        cascadeResolution = 1 << cascadeIndex;
        probeCountPerAxis = ((1 << 6) / cascadeResolution);

        targetTextureSize = new int3()
        {
            x = 3 * cascadeResolution * probeCountPerAxis,
            y = 2 * cascadeResolution * probeCountPerAxis,
            z = probeCountPerAxis,
        };

        readPropertyID = Shader.PropertyToID($"_Cascade_Read_{cascadeIndex}");
        writePropertyID = cascadeIndex + 1;
    }

    public int cascadeResolution;
    public int probeCountPerAxis;

    public int3 targetTextureSize;

    public int readPropertyID;
    public int writePropertyID;
}
