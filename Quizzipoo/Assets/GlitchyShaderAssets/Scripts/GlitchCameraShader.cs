using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GlitchCameraShader : MonoBehaviour {

    private Material material;    

    public float GlitchInterval = 5f;
    [Range(0,1)]
    public float GlitchRate = 0.9f;
    public float HorizontalResolution = 640f;
    public float VerticalResolution = 480f;

    [Range(0,1)]
    public float WhiteNoiseIntensity = 1.0f;
       
    [Range(0, 1)]
    public float WaveNoiseIntensity = 1.0f;
    [Range(0, 1)]
    public float RGBShiftIntensity = 1.0f;

    public Color GlitchTint = Color.white;

    [Header("Component Settings")]
    [Space()]
    [Tooltip("Toggle the horizontal line glitch that moves vertically on the screen.")]
    public bool EnableScanlineGlitch = true;
    [Tooltip("Toggle the rectangle shifting glitch component")]
    public bool EnableBlockGlitch = true;
    [Tooltip("Toggle the screen shaking glitch controlled by Glitch Interval and Glitch Rate.")]
    public bool EnableShakeGlitch = true;




    void Start()
    {
        if (material == null)
        {
            material = new Material(Shader.Find("Custom/Glitchy Footage Shader"));
            material.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    void OnEnable()
    {
        if (material == null)
        {
            material = new Material(Shader.Find("Custom/Glitchy Footage Shader"));
            material.hideFlags = HideFlags.HideAndDontSave;
        }        
    }


    void OnDisable()
    {
        if (material != null)
        {
            DestroyImmediate(material);
        }
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
        {
            Graphics.Blit(source, destination);
        }
        else
        {
            material.SetFloat("_GlitchInterval", GlitchInterval);
            material.SetFloat("_GlitchRate", GlitchRate);
            material.SetFloat("_ResHorizontal", HorizontalResolution);
            material.SetFloat("_ResVertical", VerticalResolution);
            material.SetFloat("_WhiteNoiseIntensity", WhiteNoiseIntensity);
            material.SetFloat("_WaveNoiseIntensity", WaveNoiseIntensity);
            material.SetColor("_GlitchColor", GlitchTint);
            material.SetFloat("_BlockGlitchEnabled", EnableBlockGlitch ? 1f : 0f);
            material.SetFloat("_ShakeGlitchEnabled", EnableShakeGlitch ? 1f : 0f);
            material.SetFloat("_ScanlineGlitchEnabled", EnableScanlineGlitch ? 1f : 0f);
            material.SetFloat("_RGBShiftIntensity", RGBShiftIntensity);
            Graphics.Blit(source, destination, material);
        }
    }

}
