using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class fullscreen_script : MonoBehaviour
{

    public static bool inFullScreen = false;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void change()
    {
        if (!inFullScreen)
        {
            Screen.fullScreenMode = FullScreenMode.FullScreenWindow;
            inFullScreen = true;
        }
        else
        {
            Screen.fullScreenMode = FullScreenMode.Windowed;
            inFullScreen = false;
        }
    }
}
