using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderFieldUpdater : MonoBehaviour
{
    private Renderer renderer;
    private Material material;



    [SerializeField]
    private string fieldName;
    [SerializeField]
    private float startValue;
    [SerializeField]
    private float endValue;

    [SerializeField]
    [Range(0, 1)]
    private float time;


    private void OnEnable()
    {
        renderer = GetComponent<Renderer>();
        material = renderer.material;
    }

    private void Update()
    {
        if (fieldName != "" && renderer)
        {
            float maxVal = endValue - startValue;
            material.SetFloat(fieldName, startValue + (maxVal * time));
        }
    }
}
