using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GeometryDissolveScript : MonoBehaviour
{
    [SerializeField]
    private Transform _dissolveOrigin;
    [SerializeField]
    [Range(0, 1.5f)]
    private float _time = 0;
    [SerializeField]
    private float _speed = 1;

    private Material _mat;
    private Renderer _renderer;

    private void OnEnable()
    {
        _renderer = GetComponent<Renderer>();
        _mat = _renderer.sharedMaterial;
        _mat.SetVector("_DissolvePoint", _dissolveOrigin.position);
    }

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKey(KeyCode.O))
        {
            _time = Mathf.Lerp(_time, 0, Time.deltaTime * _speed);
        }
        if(Input.GetKey(KeyCode.P))
        {
            _time = Mathf.Lerp(_time, 1.5f, Time.deltaTime * _speed);
        }

        if (_mat)
        {
            _mat.SetVector("_DissolvePoint", _dissolveOrigin.position);
            _mat.SetFloat("_TimeScale", _time);
        }
    }

    private void OnValidate()
    {
        if (_mat)
        {
            _mat.SetVector("_DissolvePoint", _dissolveOrigin.position);
            _mat.SetFloat("_TimeScale", _time);
        }
    }
}
