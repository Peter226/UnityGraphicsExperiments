#include "./RadianceLighting.hlsl"

float3 _Cascade_Write_PositionWS;
float _Cascade_Write_Size;
float _Cascade_Write_SizeInverse;

float3 WorldToWriteCascade(float3 positionWS) {
	float3 offsetPositionWS = positionWS - _Cascade_Write_PositionWS;
	return offsetPositionWS * _Cascade_Write_SizeInverse + 0.5;
}


RWTexture3D<float3> _Cascade_Write_Emission : register(u1);
RWTexture3D<float4> _Cascade_Write_Transmittance : register(u2);


void WriteRadainceCascadeProbe(float3 emission, float3 transmittance, float3 positionCascade, float3 probePosition, int index) {
	float3 offset = positionCascade - probePosition;
	[branch]if (any(abs(offset) * (float)CASCADE_INDEX_TO_PROBE_RESOLUTION(index) >= float3(1,1,1) * 0.25)) {
		float distance = length(offset) * _Cascade_Write_Size;

		float3 cubeNormal = normalize(offset);
		float2 cubemapFace;	
		float2 cubemapUV;
		float3 probePositionRotated;

		NormalToCascadeCubemapFaceUVCoordinate(cubeNormal, probePosition, cubemapFace, cubemapUV, probePositionRotated);
		float3 texturePosition = COMBINE_CASCADE_COORDINATES(probePositionRotated, cubemapFace, cubemapUV, index);

		uint3 pixelPosition = (uint3)(texturePosition * (float3)TEXTURE_SIZE);

		float4 currentTransmittance = _Cascade_Write_Transmittance[pixelPosition];																									
		float3 currentEmission = _Cascade_Write_Emission[pixelPosition];
		emission = currentTransmittance.a > distance ? (emission + currentEmission * transmittance.rgb) : (emission * currentTransmittance.rgb + currentEmission);
		_Cascade_Write_Emission[pixelPosition] = emission;																															
		_Cascade_Write_Transmittance[pixelPosition] = float4(transmittance.rgb * currentTransmittance.rgb, min(distance, currentTransmittance.a));
	}
}							

/////////////////////////////////////////////////////////////////////////////////////////////////////
#define WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, index)										\
{																													\
float3 probeSize = CASCADE_INDEX_TO_PROBE_UNIT_SIZE(index);															\
float3 halfProbeSize = probeSize / 2.0;																				\
float3 pixelPositionCascade = (positionCascade - halfProbeSize) * CASCADE_INDEX_TO_PROBE_RESOLUTION(index);			\
																													\
float3 pMin = floor(pixelPositionCascade) / (float)CASCADE_INDEX_TO_PROBE_RESOLUTION(index);						\
pMin = max(float3(0,0,0), pMin);																					\
float3 pMax = ceil(pixelPositionCascade) / (float)CASCADE_INDEX_TO_PROBE_RESOLUTION(index);							\
pMax = min(float3(1,1,1) - probeSize, pMax);																		\
pMin += halfProbeSize;																									\
pMax += halfProbeSize;																									\
																													\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMin.x, pMin.y, pMin.z), index);		\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMax.x, pMin.y, pMin.z), index);		\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMin.x, pMin.y, pMax.z), index);		\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMax.x, pMin.y, pMax.z), index);		\
																												\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMin.x, pMax.y, pMin.z), index);		\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMax.x, pMax.y, pMin.z), index);		\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMin.x, pMax.y, pMax.z), index);		\
WriteRadainceCascadeProbe(emission, transmittance, positionCascade, float3(pMax.x, pMax.y, pMax.z), index);	}	\
/////////////////////////////////////////////////////////////////////////////////////////////////////



void WriteRadiance(float3 emission, float3 transmittance, float3 positionWS) {

	float3 positionCascade = saturate(WorldToWriteCascade(positionWS));
	WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, 0);
	WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, 1);
	WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, 2);
	WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, 3);
	WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, 4);
	WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, 5);
	WRITE_RADIANCE_CASCADE(emission, transmittance, positionCascade, 6);
}
