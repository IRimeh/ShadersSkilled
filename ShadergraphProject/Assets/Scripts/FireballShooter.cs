using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FireballShooter : MonoBehaviour
{
    [SerializeField]
    private GameObject fireballPrefab;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if(Input.GetMouseButtonDown(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            Quaternion rot = Quaternion.FromToRotation(Vector3.forward, ray.direction);

            Instantiate(fireballPrefab, transform.position + ray.direction * 0.1f, rot);
        }
    }
}
