using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RendererUtils;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class VoxelizeSceneRenderPass : ScriptableRenderPass
{

    static void ExecutePass(VoxelizedSceneData data, RasterGraphContext context)
    {
        var cmd = context.cmd;
        
        var bounds = new Bounds(data.writeCascade.position, Vector3.one * data.writeCascade.size);
        var extendedBounds = bounds;
        //extendedBounds.size *= 1.5f;
        var extendedExtents = extendedBounds.extents;
        var projection = Matrix4x4.Ortho(-extendedExtents.x, extendedExtents.x, -extendedExtents.y, extendedExtents.y, 0, extendedExtents.z * 2.0f);
        cmd.SetViewProjectionMatrices(Matrix4x4.TRS(data.writeCascade.position + Vector3.forward * extendedExtents.z, Quaternion.identity,Vector3.one).inverse, projection);
        cmd.SetViewport(new Rect(0, 0, 256, 256));
        cmd.DrawRendererList(data.rendererListHandle);
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (RadianceCascadeVolume.Volumes.Count() <= 0) return;
        var radianceCascadeVolume = RadianceCascadeVolume.Volumes.First();


        var emissionImportParams = new ImportResourceParams()
        {
            clearColor = Color.clear,
            clearOnFirstUse = true,
            discardOnLastUse = false,
        };

        var transmissionImportParams = new ImportResourceParams()
        {
            clearColor = new Color(1,1,1, 4096),
            clearOnFirstUse = true,
            discardOnLastUse = false,
        };

        var lastCascade = radianceCascadeVolume.LastCascade;
        var currentCascade = radianceCascadeVolume.CurrentCascade;

        using (var builder = renderGraph.AddRasterRenderPass<VoxelizedSceneData>(passName, out var passData))
        {
            passData.readCascade = lastCascade;
            passData.writeCascade = currentCascade;

            var cameraData = frameData.Get<UniversalCameraData>();


            var cullContextData = frameData.Get<CullContextData>();

            cameraData.camera.TryGetCullingParameters(false, out var cullingParameters);

            var cullingResults = cullContextData.Cull(ref cullingParameters);
            var rendererListDescriptor = new RendererListDesc(new ShaderTagId("RadianceCascadeWrite"), cullingResults, cameraData.camera);
            rendererListDescriptor.renderQueueRange = RenderQueueRange.opaque;
            var rendererList = renderGraph.CreateRendererList(rendererListDescriptor);

            passData.rendererListHandle = rendererList;

            if (!passData.rendererListHandle.IsValid())
                return;

            builder.UseRendererList(passData.rendererListHandle);
            
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            var dummyTarget = renderGraph.CreateTexture(new TextureDesc(256, 256) { name = "_Dummy" , colorFormat = GraphicsFormat.R8G8B8A8_SRGB, enableRandomWrite = false});
            builder.SetRenderAttachment(dummyTarget, 0);

            
            var emissionTexture = renderGraph.ImportTexture(currentCascade.emissionCascade, emissionImportParams);
            builder.SetRandomAccessAttachment(emissionTexture, currentCascade.emissionWriteID, AccessFlags.ReadWrite);
            builder.SetGlobalTextureAfterPass(emissionTexture, currentCascade.emissionReadID);

            var transmittanceTexture = renderGraph.ImportTexture(currentCascade.transmittanceCascade, transmissionImportParams);
            builder.SetRandomAccessAttachment(transmittanceTexture, currentCascade.transmittanceWriteID, AccessFlags.ReadWrite);
            builder.SetGlobalTextureAfterPass(transmittanceTexture, currentCascade.transmittanceReadID);

            builder.SetRenderFunc((VoxelizedSceneData data, RasterGraphContext context) => ExecutePass(data, context));
        }
    }

    public class VoxelizedSceneData
    {
        public CascadeDescriptor cascadeDescriptor;
        public RendererListHandle rendererListHandle;
        public RadianceCascadeData writeCascade;
        public RadianceCascadeData readCascade;
    }
}
