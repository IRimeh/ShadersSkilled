using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightRotator : MonoBehaviour
{
    [SerializeField]
    private float _rotationSpeed = 10;

    // Update is called once per frame
    void Update()
    {
        transform.rotation = Quaternion.Euler(transform.rotation.eulerAngles + new Vector3(0, Time.deltaTime * _rotationSpeed, 0));
    }
}
