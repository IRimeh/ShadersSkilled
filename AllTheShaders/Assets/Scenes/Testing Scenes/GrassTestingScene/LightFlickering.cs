using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class LightFlickering : MonoBehaviour
{
    private int _timeInbetweenFlickering = 2000;
    private int _flickeringChance = 3; // 3 out of 100
    private int _stayFlickeringTimeInMs = 3000;
    private bool _bothLights = true;
    private int _lightIndex = 0;

    private DateTime _startFlickeringTime;
    private DateTime _flickeringTime = DateTime.MinValue;
    private Light[] _lights;
    private float[] _intensities;

    private float _startStrength;

    // Start is called before the first frame update
    void Start()
    {
        _startFlickeringTime = DateTime.Now.AddMilliseconds(_timeInbetweenFlickering);
        _lights = transform.GetComponentsInChildren<Light>();
        _intensities = new float[_lights.Length];
        for (int i = 0; i < _lights.Length; i++)
        {
            _intensities[i] = _lights[i].intensity;
        }

        if (!_bothLights)
        {
            _lightIndex = Mathf.FloorToInt(UnityEngine.Random.Range(0, 1.9f));
        }

        //Generate new flickering chance
        _flickeringChance = Mathf.RoundToInt(UnityEngine.Random.Range(0, 15));
    }

    // Update is called once per frame
    void Update()
    {
        if (_bothLights)
            BothLightFLickering();
        else
            SingleLightFlickering();
    }

    private void BothLightFLickering()
    {
        //Start flickering
        if (DateTime.Now > _startFlickeringTime)
        {
            if (_flickeringTime < _startFlickeringTime)
            {
                //Set stop flickering time
                _flickeringTime = DateTime.Now.AddMilliseconds(_stayFlickeringTimeInMs + UnityEngine.Random.Range(0, _stayFlickeringTimeInMs));
            }
            else
            {
                if (DateTime.Now > _flickeringTime)
                {
                    //Stop flickering
                    _startFlickeringTime = DateTime.Now.AddMilliseconds(UnityEngine.Random.Range(0, _timeInbetweenFlickering));

                    for (int i = 0; i < _lights.Length; i++)
                    {
                        _lights[_lightIndex].enabled = true;
                        _lights[_lightIndex].intensity = _intensities[_lightIndex];
                    }

                    //Randomly choose what light to flicker next
                    if (UnityEngine.Random.Range(0, 100) > 50)
                        _lightIndex = 0;
                    else
                        _lightIndex = 1;

                    //Generate new flickering chance
                    _flickeringChance = Mathf.RoundToInt(UnityEngine.Random.Range(0, 15));
                }
                else
                {
                    //Flicker light
                    if (UnityEngine.Random.Range(0, 100) > 100 - _flickeringChance)
                    {
                        if (_lights[_lightIndex].enabled)
                        {
                            _lights[_lightIndex].enabled = false;
                            _lights[_lightIndex].intensity = 0;
                            //_lights[_lightIndex + 2].enabled = false;
                            //_auraLights[_lightIndex].enabled = false;
                        }
                        else
                        {
                            _lights[_lightIndex].enabled = true;
                            _lights[_lightIndex].intensity = _intensities[_lightIndex];
                            //_lights[_lightIndex + 2].enabled = true;
                            //_auraLights[_lightIndex].enabled = true;
                        }
                    }
                }
            }
        }
    }

    private void SingleLightFlickering()
    {
        //Start flickering
        if (DateTime.Now > _startFlickeringTime)
        {
            if (_flickeringTime < _startFlickeringTime)
            {
                //Set stop flickering time
                _flickeringTime = DateTime.Now.AddMilliseconds(_stayFlickeringTimeInMs + UnityEngine.Random.Range(0, _stayFlickeringTimeInMs));
            }
            else
            {
                if (DateTime.Now > _flickeringTime)
                {
                    //Stop flickering
                    _startFlickeringTime = DateTime.Now.AddMilliseconds(UnityEngine.Random.Range(0, _timeInbetweenFlickering));

                    //Generate new flickering chance
                    _flickeringChance = Mathf.RoundToInt(UnityEngine.Random.Range(0, 15));
                }
                else
                {
                    //Flicker light
                    if (UnityEngine.Random.Range(0, 100) > 100 - _flickeringChance)
                    {
                        if (_lights[_lightIndex].enabled)
                        {
                            _lights[_lightIndex].enabled = false;
                            _lights[_lightIndex + 2].enabled = false;
                            //_auraLights[_lightIndex].enabled = false;
                        }
                        else
                        {
                            _lights[_lightIndex].enabled = true;
                            _lights[_lightIndex + 2].enabled = true;
                            //_auraLights[_lightIndex].enabled = true;
                        }
                    }
                }
            }
        }
    }
}
