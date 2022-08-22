﻿Shader "K13A_/Cubemap" {
Properties {
    _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
    [Gamma] _Gamma ("Gamma Brightness", Range(0, 8)) = 1.0
    _Rotation ("Rotation", Range(0, 360)) = 0
    _Alpha ("Master Alpha", Range(0, 1)) = 1
    _AlphaMapRange ("AlphaMap Range", Range(0, 1)) = 1
    [NoScaleOffset] _Tex ("Cubemap   (HDR)", Cube) = "grey" {}
    [NoScaleOffset] _AlphaMap ("AlphaCubemap   (HDR)", Cube) = "white" {}
}

SubShader {
    Tags {"Queue"="Geometry-1000" "IgnoreProjector"="True" "RenderType"="Transparent"}
    blend SrcAlpha OneMinusSrcAlpha 
    Cull Front ZWrite Off

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0

        #include "UnityCG.cginc"

        samplerCUBE _Tex;
        samplerCUBE _AlphaMap;
        half4 _Tex_HDR;
        half4 _Tint;
        half _Gamma;
        float _Rotation;
        float _Alpha;
        float _AlphaMapRange;

        float3 RotateAroundYInDegrees (float3 vertex, float degrees)
        {
            float alpha = degrees * UNITY_PI / 180.0;
            float sina, cosa;
            sincos(alpha, sina, cosa);
            float2x2 m = float2x2(cosa, -sina, sina, cosa);
            return float3(mul(m, vertex.xz), vertex.y).xzy;
        }

        struct appdata_t {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f {
            float4 vertex : SV_POSITION;
            float3 texcoord : TEXCOORD0;
            UNITY_VERTEX_OUTPUT_STEREO
        };

        v2f vert (appdata_t v)
        {
            v2f o;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            o.vertex = UnityObjectToClipPos(v.vertex);
            float3 viewDir = WorldSpaceViewDir(v.vertex);
            viewDir = RotateAroundYInDegrees(viewDir, _Rotation);
            o.texcoord = viewDir;
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            float3 dir = normalize(-i.texcoord);
            half4 tex = texCUBE (_Tex, dir);
            half4 alpha = texCUBE (_AlphaMap, dir);
            half3 c = DecodeHDR (tex, _Tex_HDR);
            c = c * _Tint.rgb;
            c *= _Gamma;
            return half4(c, clamp(_Alpha - (1 - alpha.r) * _AlphaMapRange, 0, 1));
        }
        ENDCG
    }
}


Fallback Off

}