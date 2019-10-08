using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BasicMovement : MonoBehaviour
{
    [SerializeField]
    [Range(0, 100)]
    private float _movementSpeed = 10;

    // Update is called once per frame
    void FixedUpdate()
    {
        Rotation();
        Movement();
    }

    private void Rotation()
    {
        if (Mathf.Abs(Input.GetAxis("Mouse X")) > 0)
        {
            transform.Rotate(Vector3.up, Input.GetAxis("Mouse X"));
        }
    }

    private void Movement()
    {
        Vector3 mvmnt = new Vector3();
        if (Input.GetKey(KeyCode.W))
        {
            mvmnt += transform.forward;
        }
        if (Input.GetKey(KeyCode.A))
        {
            mvmnt -= transform.right;
        }
        if (Input.GetKey(KeyCode.S))
        {
            mvmnt -= transform.forward;
        }
        if (Input.GetKey(KeyCode.D))
        {
            mvmnt += transform.right;
        }
        if (Input.GetKey(KeyCode.Space))
        {
            mvmnt += transform.up;
        }
        if (Input.GetKey(KeyCode.LeftShift))
        {
            mvmnt -= transform.up;
        }

        mvmnt.Normalize();
        mvmnt *= Time.fixedDeltaTime * _movementSpeed;

        transform.position += mvmnt;
    }
}
