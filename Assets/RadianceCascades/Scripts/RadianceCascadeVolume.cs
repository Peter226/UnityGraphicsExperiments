using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using static UnityEditor.Rendering.ShadowCascadeGUI;


public class RadianceCascadeVolume : MonoBehaviour
{
    public static IEnumerable<RadianceCascadeVolume> Volumes => _volumes;
    private static HashSet<RadianceCascadeVolume> _volumes = new HashSet<RadianceCascadeVolume>();

    [SerializeField] private float _volumeSize = 128.0f;

    private RadianceCascadeData _cascadeDataA;
    private RadianceCascadeData _cascadeDataB;

    public RadianceCascadeData CurrentCascade => _cascadeDataA;
    public RadianceCascadeData LastCascade => _cascadeDataB;

    private void OnEnable()
    {
        _cascadeDataA = new RadianceCascadeData();
        _cascadeDataB = new RadianceCascadeData();

        _cascadeDataA.Allocate();
        _cascadeDataB.Allocate();

        _cascadeDataA.position = transform.position;
        _cascadeDataB.position = transform.position;
        _cascadeDataA.size = _volumeSize;
        _cascadeDataB.size = _volumeSize;

        _volumes.Add(this);
    }

    private void Update()
    {
        var a = _cascadeDataA;
        _cascadeDataA = _cascadeDataB;
        _cascadeDataB = a;
        _cascadeDataA.position = transform.position;

        _cascadeDataA.position = transform.position;
        _cascadeDataA.size = _volumeSize;

        Shader.SetGlobalTexture(_cascadeDataB.emissionReadID, _cascadeDataB.emissionCascade);
        Shader.SetGlobalTexture(_cascadeDataB.transmittanceReadID, _cascadeDataB.transmittanceCascade);

        Shader.SetGlobalVector("_Cascade_Read_PositionWS", _cascadeDataB.position);
        Shader.SetGlobalVector("_Cascade_Write_PositionWS", _cascadeDataA.position);

        Shader.SetGlobalFloat("_Cascade_Read_Size", _cascadeDataB.size);
        Shader.SetGlobalFloat("_Cascade_Write_Size", _cascadeDataA.size);

        Shader.SetGlobalFloat("_Cascade_Read_SizeInverse", 1.0f / _cascadeDataB.size);
        Shader.SetGlobalFloat("_Cascade_Write_SizeInverse", 1.0f / _cascadeDataA.size);
    }

    private void OnDisable()
    {
        _volumes.Remove(this);
        _cascadeDataA.Dispose();
        _cascadeDataB.Dispose();
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.yellowNice;
        Gizmos.DrawWireCube(transform.position, Vector3.one * _volumeSize);
    }
}
