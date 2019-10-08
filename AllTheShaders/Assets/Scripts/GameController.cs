using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GameController : MonoBehaviour
{
    [SerializeField]
    private bool _setValuesInPlaymode = false;
    [SerializeField]
    private Color _shadowColor;

    private void OnEnable()
    {
        Shader.SetGlobalColor("_ShadowColor", _shadowColor);
    }

    // Update is called once per frame
    void Update()
    {
        if (_setValuesInPlaymode || !Application.isPlaying)
        {
            Shader.SetGlobalColor("_ShadowColor", _shadowColor);
        }
    }
}
