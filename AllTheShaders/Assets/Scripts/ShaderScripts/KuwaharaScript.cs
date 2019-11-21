using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class KuwaharaScript : MonoBehaviour
{
    [SerializeField]
    private Material material;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material)
            Graphics.Blit(source, destination, material);
    }
}
