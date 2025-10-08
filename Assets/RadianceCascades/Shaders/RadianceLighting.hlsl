
float3 _Cascade_Read_PositionWS;
float _Cascade_Read_Size;
float _Cascade_Read_SizeInverse;

#define CASCADE_COUNT 7;

TYPED_TEXTURE3D(float3, _Cascade_Read_Emission);
SAMPLER(sampler_Cascade_Read_Emission);

TYPED_TEXTURE3D(float4, _Cascade_Read_Transmittance);
SAMPLER(sampler_Cascade_Read_Transmittance);

#define TEXTURE_SIZE uint3(192, 128, 127)

#define CASCADE_INDEX_TO_CUBEMAP_RESOLUTION(index) \
(1 << index)

#define CASCADE_INDEX_TO_PROBE_RESOLUTION(index) \
((1 << 6) / (1 << index))

#define CASCADE_INDEX_TO_PROBE_UNIT_SIZE(index) \
(1.0 / (float)CASCADE_INDEX_TO_PROBE_RESOLUTION(index))


uint GetCascadeTextureIndexOffset(int index) {
	uint offset = 0;
	offset += index > 0 ? CASCADE_INDEX_TO_PROBE_RESOLUTION(0) : 0;
	offset += index > 1 ? CASCADE_INDEX_TO_PROBE_RESOLUTION(1) : 0;
	offset += index > 2 ? CASCADE_INDEX_TO_PROBE_RESOLUTION(2) : 0;
	offset += index > 3 ? CASCADE_INDEX_TO_PROBE_RESOLUTION(3) : 0;
	offset += index > 4 ? CASCADE_INDEX_TO_PROBE_RESOLUTION(4) : 0;
	offset += index > 5 ? CASCADE_INDEX_TO_PROBE_RESOLUTION(5) : 0;
	return offset;
}

uint3 GetCascadeTextureSize(int index) {
	uint probeResolution = CASCADE_INDEX_TO_PROBE_RESOLUTION(index);
	uint cubemapResolution = CASCADE_INDEX_TO_CUBEMAP_RESOLUTION(index);
	return uint3(probeResolution * cubemapResolution * 3, probeResolution * cubemapResolution * 2, probeResolution);
}


float3 CombineCascadeCoordinates(float3 positionCascade, float2 cubemapFace, float2 cubemapUV, float cubemapResolution, float cubemapResolutionInverse, int index) {
	float2 roundedCubemapUV = floor(cubemapUV * cubemapResolution) * cubemapResolutionInverse;
	float2 faceScale = float2(1.0 / 3.0, 1.0 / 2.0);
	float2 cubemapCoordinate = cubemapFace + roundedCubemapUV * faceScale;
	float3 combinedCoordinate = positionCascade;
	combinedCoordinate.xy *= faceScale * cubemapResolutionInverse;
	combinedCoordinate.xy += cubemapCoordinate;
	combinedCoordinate.z = combinedCoordinate.z * (float)(GetCascadeTextureSize(index).z) / (float)(TEXTURE_SIZE.z) + (float)GetCascadeTextureIndexOffset(index) / (float)(TEXTURE_SIZE.z);
	return combinedCoordinate;
}

#define COMBINE_CASCADE_COORDINATES(positionCascade, cubemapFace, cubemapUV, index) \
CombineCascadeCoordinates(positionCascade, cubemapFace, cubemapUV, CASCADE_INDEX_TO_CUBEMAP_RESOLUTION(index), 1.0 / (float)CASCADE_INDEX_TO_CUBEMAP_RESOLUTION(index), index)

void SampleRadianceCascadeRay(float3 positionCascade, float2 cubemapFace, float2 cubemapUV, int index, out float3 emission, out float4 transmittance) {
	float3 textureCoordinate = COMBINE_CASCADE_COORDINATES(positionCascade, cubemapFace, cubemapUV, index);
	textureCoordinate.z += (float)CASCADE_INDEX_TO_PROBE_UNIT_SIZE(index) * ((float)CASCADE_INDEX_TO_PROBE_RESOLUTION(index) / (float)TEXTURE_SIZE.z) * 0.5;
	emission = SAMPLE_TEXTURE3D(_Cascade_Read_Emission, sampler_Cascade_Read_Emission, textureCoordinate);
	transmittance = SAMPLE_TEXTURE3D(_Cascade_Read_Transmittance, sampler_Cascade_Read_Transmittance, textureCoordinate);
}


