using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterRippleRegister : MonoBehaviour
{
    [SerializeField]
    private int rippleCount = 5;
    [SerializeField]
    private int rippleCountWhenMoving = 8;
    [SerializeField]
    private float increaseMultiplier = 1.0f;
    [SerializeField]
    private Material waterMaterial;

    private Dictionary<GameObject, List<Vector4>> waterObjects = new Dictionary<GameObject, List<Vector4>>();
    private Dictionary<GameObject, float> currentCollidingObjects = new Dictionary<GameObject, float>();
    private List<float> collidingObjectSizes = new List<float>();
    private float ratio;
    private float movingRatio;

    // Start is called before the first frame update
    void Start()
    {
        ratio = 1.0f / (float)rippleCount;
        movingRatio = 1.0f / (float)rippleCountWhenMoving;
    }

    private void OnValidate()
    {
        ratio = 1.0f / (float)rippleCount;
        movingRatio = 1.0f / (float)rippleCountWhenMoving;
        Debug.Log("Ratio: " + ratio + Environment.NewLine + "Moving Ratio: " + movingRatio);
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        AddListValues();
        UpdateListValues(waterObjects);
        PassListValuesToShader(waterObjects);
    }

    private void AddListValues()
    {
        List<GameObject> toRemove = new List<GameObject>();
        foreach (KeyValuePair<GameObject, List<Vector4>> entry in waterObjects)
        {
            //Check if still colliding with water
            if (currentCollidingObjects.ContainsKey(entry.Key))
            {
                float distVal = 0;
                if(entry.Value.Count > 0)
                {
                    distVal = Mathf.Clamp((new Vector2(entry.Value[entry.Value.Count - 1].x, entry.Value[entry.Value.Count - 1].y) - new Vector2(entry.Key.transform.position.x, entry.Key.transform.position.z)).magnitude, 0, 1);
                    distVal *= 1 + (1 - Mathf.Min(currentCollidingObjects[entry.Key], 1.0f));
                }
                float count = Mathf.Lerp(rippleCount, rippleCountWhenMoving, distVal);
                float rat = Mathf.Lerp(ratio, movingRatio, distVal);

                //Add water ripples
                if (entry.Value.Count < count)
                {
                    if (entry.Value.Count > 0 && entry.Value[entry.Value.Count - 1].z > rat)
                        entry.Value.Add(new Vector4(entry.Key.transform.position.x, entry.Key.transform.position.z, 0, currentCollidingObjects[entry.Key]));
                    else if (entry.Value.Count <= 0)
                        entry.Value.Add(new Vector4(entry.Key.transform.position.x, entry.Key.transform.position.z, 0, currentCollidingObjects[entry.Key]));
                }

            }
            else
            {
                if(entry.Value.Count <= 0)
                {
                    toRemove.Add(entry.Key);
                }
            }
        }

        //Remove extra objects
        foreach (GameObject obj in toRemove)
        {
            waterObjects.Remove(obj);
        }
        toRemove.Clear();
    }

    private void UpdateListValues(Dictionary<GameObject, List<Vector4>> dict)
    {
        foreach (KeyValuePair<GameObject, List<Vector4>> entry in dict)
        {
            for (int i = 0; i < entry.Value.Count; i++)
            {
                if (entry.Value[i].z >= 1.0f)
                {
                    entry.Value.RemoveAt(i);
                    i--;
                }
                else
                {
                    entry.Value[i] += new Vector4(0, 0, Time.deltaTime * increaseMultiplier, 0);
                }
            }

            //Debug.Log(entry.Value.Count);
        }
    }

    private void PassListValuesToShader(Dictionary<GameObject, List<Vector4>> dict)
    {
        int count = 0;
        List<Vector4> values = new List<Vector4>();

        foreach (KeyValuePair<GameObject, List<Vector4>> entry in dict)
        {
            for (int i = 0; i < entry.Value.Count; i++)
            {
                values.Add(entry.Value[i]);
                count++;
            }
        }

        var materialProp = new MaterialPropertyBlock();
        materialProp.SetInt("_rippleCount", count);
        if(values.Count > 0)
            materialProp.SetVectorArray("_ripples", values);
        GetComponent<Renderer>().SetPropertyBlock(materialProp);
    }

    private void OnTriggerEnter(Collider other)
    {
        Vector3 size = other.gameObject.GetComponent<Renderer>().bounds.size;
        currentCollidingObjects.Add(other.gameObject, Mathf.Min(Mathf.Max(size.x, size.z), 2.0f));
        if(!waterObjects.ContainsKey(other.gameObject))
            waterObjects.Add(other.gameObject, new List<Vector4>());
    }

    private void OnTriggerExit(Collider other)
    {
        currentCollidingObjects.Remove(other.gameObject);
    }
}
