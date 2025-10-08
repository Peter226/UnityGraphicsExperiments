using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static VoxelizeSceneTreeRenderPass;

public class DebugVoxelizedSceneTreePass : ScriptableRenderPass
{

    static void ExecutePass(DebugVoxelizedTreeSceneData data, RasterGraphContext context)
    {
        data.tree.GetCounters(out int emissionCounter, out int emissionCubemapCounter, out int transmittanceCounter);
        var cmd = context.cmd;
        transmittanceCounter = Mathf.Min(transmittanceCounter, 1000000);
        cmd.DrawProcedural(Matrix4x4.identity, data.tree.treeDebugMaterial, 0, MeshTopology.Points, transmittanceCounter);
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        var treeVolume = RadianceTreeVolume.Volumes.FirstOrDefault();
        if (treeVolume == null) return;

        var cameraData = frameData.Get<UniversalCameraData>();
        var resourceData = frameData.Get<UniversalResourceData>();

        using (var builder = renderGraph.AddRasterRenderPass<DebugVoxelizedTreeSceneData>(passName, out var passData))
        {
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0);
            builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture);
            passData.tree = treeVolume.LastTree;
            builder.SetRenderFunc((DebugVoxelizedTreeSceneData data, RasterGraphContext context) => ExecutePass(data, context));
        }
    }
    public class DebugVoxelizedTreeSceneData
    {
        public RadianceTreeData tree;
    }
}
