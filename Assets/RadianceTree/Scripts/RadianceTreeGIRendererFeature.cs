using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;


public sealed class RadianceTreeGIRendererFeature : ScriptableRendererFeature
{
    
    private VoxelizeSceneTreeRenderPass _voxelizePass;
    private DebugVoxelizedSceneTreePass _debugVoxelizedPass;

    public override void Create()
    {
       _voxelizePass = new VoxelizeSceneTreeRenderPass();
        _debugVoxelizedPass = new DebugVoxelizedSceneTreePass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Preview || renderingData.cameraData.cameraType == CameraType.Reflection)
            return;
        RadianceTreeGIVolumeComponent myVolume = VolumeManager.instance.stack?.GetComponent<RadianceTreeGIVolumeComponent>();
        if (myVolume == null || !myVolume.IsActive())
            return;

        if (renderingData.cameraData.cameraType != CameraType.SceneView) {
            _voxelizePass.renderPassEvent = RenderPassEvent.BeforeRendering;
            _voxelizePass.ConfigureInput(ScriptableRenderPassInput.None);
            renderer.EnqueuePass(_voxelizePass);
        }
        _debugVoxelizedPass.ConfigureInput(ScriptableRenderPassInput.None);
        _debugVoxelizedPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        renderer.EnqueuePass(_debugVoxelizedPass);
    }

    protected override void Dispose(bool disposing)
    {
        
    }
}
