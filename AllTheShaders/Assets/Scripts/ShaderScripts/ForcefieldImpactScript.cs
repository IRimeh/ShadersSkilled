using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ForcefieldImpactScript : MonoBehaviour
{
    private Camera _camera;
    private Renderer _renderer;
    private List<Vector4> _impacts = new List<Vector4>();

    [SerializeField]
    [Range(0, 10)]
    private float speed = 5;

    // Start is called before the first frame update
    private void OnEnable()
    {
        _renderer = GetComponent<Renderer>();
        _camera = Camera.main;
    }

    // Update is called once per frame
    void Update()
    {
        AddImpacts();
        UpdateImpacts();
        PassImpacts();
    }

    private void AddImpacts()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = _camera.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                _impacts.Add(new Vector4(hit.point.x, hit.point.y, hit.point.z, 0));
            }
        }
    }

    private void UpdateImpacts()
    {
        for (int i = 0; i < _impacts.Count; i++)
        {
            if(_impacts[i].w <= 7)
            {
                _impacts[i] += new Vector4(0, 0, 0, Time.deltaTime * speed);
            }
            else
            {
                _impacts.RemoveAt(i);
                i--;
            }
        }
    }

    private void PassImpacts()
    {
        var materialProp = new MaterialPropertyBlock();
        materialProp.SetFloat("_CurrentImpactCount", _impacts.Count);
        if (_impacts.Count > 0)
            materialProp.SetVectorArray("_ImpactPositions", _impacts);
        _renderer.SetPropertyBlock(materialProp);
    }
}
