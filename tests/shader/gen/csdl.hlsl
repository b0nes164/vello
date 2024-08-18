static const uint3 gl_WorkGroupSize = uint3(512u, 1u, 1u);

globallycoherent RWByteAddressBuffer _23 : register(u2);
ByteAddressBuffer _61 : register(t0);
RWByteAddressBuffer _241 : register(u1);

static uint3 gl_LocalInvocationID;
struct SPIRV_Cross_Input
{
    uint3 gl_LocalInvocationID : SV_GroupThreadID;
};

groupshared uint s_broadcast;
groupshared uint s_reduce[512];

void comp_main()
{
    if (gl_LocalInvocationID.x == 0u)
    {
        uint _29;
        _23.InterlockedAdd(0, 1u, _29);
        s_broadcast = _29;
    }
    GroupMemoryBarrierWithGroupSync();
    uint part_id = s_broadcast;
    uint red = 0u;
    uint threadOffset = (gl_LocalInvocationID.x * 4u) + (part_id * 2048u);
    uint4 t_scan[4];
    for (uint i = 0u; i < 4u; i++)
    {
        t_scan[i] = _61.Load4((i + threadOffset) * 16 + 0);
        t_scan[i].x += red;
        t_scan[i].y += t_scan[i].x;
        t_scan[i].z += t_scan[i].y;
        t_scan[i].w += t_scan[i].z;
        red = t_scan[i].w;
    }
    s_reduce[gl_LocalInvocationID.x] = red;
    for (uint i_1 = 0u; i_1 < 9u; i_1++)
    {
        GroupMemoryBarrierWithGroupSync();
        if (gl_LocalInvocationID.x >= (1u << i_1))
        {
            red += s_reduce[gl_LocalInvocationID.x - (1u << i_1)];
        }
        GroupMemoryBarrierWithGroupSync();
        s_reduce[gl_LocalInvocationID.x] = red;
    }
    if (gl_LocalInvocationID.x == 511u)
    {
        uint _255;
        _23.InterlockedExchange(part_id * 4 + 4, (red << uint(2)) | uint((part_id != 0u) ? 1 : 2), _255);
    }
    if (part_id != 0u)
    {
        if (gl_LocalInvocationID.x == 511u)
        {
            uint prev_reduction = 0u;
            uint lookback_id = part_id - 1u;
            while (true)
            {
                uint _184;
                _23.InterlockedAdd(lookback_id * 4 + 4, 0, _184);
                uint flag_payload = _184;
                if ((flag_payload & 3u) == 2u)
                {
                    prev_reduction += (flag_payload >> uint(2));
                    uint _256;
                    _23.InterlockedExchange(part_id * 4 + 4, ((red + prev_reduction) << uint(2)) | 2u, _256);
                    s_broadcast = prev_reduction;
                    break;
                }
                if ((flag_payload & 3u) == 1u)
                {
                    prev_reduction += (flag_payload >> uint(2));
                    lookback_id--;
                }
            }
        }
    }
    GroupMemoryBarrierWithGroupSync();
    uint _218;
    if (gl_LocalInvocationID.x != 0u)
    {
        _218 = s_reduce[gl_LocalInvocationID.x - 1u];
    }
    else
    {
        _218 = 0u;
    }
    uint prev = _218 + s_broadcast;
    for (uint i_2 = 0u; i_2 < 4u; i_2++)
    {
        _241.Store4((i_2 + threadOffset) * 16 + 0, t_scan[i_2] + prev.xxxx);
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    comp_main();
}
