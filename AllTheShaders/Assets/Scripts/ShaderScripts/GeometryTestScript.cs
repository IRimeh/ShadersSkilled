using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GeometryTestScript : MonoBehaviour
{
    private Renderer _renderer;
    private Material _mat;

    float _extrusionFactor = 0;
    float _scrollSpeed = 0.2f;

    private void OnEnable()
    {
        _renderer = GetComponent<Renderer>();
        _mat = _renderer.sharedMaterial;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.O) || Input.GetKey(KeyCode.P))
        {
            _extrusionFactor = Mathf.Lerp(_extrusionFactor, 1, Time.deltaTime * 5);
            _scrollSpeed = 0.75f;
        }
        else
        {
            _extrusionFactor = Mathf.Lerp(_extrusionFactor, 0.2f, Time.deltaTime * 5);
            _scrollSpeed = 0.4f;
        }

        if (_mat)
        {
            _mat.SetFloat("_ExtrusionFactor", _extrusionFactor);
            _mat.SetFloat("_NoiseTexScrollSpeed", _scrollSpeed);
        }
    }
}
