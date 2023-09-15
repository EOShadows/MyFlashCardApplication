using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleRotator : MonoBehaviour {

    public float Speed = 4f;
    public Vector3 RotateAbout = Vector3.up;
	
	// Update is called once per frame
	void Update () {

        transform.Rotate(RotateAbout.normalized, Speed * Time.deltaTime);       


	}
}
