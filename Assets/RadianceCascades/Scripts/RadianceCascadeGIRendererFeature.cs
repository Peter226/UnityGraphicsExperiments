using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;


public sealed class RadianceCascadeGIRendererFeature : ScriptableRendererFeature
{
    
    private VoxelizeSceneRenderPass _voxelizePass;

    public override void Create()
    {
       _voxelizePass = new VoxelizeSceneRenderPass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Preview || renderingData.cameraData.cameraType == CameraType.Reflection || renderingData.cameraData.cameraType == CameraType.SceneView)
            return;
        RadianceCascadeGIVolumeComponent myVolume = VolumeManager.instance.stack?.GetComponent<RadianceCascadeGIVolumeComponent>();
        if (myVolume == null || !myVolume.IsActive())
            return;

        _voxelizePass.renderPassEvent = RenderPassEvent.BeforeRendering;

        _voxelizePass.ConfigureInput(ScriptableRenderPassInput.None);
        renderer.EnqueuePass(_voxelizePass);
    }

    protected override void Dispose(bool disposing)
    {
        
    }
}
