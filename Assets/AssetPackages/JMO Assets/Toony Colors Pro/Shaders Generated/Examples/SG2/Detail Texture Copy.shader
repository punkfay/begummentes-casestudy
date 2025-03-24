// Toony Colors Pro+Mobile 2
// (c) 2014-2022 Jean Moreno

Shader "Toony Colors Pro 2/Examples/SG2/Detail Texture Copy"
{
	Properties
	{
		[TCP2HeaderHelp(Base)]
		_Color ("Color", Color) = (1,1,1,1)
		[TCP2ColorNoAlpha] _HColor ("Highlight Color", Color) = (0.75,0.75,0.75,1)
		[TCP2ColorNoAlpha] _SColor ("Shadow Color", Color) = (0.2,0.2,0.2,1)
		_MainTex ("Albedo", 2D) = "white" {}
		[TCP2Separator]

		[TCP2Header(Ramp Shading)]
		_RampThreshold ("Threshold", Range(0.01,1)) = 0.5
		_RampSmoothing ("Smoothing", Range(0.001,1)) = 0.5
		[TCP2Separator]
		
		[TCP2HeaderHelp(Normal Mapping)]
		_NormalMap ("Normal Map Texture", 2D) = "bump" {}
		 _DetailNormalMap ("Detail Normal Map", 2D) = "white" {}
		[NoScaleOffset] _ParallaxMap ("Height Map", 2D) = "black" {}
		_Parallax ("Height", Range(0.005,0.08)) = 0.02
		[TCP2Separator]
		
		// Custom Material Properties
		 _DetailTex ("Detail Map", 2D) = "white" {}

		// Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"RenderType"="Opaque"
		}

		CGINCLUDE

		#include "UnityCG.cginc"
		#include "UnityLightingCommon.cginc"	// needed for LightColor

		// Texture/Sampler abstraction
		#define TCP2_TEX2D_WITH_SAMPLER(tex)						UNITY_DECLARE_TEX2D(tex)
		#define TCP2_TEX2D_NO_SAMPLER(tex)							UNITY_DECLARE_TEX2D_NOSAMPLER(tex)
		#define TCP2_TEX2D_SAMPLE(tex, samplertex, coord)			UNITY_SAMPLE_TEX2D_SAMPLER(tex, samplertex, coord)
		#define TCP2_TEX2D_SAMPLE_LOD(tex, samplertex, coord, lod)	UNITY_SAMPLE_TEX2D_SAMPLER_LOD(tex, samplertex, coord, lod)

		// Custom Material Properties
		TCP2_TEX2D_WITH_SAMPLER(_DetailTex);

		// Shader Properties
		TCP2_TEX2D_WITH_SAMPLER(_ParallaxMap);
		TCP2_TEX2D_WITH_SAMPLER(_NormalMap);
		TCP2_TEX2D_WITH_SAMPLER(_DetailNormalMap);
		TCP2_TEX2D_WITH_SAMPLER(_MainTex);
		
		// Custom Material Properties
		float4 _DetailTex_ST;

		// Shader Properties
		float _Parallax;
		float4 _NormalMap_ST;
		float4 _DetailNormalMap_ST;
		float4 _MainTex_ST;
		fixed4 _Color;
		float _RampThreshold;
		float _RampSmoothing;
		fixed4 _HColor;
		fixed4 _SColor;

		// Calculates UV offset for parallax bump mapping
		inline float2 TCP2_ParallaxOffset( half h, half height, half3 viewDir )
		{
			h = h * height - height/2.0;
			float3 v = normalize(viewDir);
			v.z += 0.42;
			return h * (v.xy / v.z);
		}

		ENDCG

		// Main Surface Shader

		CGPROGRAM

		#pragma surface surf ToonyColorsCustom vertex:vertex_surface exclude_path:deferred exclude_path:prepass keepalpha nolightmap nofog nolppv
		#pragma target 3.0

		//================================================================
		// STRUCTS

		// Vertex input
		struct appdata_tcp2
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord0 : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 texcoord2 : TEXCOORD2;
			half4 tangent : TANGENT;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct Input
		{
			half3 viewDir;
			half3 tangent;
			float2 texcoord0;
		};

		//================================================================

		// Custom SurfaceOutput
		struct SurfaceOutputCustom
		{
			half atten;
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Specular;
			half Gloss;
			half Alpha;
			float3 normalTS;

			Input input;

			// Shader Properties
			float __rampThreshold;
			float __rampSmoothing;
			float3 __highlightColor;
			float3 __shadowColor;
			float __ambientIntensity;
		};

		//================================================================
		// VERTEX FUNCTION

		void vertex_surface(inout appdata_tcp2 v, out Input output)
		{
			UNITY_INITIALIZE_OUTPUT(Input, output);

			// Texture Coordinates
			output.texcoord0.xy = v.texcoord0.xy * _NormalMap_ST.xy * _MainTex_ST.xy + _NormalMap_ST.zw + _MainTex_ST.zw;

			output.tangent = mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0)).xyz;

		}

		//================================================================
		// SURFACE FUNCTION

		void surf(Input input, inout SurfaceOutputCustom output)
		{
			//Parallax Offset
			float __parallaxHeightMap = ( TCP2_TEX2D_SAMPLE(_ParallaxMap, _ParallaxMap, input.texcoord0.xy).a );
			float __parallaxHeight = ( _Parallax );
			half height = __parallaxHeightMap;
			float2 offset = ParallaxOffset(height, __parallaxHeight, input.viewDir);
			input.texcoord0 += offset;
			// Custom Material Properties Sampling
			half4 value__DetailTex = TCP2_TEX2D_SAMPLE(_DetailTex, _DetailTex, input.texcoord0.xy * _DetailTex_ST.xy + _DetailTex_ST.zw).rgba;

			// Sampled in Custom Code
			float4 imp_100 = value__DetailTex;
			// Shader Properties Sampling
			float4 __normalMap = (  lerp(TCP2_TEX2D_SAMPLE(_NormalMap, _NormalMap, input.texcoord0.xy).rgba, TCP2_TEX2D_SAMPLE(_DetailNormalMap, _DetailNormalMap, input.texcoord0.xy * _DetailNormalMap_ST.xy + _DetailNormalMap_ST.zw).rgba, value__DetailTex.a) );
			float4 __albedo = (  lerp(TCP2_TEX2D_SAMPLE(_MainTex, _MainTex, input.texcoord0.xy).rgba, imp_100.rgba, imp_100.a) );
			float4 __mainColor = ( _Color.rgba );
			float __alpha = ( __albedo.a * __mainColor.a );
			output.__rampThreshold = ( _RampThreshold );
			output.__rampSmoothing = ( _RampSmoothing );
			output.__highlightColor = ( _HColor.rgb );
			output.__shadowColor = ( _SColor.rgb );
			output.__ambientIntensity = ( 1.0 );

			output.input = input;

			half4 normalMap = __normalMap;
			output.Normal = UnpackNormal(normalMap);
			output.normalTS = output.Normal;

			output.Albedo = __albedo.rgb;
			output.Alpha = __alpha;

			output.Albedo *= __mainColor.rgb;

		}

		//================================================================
		// LIGHTING FUNCTION

		inline half4 LightingToonyColorsCustom(inout SurfaceOutputCustom surface, half3 viewDir, UnityGI gi)
		{

			half3 lightDir = gi.light.dir;
			#if defined(UNITY_PASS_FORWARDBASE)
				half3 lightColor = _LightColor0.rgb;
				half atten = surface.atten;
			#else
				// extract attenuation from point/spot lights
				half3 lightColor = _LightColor0.rgb;
				half atten = max(gi.light.color.r, max(gi.light.color.g, gi.light.color.b)) / max(_LightColor0.r, max(_LightColor0.g, _LightColor0.b));
			#endif

			half3 normal = normalize(surface.Normal);
			half ndl = dot(normal, lightDir);
			half3 ramp;
			
			#define		RAMP_THRESHOLD	surface.__rampThreshold
			#define		RAMP_SMOOTH		surface.__rampSmoothing
			ndl = saturate(ndl);
			ramp = smoothstep(RAMP_THRESHOLD - RAMP_SMOOTH*0.5, RAMP_THRESHOLD + RAMP_SMOOTH*0.5, ndl);

			// Apply attenuation (shadowmaps & point/spot lights attenuation)
			ramp *= atten;

			// Highlight/Shadow Colors
			#if !defined(UNITY_PASS_FORWARDBASE)
				ramp = lerp(half3(0,0,0), surface.__highlightColor, ramp);
			#else
				ramp = lerp(surface.__shadowColor, surface.__highlightColor, ramp);
			#endif

			// Output color
			half4 color;
			color.rgb = surface.Albedo * lightColor.rgb * ramp;
			color.a = surface.Alpha;

			// Apply indirect lighting (ambient)
			half occlusion = 1;
			#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
				half3 ambient = gi.indirect.diffuse;
				ambient *= surface.Albedo * occlusion * surface.__ambientIntensity;

				color.rgb += ambient;
			#endif

			return color;
		}

		void LightingToonyColorsCustom_GI(inout SurfaceOutputCustom surface, UnityGIInput data, inout UnityGI gi)
		{
			half3 normal = surface.Normal;

			// GI without reflection probes
			gi = UnityGlobalIllumination(data, 1.0, normal); // occlusion is applied in the lighting function, if necessary

			surface.atten = data.atten; // transfer attenuation to lighting function
			gi.light.color = _LightColor0.rgb; // remove attenuation

		}

		ENDCG

	}

	Fallback "Diffuse"
	CustomEditor "ToonyColorsPro.ShaderGenerator.MaterialInspector_SG2"
}

