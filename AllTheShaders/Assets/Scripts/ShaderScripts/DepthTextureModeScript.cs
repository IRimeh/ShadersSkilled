using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DepthTextureModeScript : MonoBehaviour
{
    [SerializeField]
    private bool Depth = true;
    [SerializeField]
    private bool DepthNormals = false;
    [SerializeField]
    private bool MotionVectors = false;

    private void OnEnable()
    {
        if(Depth)
            Camera.main.depthTextureMode = DepthTextureMode.Depth;
        if (DepthNormals)
            Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
        if (MotionVectors)
            Camera.main.depthTextureMode = DepthTextureMode.MotionVectors;
    }
}
