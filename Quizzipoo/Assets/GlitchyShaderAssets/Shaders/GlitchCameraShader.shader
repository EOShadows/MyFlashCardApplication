Shader "Custom/Glitchy Footage Shader"{
	Properties{
		_MainTex("Main Texture", 2D) = "white" {}
		_GlitchColor("Glitch Color", Color) = (1.0,1.0,1.0,1.0)
		_GlitchInterval("Glitch Interval", Float) = 5.0	
		_GlitchRate("Glitch Rate", Range(0,1)) = 0.9
		_ResHorizontal("Horizontal Resolution", Float) = 640
		_ResVertical("Vertical Resolution", Float) = 480
		_WhiteNoiseIntensity("White Noise Intensity", Float) = 1.0	
		_WaveNoiseIntensity("Wave Noise Intensity", Float) = 1.0
		_RGBShiftIntensity("RGB Shift Intensity", Float) = 1.0
		_BlockGlitchEnabled("Block Glitch", Float) = 1.0
		_ShakeGlitchEnabled("Shake Glitch", Float) = 1.0
		_ScanlineGlitchEnabled("Scanline Glitch", Float) = 1.0
	}
	SubShader
	{
		Tags{ "Queue" = "Geometry" }
		LOD 200

		//License: https://opensource.org/licenses/mit-license.php
		// GLSL ported to Cg/HLSL and modified. 
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc" 
			#include "noiseSimplex.cginc"
			#pragma target 3.0
			
			struct appdata {
				float4 vertex: POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos :SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = float2(v.texcoord.xy);
				return o;
			}

			uniform sampler2D _MainTex;
			uniform float _GlitchInterval;
			uniform float _GlitchRate;
			uniform float _ResHorizontal;
			uniform float _ResVertical;
			uniform fixed _WhiteNoiseIntensity;
			uniform fixed _WaveNoiseIntensity;
			uniform fixed4 _GlitchColor;
			uniform float _BlockGlitchEnabled;
			uniform float _ScanlineGlitchEnabled;
			uniform float _ShakeGlitchEnabled;
			uniform fixed _RGBShiftIntensity;

			float random(float2 c) {
				return frac(sin(dot(c.xy, float2(12.9898, 78.233))) * 43758.5453);
			}
			float mod(float x, float y)
			{
				return x - y * floor(x / y);
			}
			

			fixed4 frag(v2f i) : SV_Target 
			{
				fixed strength = 0.;
				fixed2 shake = fixed2(0., 0.);
				if (_ShakeGlitchEnabled == 1.) {
					 strength = smoothstep(_GlitchInterval * _GlitchRate, _GlitchInterval, _GlitchInterval - mod(_Time.y, _GlitchInterval));
					 shake = fixed2(strength * 8.0 + 0.5, strength * 8.0 + 0.5)* fixed2(random(fixed2(_Time.xy)) * 2.0 - 1.0, random(fixed2(_Time.y * 2.0, _Time.y * 2.0)) * 2.0 - 1.0) / fixed2(_ResHorizontal, _ResVertical);
				}


				fixed y = i.uv.y * _ResVertical;
				fixed rgbWave = 0.;
				if (_ScanlineGlitchEnabled == 1.) {
					rgbWave = (
						snoise(float2( y * 0.01, _Time.y * 400.0)) * (2.0 + strength * 32.0) //Time.x was just _Time in original
						* snoise(float2( y * 0.02, _Time.y * 200.0)) * (1.0 + strength * 4.0) //Time.x was just _Time in original
						+ step(0.9995, sin(y * 0.005 + _Time.y * 1.6)) * 12.0
						+ step(0.9999, sin(y * 0.005 + _Time.y * 2.0)) * -18.0
						) / _ResHorizontal;
				}
				fixed rgbDiff = (6.0 + sin(_Time.y * 500.0 + i.uv.y * 40.0) * (20.0 * strength + 1.0)) / _ResHorizontal;
				rgbDiff = rgbDiff * _RGBShiftIntensity;
				fixed rgbUvX = i.uv.x + rgbWave;
				
				fixed g = tex2D(_MainTex, float2(rgbUvX, i.uv.y) + shake).g;
				fixed2 rb = tex2D(_MainTex, float2(rgbUvX + rgbDiff, i.uv.y) + shake).rb;//r and b channels get shifted by rgbDiff amount
				
				fixed whiteNoise = (random(i.uv + mod(_Time.y, 10.0)) * 2.0 - 1.0) * (0.15 + strength * 0.15);

				fixed bnMask = 0.;
				fixed bnMask2 = 0.;
				fixed4 blockNoise = fixed4(0., 0., 0., 0.);
				fixed4 blockNoise2 = fixed4(0., 0., 0., 0.);

				if (_BlockGlitchEnabled == 1.) {
					fixed bnTime = floor(_Time.y * 20.0) * 200.0;
					float noiseX = step((snoise(float3(0.0, i.uv.x * 3.0, bnTime)) + 1.0) / 2.0, 0.12 + strength * 0.3);
					float noiseY = step((snoise(float3(0.0, i.uv.y * 3.0, bnTime)) + 1.0) / 2.0, 0.12 + strength * 0.3);
					bnMask = noiseX * noiseY;
					fixed bnUvX = i.uv.x + sin(bnTime) * 0.2 + rgbWave;
					half bnR = tex2D(_MainTex, float2(bnUvX + rgbDiff, i.uv.y)).r * bnMask;
					half bnG = tex2D(_MainTex, float2(bnUvX, i.uv.y)).g * bnMask;
					half bnB = tex2D(_MainTex, float2(bnUvX - rgbDiff, i.uv.y)).b * bnMask;
					blockNoise = fixed4(bnR, bnG, bnB, 1.0);

					float bnTime2 = floor(_Time * 25.0) * 300.0;
					float noiseX2 = step((snoise(float3(0.0, i.uv.x * 2.0, bnTime2)) + 1.0) / 2.0, 0.12 + strength * 0.5);
					float noiseY2 = step((snoise(float3(0.0, i.uv.y * 8.0, bnTime2)) + 1.0) / 2.0, 0.12 + strength * 0.3);
					bnMask2 = noiseX2 * noiseY2;
					half bnR2 = tex2D(_MainTex, float2(bnUvX + rgbDiff, i.uv.y)).r * bnMask2;
					half bnG2 = tex2D(_MainTex, float2(bnUvX, i.uv.y)).g * bnMask2;
					half bnB2 = tex2D(_MainTex, float2(bnUvX - rgbDiff, i.uv.y)).b * bnMask2;
					blockNoise2 = fixed4(bnR2, bnG2, bnB2, 1.0);
				}

				fixed waveNoise = (sin(i.uv.y * 1200.0) + 1.0) / 2.0 * (0.15 + strength * 0.2);

				//gl_FragColor = vec4(r, g, b, 1.0) * (1.0 - bnMask - bnMask2) + (whiteNoise + blockNoise + blockNoise2 - waveNoise);
				fixed4 ret = fixed4(rb.x, g, rb.y, 1.0) *
					((1.0 - bnMask - bnMask2) * _GlitchColor) +
					((whiteNoise* _WhiteNoiseIntensity) +
						blockNoise +
						blockNoise2 -
						(waveNoise* _WaveNoiseIntensity)) * _GlitchColor;

				return ret;
			}
			ENDCG
		}     
	}
}