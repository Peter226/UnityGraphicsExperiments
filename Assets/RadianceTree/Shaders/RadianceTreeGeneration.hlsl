#include "./RadianceTreeLighting.hlsl"

float3 _Tree_Write_PositionWS;
float _Tree_Write_Size;
float _Tree_Write_SizeInverse;

float3 WorldToWriteTree(float3 positionWS) {
	float3 offsetPositionWS = positionWS - _Tree_Write_PositionWS;
	return offsetPositionWS * _Tree_Write_SizeInverse + 0.5;
}

RWStructuredBuffer<TreeNodeCounter> _Tree_Node_Counter : register(u1);
RWStructuredBuffer<EmissionTreeNode> _Tree_Write_Emission : register(u2);
RWStructuredBuffer<EmissionCubemapTreeNode> _Tree_Write_Emission_Cubemap : register(u3);
RWStructuredBuffer<TransmittanceTreeNode> _Tree_Write_Transmittance : register(u4);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define FETCH_NODE(TREE_NAME)																													\
int FetchNode_##TREE_NAME(float3 position, uint nodeDepth){																						\
	int childIndex = 0;																															\
	float3 nodePosition = position;																												\
	float nodeSize = 1.0;																														\
	int childBuffer = -1;																														\
	float3 currentPosition = float3(0.5,0.5,0.5);																								\
	for (uint d = 0; d < nodeDepth;d++) {																										\
																																				\
		int parentIndex = childIndex;																											\
																																				\
		if (childBuffer < 0) {																													\
			InterlockedAdd(_Tree_Node_Counter[0].counter##TREE_NAME, 2 * 2 * 2, childBuffer);													\
		}																																		\
																																				\
		InterlockedCompareExchange(_Tree_Write_##TREE_NAME[parentIndex].childrenStartIndex, -1, childBuffer, childIndex);						\
		if (childIndex < 0) {																													\
			[unroll] for (int x = 0; x < 2;x++) {																								\
				[unroll] for (int y = 0; y < 2; y++) {																							\
					[unroll] for (int z = 0; z < 2; z++) {																						\
						int index = childBuffer + x + y * 2 + z * 4;																			\
						_Tree_Write_##TREE_NAME[index].parentIndex = parentIndex;																\
						_Tree_Write_##TREE_NAME[index].treeDepth = d + 1;																		\
						_Tree_Write_##TREE_NAME[index].nodePosition = currentPosition + (nodeSize * 0.5 * (float3(x, y, z) - 0.5));				\
					}																															\
				}																																\
			}																																	\
			childIndex = childBuffer;																											\
			childBuffer = -1;																													\
		}																																		\
																																				\
		bool3 nodeLocation = nodePosition > 0.5;																								\
		int selectedChildOffset = 0;																											\
		selectedChildOffset += nodeLocation.x ? 1 : 0;																							\	
		selectedChildOffset += nodeLocation.y ? 2 : 0;																							\
		selectedChildOffset += nodeLocation.z ? 4 : 0;																							\
																																				\
		childIndex += selectedChildOffset;																										\
		nodePosition = (nodePosition - nodeLocation * 0.5) * 2.0;																				\
		currentPosition += nodeSize * 0.5 * (nodeLocation - 0.5);																				\
		nodeSize *= 0.5;																														\
	}																																			\
	return childIndex;																															\
}																																				\
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

FETCH_NODE(Transmittance)
FETCH_NODE(Emission)

void WriteTransmittance(float3 transmittance, float3 positionWS) {

	float3 treePosition = saturate(WorldToWriteTree(positionWS));
	int transmittanceNode = FetchNode_Transmittance(treePosition, 8);
	_Tree_Write_Transmittance[transmittanceNode].transmittance = float4(transmittance, 1.0);
}

void WriteEmission(float3 emission, float3 positionWS, int cubemapSide) {
	float3 treePosition = saturate(WorldToWriteTree(positionWS));
	int emissionNode = FetchNode_Emission(treePosition, 8);
}