
float3 _Tree_Read_PositionWS;
float _Tree_Read_Size;
float _Tree_Read_SizeInverse;

/////////////////////////////
#define TREE_NODE_STRUCT    \
int parentIndex;            \
int childrenStartIndex;     \
int treeDepth;              \
float3 nodePosition;    	\
/////////////////////////////


struct EmissionTreeNode
{
    TREE_NODE_STRUCT

    int cubemapIndex;
};


struct EmissionCubemapTreeNode
{
    TREE_NODE_STRUCT

    float3 emission;
};

struct TransmittanceTreeNode
{
    TREE_NODE_STRUCT

    float4 transmittance;
};

struct TreeNodeCounter
{
    int counterEmission;
    int counterCubemapEmission;
    int counterTransmittance;
};


StructuredBuffer<EmissionTreeNode> _Tree_Read_Emission;
StructuredBuffer<EmissionCubemapTreeNode> _Tree_Read_Emission_Cubemap;
StructuredBuffer<TransmittanceTreeNode> _Tree_Read_Transmittance;

half4 RadiancePBR(half3 albedo, float3 positionWS, half3 normalWS) {
	return half4(0,0,0,0);
}