using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[CustomEditor(typeof(CustomTexture2DArray))]
public class CustomTexture2DArrayEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        var customArray = target as CustomTexture2DArray;
        var validationMessage = CheckValidity(customArray);
        bool isValid = validationMessage == string.Empty;
        EditorGUI.BeginDisabledGroup(!isValid);
        if (GUILayout.Button("Apply"))
        {
            Apply(customArray);
        }
        EditorGUI.EndDisabledGroup();
        if (!isValid)
        {
            GUILayout.Label(validationMessage);
        }
    }

    private string CheckValidity(CustomTexture2DArray customArray)
    {
        if(customArray.Textures.Count() <= 0) return "No source textures added, cannot apply.";
        var firstTexture = customArray.Textures.First();
        if (firstTexture == null) return "A texture asset is missing from the list, cannot apply.";
        int width = firstTexture.width;
        int height = firstTexture.height;
        var format = firstTexture.graphicsFormat;
        var mipmapCount = firstTexture.mipmapCount;
        foreach (var texture in customArray.Textures)
        {
            if (texture == null) return "A texture asset is missing from the list, cannot apply.";
            if (texture.width != width || texture.height != height)
            {
                return "All textures must be the same resolution, cannot apply.";
            }
            if (format != texture.graphicsFormat)
            {
                return "All textures must be the same format, cannot apply.";
            }
            if (texture.mipmapCount != mipmapCount)
            {
                return "All textures must have the same mipmap count, cannot apply.";
            }
        }
        return string.Empty;
    }

    private void Apply(CustomTexture2DArray customArray)
    {
        var firstTexture = customArray.Textures.First();
        var lastTextureArray = customArray.TextureArray;
        if (lastTextureArray != null && (lastTextureArray.mipmapCount != firstTexture.mipmapCount || lastTextureArray.width != firstTexture.width || lastTextureArray.height != firstTexture.height || lastTextureArray.graphicsFormat != firstTexture.graphicsFormat || lastTextureArray.depth != customArray.Textures.Count()))
        {
            AssetDatabase.RemoveObjectFromAsset(customArray.TextureArray);
            if(customArray.TextureArray != null) DestroyImmediate(customArray.TextureArray);
            customArray.TextureArray = null;
        }
        bool justCreated = false;
        if (customArray.TextureArray == null)
        {
            customArray.TextureArray = new Texture2DArray(firstTexture.width, firstTexture.height, customArray.Textures.Count(), firstTexture.graphicsFormat, TextureCreationFlags.MipChain, firstTexture.mipmapCount);
            customArray.TextureArray.name = customArray.name + "Data";
            justCreated = true;
        }
        var textureArray = customArray.TextureArray;
        var index = 0;
        foreach (var texture in customArray.Textures)
        {
            for (int m = 0;m < texture.mipmapCount;m++)
            {
                Graphics.CopyTexture(texture, 0, m, textureArray, index, m);
            }
            index++;
        }
        textureArray.Apply(false, false);

        if (justCreated) AssetDatabase.AddObjectToAsset(customArray.TextureArray, customArray);
        AssetDatabase.SaveAssets();
    }
}