void NormalToCascadeCubemapFaceUVCoordinate(float3 normal, float3 positionCascade, out float2 face, out float2 uv, out float3 positionCascadeRotated) {
	float absX = abs(normal.x);
	float absY = abs(normal.y);
	float absZ = abs(normal.z);
	float largest = max(absX, max(absY, absZ));
	float3 cubeRay = normal / largest * 0.5 + 0.5;

	if (absX >= absY && absX > absZ) {
		face = float2(0.0, normal.x >= 0.0 ? 0.0 : 0.5);
		uv = cubeRay.yz;
		positionCascadeRotated = positionCascade.zyx;
	}
	else if (absY >= absZ) {
		face = float2(1.0 / 3.0, normal.y >= 0.0 ? 0.0 : 0.5);
		uv = cubeRay.xz;
		positionCascadeRotated = positionCascade.xzy;
	}
	else {
		face = float2(2.0 / 3.0, normal.z >= 0.0 ? 0.0 : 0.5);
		uv = cubeRay.xy;
		positionCascadeRotated = positionCascade;
	}
}

float3 WorldToReadCascade(float3 positionWS) {
	float3 offsetPositionWS = positionWS - _Cascade_Read_PositionWS;
	return offsetPositionWS * _Cascade_Read_SizeInverse + 0.5;
}

void CombineRadiance(inout float3 nearEmission, inout float4 nearTransmittance, float3 farEmission, float4 farTransmittance) {
	nearEmission = nearEmission + (nearTransmittance.rgb * farEmission);
	nearTransmittance = nearTransmittance * farTransmittance;
}


void SampleRadianceRay(float3 positionCascade, float2 cubemapFace, float2 cubemapUV, out float3 emission) {
	float4 transmittance;
	SampleRadianceCascadeRay(positionCascade, cubemapFace, cubemapUV, 0, emission, transmittance);

	float3 newEmission;
	float4 newTransmittance;
	
	SampleRadianceCascadeRay(positionCascade, cubemapFace, cubemapUV, 1, newEmission, newTransmittance);
	CombineRadiance(emission, transmittance, newEmission, newTransmittance);
	[branch] if (all(transmittance <= 0.01)) return;
	
	SampleRadianceCascadeRay(positionCascade, cubemapFace, cubemapUV, 2, newEmission, newTransmittance);
	CombineRadiance(emission, transmittance, newEmission, newTransmittance);
	[branch] if (all(transmittance <= 0.01)) return;

	SampleRadianceCascadeRay(positionCascade, cubemapFace, cubemapUV, 3, newEmission, newTransmittance);
	CombineRadiance(emission, transmittance, newEmission, newTransmittance);
	[branch] if (all(transmittance <= 0.01)) return;

	SampleRadianceCascadeRay(positionCascade, cubemapFace, cubemapUV, 4, newEmission, newTransmittance);
	CombineRadiance(emission, transmittance, newEmission, newTransmittance);
	[branch] if (all(transmittance <= 0.01)) return;

	SampleRadianceCascadeRay(positionCascade, cubemapFace, cubemapUV, 5, newEmission, newTransmittance);
	CombineRadiance(emission, transmittance, newEmission, newTransmittance);
	[branch] if (all(transmittance <= 0.01)) return;

	SampleRadianceCascadeRay(positionCascade, cubemapFace, cubemapUV, 6, newEmission, newTransmittance);
	CombineRadiance(emission, transmittance, newEmission, newTransmittance);
}

half4 RadiancePBR(half3 albedo, float3 positionWS, half3 normalWS) {
	float3 radiance;
	positionWS += normalWS * CASCADE_INDEX_TO_PROBE_UNIT_SIZE(0) * 1.5;
	float3 positionCascade = saturate(WorldToReadCascade(positionWS));
	float2 cubemapFace;
	float2 cubemapUV;
	float3 positionCascadeRotated;
	NormalToCascadeCubemapFaceUVCoordinate(normalWS, positionCascade, cubemapFace, cubemapUV, positionCascadeRotated);
	SampleRadianceRay(positionCascadeRotated, cubemapFace, cubemapUV, radiance);
	return float4(radiance, 1.0) * half4(albedo, 1.0);
}