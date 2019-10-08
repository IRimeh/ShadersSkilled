using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogOfWar : MonoBehaviour
{

    [SerializeField]
    private Camera _renderTexCamera;
    [SerializeField]
    private RenderTexture _renderTex;
    [SerializeField]
    private Material _mat;
    [SerializeField]
    private bool _showOld = false;

    private Renderer _renderer;

    // Start is called before the first frame update
    private void OnEnable()
    {
        _renderer = GetComponent<Renderer>();
    }


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        _mat.SetTexture("_RenderTex", _renderTex);
        if (_showOld)
            _mat.SetFloat("_ShowOld", 1);
        else
            _mat.SetFloat("_ShowOld", 0);
        _mat.SetVector("_RenderCameraPos", _renderTexCamera.transform.position);
        Graphics.Blit(source, destination, _mat);
    }
}
