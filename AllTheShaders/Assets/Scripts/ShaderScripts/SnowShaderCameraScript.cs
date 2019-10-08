using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SnowShaderCameraScript : MonoBehaviour
{
    [SerializeField]
    private Material _TextureLogicMaterial;
    [SerializeField]
    private Material _SnowMaterial;

    private RenderTexture _tempTex;
    private Camera _camera;

    // Start is called before the first frame update
    void Start()
    {
        _camera = GetComponent<Camera>();
        _camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void Update()
    {
        if (!Application.isPlaying)
        {
            _SnowMaterial.SetFloat("_MaxDepth", _camera.farClipPlane);
            transform.localPosition = new Vector3(0, 0, 0);
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(!_tempTex)
            _tempTex = new RenderTexture(1024, 1024, 0);
        RenderTexture.active = _camera.targetTexture;
        Graphics.Blit(RenderTexture.active, _tempTex);
        RenderTexture.active = null;

        _TextureLogicMaterial.SetTexture("_OldTex", _tempTex);
        Graphics.Blit(source, destination, _TextureLogicMaterial);
    }
}