/* TCP_DATA u config(ver:"2.9.1";unity:"2021.3.15f1";tmplt:"SG2_Template_Default";features:list["UNITY_5_4","UNITY_5_5","BUMP","PARALLAX","UNITY_5_6","UNITY_2017_1","UNITY_2018_1","UNITY_2018_2","UNITY_2018_3","UNITY_2019_1","UNITY_2019_2","UNITY_2019_3","UNITY_2019_4","UNITY_2020_1","UNITY_2021_1"];flags:list[];flags_extra:dict[];keywords:dict[RENDER_TYPE="Opaque",RampTextureDrawer="[TCP2Gradient]",RampTextureLabel="Ramp Texture",SHADER_TARGET="3.0"];shaderProperties:list[sp(name:"Albedo";imps:list[imp_customcode(prepend_type:Disabled;prepend_code:"";prepend_file:"";prepend_file_block:"";preprend_params:dict[];code:"lerp({2}.rgba, {3}.rgba, {3}.a)";guid:"77d5bf2e-8e82-4047-a590-105851d75d48";op:Multiply;lbl:"Albedo";gpu_inst:False;locked:False;impl_index:-1),imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:True;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"white";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_MainTex";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"99c71125-3b44-4e0d-b337-f81343e3dcfd";op:Multiply;lbl:"Albedo";gpu_inst:False;locked:False;impl_index:0),imp_ct(lct:"_DetailTex";cc:4;chan:"RGBA";avchan:"RGBA";guid:"e8ebc0b2-f98e-48c9-867d-5060270cafeb";op:Multiply;lbl:"Detail";gpu_inst:False;locked:False;impl_index:-1)];layers:list[];unlocked:list[];clones:dict[];isClone:False),,,,,,,,sp(name:"Normal Map";imps:list[imp_customcode(prepend_type:Disabled;prepend_code:"";prepend_file:"";prepend_file_block:"";preprend_params:dict[];code:"lerp({2}.rgba, {3}.rgba, {4}.a)";guid:"3ad3e73e-6ebd-4051-9e5b-6f9c66e7ecbe";op:Multiply;lbl:"Normal Map";gpu_inst:False;locked:False;impl_index:-1),imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:True;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"bump";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_NormalMap";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"99c71125-3b44-4e0d-b337-f81343e3dcfd";op:Multiply;lbl:"Normal Map Texture";gpu_inst:False;locked:False;impl_index:-1),imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"white";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_DetailNormalMap";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"dff3efe8-6675-4101-a9f6-05f8a7d9a439";op:Multiply;lbl:"Detail Normal Map";gpu_inst:False;locked:False;impl_index:-1),imp_ct(lct:"_DetailTex";cc:4;chan:"RGBA";avchan:"RGBA";guid:"920f545a-ede8-4011-bee0-90c188aa8081";op:Multiply;lbl:"Normal Map";gpu_inst:False;locked:False;impl_index:-1)];layers:list[];unlocked:list[];clones:dict[];isClone:False)];customTextures:list[ct(cimp:imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"white";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:0;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_DetailTex";md:"";gbv:False;custom:True;refs:"Albedo, Normal Map";pnlock:False;guid:"d9bdb63a-02a4-4d35-8e12-75d4d0d0152f";op:Multiply;lbl:"Detail Map";gpu_inst:False;locked:False;impl_index:-1);exp:False;uv_exp:False;imp_lbl:"Texture")];codeInjection:codeInjection(injectedFiles:list[];mark:False);matLayers:list[]) */
/* TCP_HASH aa7bb702ae57ce3e5cae6c41dcb08af0 */
