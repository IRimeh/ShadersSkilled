using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class FireProjectile : MonoBehaviour
{
    [SerializeField]
    private float projectileSpeed = 50;
    [SerializeField]
    private List<ParticleSystem> hitParticleSystems = new List<ParticleSystem>();
    [SerializeField]
    private List<Renderer> renderersToDisable = new List<Renderer>();

    private Rigidbody rb;
    private bool hitGround = false;
    private DateTime spawnTime;

    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        rb.constraints = RigidbodyConstraints.FreezeAll;
        spawnTime = DateTime.Now;
    }

    private void Update()
    {
        if (!hitGround)
        {
            transform.position += transform.forward * Time.deltaTime * projectileSpeed;
            if((DateTime.Now - spawnTime).TotalSeconds > 10)
            {
                Destroy(this.gameObject);
            }
        }
        else
        {
            bool playing = true;
            foreach (ParticleSystem particleSystem in hitParticleSystems)
            {
                if (!particleSystem.isPlaying)
                {
                    playing = false;
                    break;
                }
            }

            if (!playing)
                Destroy(this.gameObject);
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        hitGround = true;
        transform.position = collision.contacts[0].point;
        Quaternion rot = Quaternion.FromToRotation(Vector3.up, collision.contacts[0].normal);
        transform.rotation = rot;
        rb.rotation = rot;

        rb.velocity = Vector3.zero;
        rb.constraints = RigidbodyConstraints.FreezeAll;

        foreach (Renderer renderer in renderersToDisable)
        {
            renderer.enabled = false;
        }

        foreach (ParticleSystem particleSystem in hitParticleSystems)
        {
            particleSystem.Play();
        }
    }
}
