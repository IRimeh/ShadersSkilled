using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Light))]
public class LightshaftSettings : MonoBehaviour
{
    [SerializeField]
    [Range(0, 2)]
    private float _intensity = 0.25f;
    [SerializeField]
    private bool _enableGrain;
    [SerializeField]
    private Texture2D _grainTexture;

    public float GetIntensity()
    {
        return _intensity;
    }

    public bool IsGrainEnabled()
    {
        if (_enableGrain && _grainTexture != null)
            return _enableGrain;
        else
            return false;
    }

    public Texture2D GetGrainTexture()
    {
        return _grainTexture;
    }

    public void SetGrainTexture(Texture2D tex)
    {
        _grainTexture = tex;
    }
}
