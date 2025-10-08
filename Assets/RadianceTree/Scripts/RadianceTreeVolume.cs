using System.Collections;
using System.Collections.Generic;
using TreeEditor;
using UnityEngine;


public class RadianceTreeVolume : MonoBehaviour
{
    public static IEnumerable<RadianceTreeVolume> Volumes => _volumes;
    private static HashSet<RadianceTreeVolume> _volumes = new HashSet<RadianceTreeVolume>();

    [SerializeField] private float _volumeSize = 128.0f;
    [SerializeField] private int _expectedTreeSize = 1000000;
    [SerializeField] private int _expectedCubemapTreeSize = 2000000;
    [SerializeField] private Shader _treeDebugShader;

    private RadianceTreeData _treeDataA;
    private RadianceTreeData _treeDataB;

    public RadianceTreeData CurrentTree => _treeDataA;
    public RadianceTreeData LastTree => _treeDataB;

    private void OnEnable()
    {
        _treeDataA = new RadianceTreeData();
        _treeDataB = new RadianceTreeData();

        var treeDebugMaterial = new Material(_treeDebugShader);

        _treeDataA.treeDebugMaterial = treeDebugMaterial;
        _treeDataB.treeDebugMaterial = treeDebugMaterial;

        _treeDataA.Allocate(_expectedTreeSize, _expectedCubemapTreeSize);
        _treeDataB.Allocate(_expectedTreeSize, _expectedCubemapTreeSize);

        _treeDataA.position = transform.position;
        _treeDataB.position = transform.position;
        _treeDataA.size = _volumeSize;
        _treeDataB.size = _volumeSize;

        _treeDataA.ClearBuffers();
        _treeDataB.ClearBuffers();

        _volumes.Add(this);
    }


    private void Update()
    {
        var a = _treeDataA;
        _treeDataA = _treeDataB;
        _treeDataB = a;
        _treeDataA.position = transform.position;

        _treeDataA.position = transform.position;
        _treeDataA.size = _volumeSize;

        Shader.SetGlobalVector("_Tree_Read_PositionWS", _treeDataB.position);
        Shader.SetGlobalVector("_Tree_Write_PositionWS", _treeDataA.position);

        Shader.SetGlobalFloat("_Tree_Read_Size", _treeDataB.size);
        Shader.SetGlobalFloat("_Tree_Write_Size", _treeDataA.size);

        Shader.SetGlobalFloat("_Tree_Read_SizeInverse", 1.0f / _treeDataB.size);
        Shader.SetGlobalFloat("_Tree_Write_SizeInverse", 1.0f / _treeDataA.size);

        Shader.SetGlobalBuffer("_Tree_Read_Emission", _treeDataB.emissionTreeBuffer);
        Shader.SetGlobalBuffer("_Tree_Read_Emission_Cubemap", _treeDataB.emissionCubemapTreeBuffer);
        Shader.SetGlobalBuffer("_Tree_Read_Transmittance", _treeDataB.transmittanceTreeBuffer);
    }

    private void OnDisable()
    {
        _volumes.Remove(this);
        _treeDataA.Dispose();
        _treeDataB.Dispose();
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.yellowNice;
        Gizmos.DrawWireCube(transform.position, Vector3.one * _volumeSize);
    }
}
