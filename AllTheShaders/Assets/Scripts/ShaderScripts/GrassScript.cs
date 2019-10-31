using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GrassScript : MonoBehaviour
{
    private Renderer _renderer;

    [SerializeField]
    [Range(0, 1)]
    private float _windStrength = 0.13f;
    [SerializeField]
    private float _windDirection = 0;

    private void OnEnable()
    {
        _renderer = GetComponent<Renderer>();

        Shader.SetGlobalFloat("_WindStrength", _windStrength);
        Shader.SetGlobalVector("_WindDirection", CalcWindDirection(_windDirection));
        Shader.SetGlobalFloat("_GrassHeight", _renderer.bounds.size.y);
    }

    private void Start()
    {
        Shader.SetGlobalFloat("_WindStrength", _windStrength);
        Shader.SetGlobalVector("_WindDirection", CalcWindDirection(_windDirection));
        Shader.SetGlobalFloat("_GrassHeight", _renderer.bounds.size.y);
    }

    private void OnValidate()
    {
        while(_windDirection > 360.0f)
        {
            _windDirection -= 360.0f;
        }
        while(_windDirection < 0.0f)
        {
            _windDirection += 360.0f;
        }

        Shader.SetGlobalFloat("_WindStrength", _windStrength);
        Shader.SetGlobalVector("_WindDirection", CalcWindDirection(_windDirection));
    }

    private Vector2 CalcWindDirection(float angle)
    {
        int count = 0;
        float dir = angle;
        while (dir >= 90)
        {
            dir -= 90;
            count++;
        }
        float x = 1;
        if (count == 1 || count == 2)
            x = -1;

        float tanVal = Mathf.Tan(angle * Mathf.Deg2Rad);
        float y = tanVal * x;

        return new Vector2(x, y);
    }
}
