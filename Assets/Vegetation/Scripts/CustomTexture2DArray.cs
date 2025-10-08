using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[CreateAssetMenu(fileName = nameof(CustomTexture2DArray), menuName = "Peter/" + nameof(CustomTexture2DArray), order = 0)]
public class CustomTexture2DArray : ScriptableObject
{
    public IEnumerable<Texture> Textures => _textures;
    [SerializeField] private List<Texture> _textures = new List<Texture>();

    public Texture2DArray TextureArray { get { return _textureArray; } set { _textureArray = value; } }
    [SerializeField][HideInInspector] private Texture2DArray _textureArray;

}
