using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterPhysicsScript : MonoBehaviour
{
    private Collider _collider;
    private float _top;

    [SerializeField]
    private float _WaterStrength = 1;

    private void Start()
    {
        _collider = GetComponent<Collider>();

        _top = transform.position.y + _collider.bounds.extents.y;
    }

    private void OnTriggerStay(Collider other)
    {
        Rigidbody rb = other.gameObject.GetComponent<Rigidbody>();
        if (rb)
        {
            float dist = _top - other.transform.position.y;
            if(dist > 0)
            {
                if (rb.velocity.y < 0)
                    rb.velocity += new Vector3(0, _WaterStrength * Time.fixedDeltaTime + (Mathf.Abs(rb.velocity.y) * 0.01f), 0);
                else
                    rb.velocity += new Vector3(0, _WaterStrength * Time.fixedDeltaTime, 0);
            }
            if (Mathf.Abs(dist) < 0.001f && rb.velocity.y < 0.001)
            {
                rb.velocity = new Vector3(rb.velocity.x, 0, rb.velocity.z);
                rb.useGravity = false;
            }
            else
                rb.useGravity = true;
        }
    }
}
