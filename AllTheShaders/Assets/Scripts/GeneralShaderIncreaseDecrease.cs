using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GeneralShaderIncreaseDecrease : MonoBehaviour
{
    [SerializeField]
    private List<string> _fieldsToAdjust = new List<string>();
    [SerializeField]
    private float _adjustSpeed = 1.0f;

    private Renderer _renderer;
    private Material _mat;

    // Start is called before the first frame update
    void Start()
    {
        _renderer = GetComponent<Renderer>();
        _mat = _renderer.sharedMaterial;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.O))
        {
            foreach (string field in _fieldsToAdjust)
            {
                float currentVal = _mat.GetFloat(field);
                _mat.SetFloat(field, currentVal - (Time.deltaTime * _adjustSpeed));
            }
        }
        if(Input.GetKey(KeyCode.P))
        {
            foreach (string field in _fieldsToAdjust)
            {
                float currentVal = _mat.GetFloat(field);
                _mat.SetFloat(field, currentVal + (Time.deltaTime * _adjustSpeed));
            }
        }
    }
}
