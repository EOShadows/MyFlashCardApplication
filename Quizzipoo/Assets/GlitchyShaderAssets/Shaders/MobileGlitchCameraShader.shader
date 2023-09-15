Shader "Custom/Mobile Glitchy Footage Shader"{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
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
			Tags{ "Queue" = "Geometry" "IGNOREPROJECTOR" = "true" "RenderType" = "Transparent" }
			LOD 200
			ZWrite Off
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
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
					o.uv = v.texcoord;
					return o;
				}

				uniform sampler2D _MainTex;
				uniform float _GlitchInterval;
				uniform float _GlitchRate;
				uniform float _ResHorizontal;
				uniform float _ResVertical;	
				uniform float _BlockGlitchEnabled;
				uniform float _ScanlineGlitchEnabled;
				uniform float _ShakeGlitchEnabled;
				uniform fixed _WhiteNoiseIntensity;
				uniform fixed _WaveNoiseIntensity;
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
						shake = fixed2(strength * 8.0 + 0.5, strength * 8.0 + 0.5) * fixed2(random(fixed2(_Time.xy)) * 2.0 - 1.0, random(fixed2(_Time.y * 2.0, _Time.y * 2.0)) * 2.0 - 1.0) / fixed2(_ResHorizontal, _ResVertical);
					}

					fixed y = i.uv.y * _ResVertical;
					fixed rgbWave = 0.;

					if (_ScanlineGlitchEnabled == 1.) {
						
						rgbWave = (							
							random(float2(y * 0.01, _Time.y * 400.0))
							* (2.0 + strength * 32.0)
							* random(float2(y * 0.02, _Time.y * 200.0))
							* (1.0 + strength * 4.0)
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
						
						float singleNoise = snoise(float2(i.uv.x * 3.0, bnTime));
						fixed noiseX = step((singleNoise + 1.0) / 2.0, 0.12 + strength * 0.3);
						fixed noiseY = step((singleNoise + i.uv.y + 1.0) / 2.0, 0.12 + strength * 0.3);

						bnMask = noiseX * noiseY;
						fixed bnUvX = i.uv.x + sin(bnTime) * 0.2 + rgbWave;

						fixed tR = tex2D(_MainTex, float2(bnUvX + rgbDiff, i.uv.y)).r;
						fixed tG = tex2D(_MainTex, float2(bnUvX, i.uv.y)).g;
						fixed tB = tex2D(_MainTex, float2(bnUvX - rgbDiff, i.uv.y)).b;
						
						fixed bnR = tR * bnMask;
						fixed bnG = tG * bnMask;
						fixed bnB = tB * bnMask;
						blockNoise = fixed4(bnR, bnG, bnB, 1.0);

						fixed bnTime2 = floor(_Time * 25.0) * 300.0;

						float singleNoise2 = snoise(float2(i.uv.x * 2.0, bnTime2));
						fixed noiseX2 = step((singleNoise2 + 1.0) / 2.0, 0.12 + strength * 0.5);
						fixed noiseY2 = step((singleNoise2 + i.uv.y + 1.0) / 2.0, 0.12 + strength * 0.3);

						bnMask2 = noiseX2 * noiseY2;
						fixed bnR2 = tR * bnMask2;
						fixed bnG2 = tG * bnMask2;
						fixed bnB2 = tB * bnMask2;
						blockNoise2 = fixed4(bnR2, bnG2, bnB2, 1.0);
					}

					fixed waveNoise = (sin(i.uv.y * 1200.0) + 1.0) / 2.0 * (0.15 + strength * 0.2);


					fixed4 ret = fixed4(rb.x, g, rb.y, 1.0) *
						(1.0 - bnMask - bnMask2) +
						((whiteNoise * _WhiteNoiseIntensity) + blockNoise + blockNoise2 - (waveNoise * _WaveNoiseIntensity));
					return ret;
				
				}
				ENDCG
			}
		}
}