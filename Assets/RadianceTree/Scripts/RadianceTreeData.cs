using System;
using System.Collections.Generic;
using System.Drawing;
using System.Runtime.InteropServices;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;

public class RadianceTreeData : IDisposable
{
    public Vector3 position;
    public float size;

    public int treeNodeCounterReadID;
    public int emissionReadID;
    public int emissionCubemapReadID;
    public int transmittanceReadID;

    public int treeNodeCounterWriteID = 1;
    public int emissionWriteID = 2;
    public int emissionCubemapWriteID = 3;
    public int transmittanceWriteID = 4;

    public GraphicsBuffer treeCounterBuffer;
    public GraphicsBuffer emissionTreeBuffer;
    public GraphicsBuffer emissionCubemapTreeBuffer;
    public GraphicsBuffer transmittanceTreeBuffer;

    public Material treeDebugMaterial;


    private List<TransmittanceTreeNode> _transmittanceClearData = new List<TransmittanceTreeNode>();

    public void Allocate(int expectedTreeSize, int expectedCubemapTreeSize)
    {
        treeNodeCounterReadID = Shader.PropertyToID("_Tree_Read_Node_Counter");
        emissionReadID = Shader.PropertyToID("_Tree_Read_Emission");
        emissionCubemapReadID = Shader.PropertyToID("_Tree_Read_Emission_Cubemap");
        transmittanceReadID = Shader.PropertyToID("_Tree_Read_Transmittance");

        emissionTreeBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, expectedTreeSize, Marshal.SizeOf(typeof(EmissionTreeNode)));
        emissionCubemapTreeBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, expectedCubemapTreeSize, Marshal.SizeOf(typeof(EmissionCubemapTreeNode)));
        transmittanceTreeBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, expectedTreeSize, Marshal.SizeOf(typeof(TransmittanceTreeNode)));
        treeCounterBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, 1, Marshal.SizeOf(typeof(TreeNodeCounter)));

        for (int i = 0;i < expectedTreeSize;i++) _transmittanceClearData.Add(new TransmittanceTreeNode()
        {
            parentIndex = -1,
            transmittance = float4.zero,
            childrenStartIndex = -1,
            treeDepth = 0,
            nodePosition = new float3(0.5f, 0.5f, 0.5f),
        });
    }

    public void ClearBuffers()
    {
        treeCounterBuffer.SetData(new List<TreeNodeCounter>() { new TreeNodeCounter() {
            counterEmission = 1,
            counterCubemapEmission = 1,
            counterTransmittance = 1,
        } });
        transmittanceTreeBuffer.SetData(_transmittanceClearData);
    }

    public void GetCounters(out int emissionCounter, out int emissionCubemapCounter, out int transmittanceCounter)
    {
        var counterArray = new TreeNodeCounter[1];
        treeCounterBuffer.GetData(counterArray);
        var counter = counterArray[0];
        emissionCounter = counter.counterEmission;
        emissionCubemapCounter = counter.counterCubemapEmission;
        transmittanceCounter = counter.counterTransmittance;
    }

    public void Dispose()
    {
        treeCounterBuffer.Release();
        emissionTreeBuffer.Release();
        emissionCubemapTreeBuffer.Release();
        transmittanceTreeBuffer.Release();
    }

    [StructLayout(LayoutKind.Sequential)]
    struct EmissionTreeNode
    {
        public int parentIndex;
        public int childrenStartIndex;
        public int treeDepth;
        public float3 nodePosition;

        public int cubemapIndex;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct EmissionCubemapTreeNode
    {
        public int parentIndex;
        public int childrenStartIndex;
        public int treeDepth;
        public float3 nodePosition;

        public float3 emission;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct TransmittanceTreeNode
    {
        public int parentIndex;
        public int childrenStartIndex;
        public int treeDepth;
        public float3 nodePosition;

        public float4 transmittance;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct TreeNodeCounter
    {
        public int counterEmission;
        public int counterCubemapEmission;
        public int counterTransmittance;
    }

}
