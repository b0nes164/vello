static const uint3 gl_WorkGroupSize = uint3(512u, 1u, 1u);

globallycoherent RWByteAddressBuffer _23 : register(u2, space0);
ByteAddressBuffer _68 : register(t0, space0);
RWByteAddressBuffer _301 : register(u1, space0);

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
    uint offset = (WaveGetLaneIndex() + (((gl_LocalInvocationID.x / WaveGetLaneCount()) * WaveGetLaneCount()) * 4u)) + (part_id * 2048u);
    uint4 t_scan[4];
    for (uint i = 0u; i < 4u; i++)
    {
        t_scan[i] = _68.Load4(offset * 16 + 0);
        t_scan[i].y += t_scan[i].x;
        t_scan[i].z += t_scan[i].y;
        t_scan[i].w += t_scan[i].z;
        offset += WaveGetLaneCount();
    }
    uint prev = 0u;
    uint highest_lane = WaveGetLaneCount() - 1u;
    for (uint i_1 = 0u; i_1 < 4u; i_1++)
    {
        uint t = WavePrefixSum(t_scan[i_1].w);
        t_scan[i_1] += (t + prev).xxxx;
        prev = WaveReadLaneAt(t_scan[i_1].w, highest_lane);
    }
    if (WaveGetLaneIndex() == 0u)
    {
        s_reduce[gl_LocalInvocationID.x / WaveGetLaneCount()] = prev;
    }
    GroupMemoryBarrierWithGroupSync();
    uint wg_red = 0u;
    if (gl_LocalInvocationID.x < WaveGetLaneCount())
    {
        bool pred = gl_LocalInvocationID.x < (512u / WaveGetLaneCount());
        uint _168;
        if (pred)
        {
            _168 = s_reduce[gl_LocalInvocationID.x];
        }
        else
        {
            _168 = 0u;
        }
        wg_red = WavePrefixSum(_168) + _168;
        if (pred)
        {
            s_reduce[gl_LocalInvocationID.x] = wg_red;
        }
        wg_red = WaveReadLaneAt(wg_red, (512u / WaveGetLaneCount()) - 1u);
    }
    if (gl_LocalInvocationID.x == 0u)
    {
        uint _316;
        _23.InterlockedExchange(part_id * 4 + 4, (wg_red << uint(2)) | uint((part_id != 0u) ? 1 : 2), _316);
    }
    if (part_id != 0u)
    {
        if (gl_LocalInvocationID.x == 0u)
        {
            uint prev_reduction = 0u;
            uint lookback_id = part_id - 1u;
            while (true)
            {
                uint _227;
                _23.InterlockedAdd(lookback_id * 4 + 4, 0, _227);
                uint flag_payload = _227;
                if ((flag_payload & 3u) == 2u)
                {
                    prev_reduction += (flag_payload >> uint(2));
                    uint _317;
                    _23.InterlockedExchange(part_id * 4 + 4, ((wg_red + prev_reduction) << uint(2)) | 2u, _317);
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
    uint _263;
    if ((gl_LocalInvocationID.x / WaveGetLaneCount()) != 0u)
    {
        _263 = s_reduce[(gl_LocalInvocationID.x / WaveGetLaneCount()) - 1u];
    }
    else
    {
        _263 = 0u;
    }
    uint prev_1 = _263 + s_broadcast;
    uint offset_1 = (WaveGetLaneIndex() + (((gl_LocalInvocationID.x / WaveGetLaneCount()) * WaveGetLaneCount()) * 4u)) + (part_id * 2048u);
    for (uint i_2 = 0u; i_2 < 4u; i_2++)
    {
        _301.Store4(offset_1 * 16 + 0, t_scan[i_2] + prev_1.xxxx);
        offset_1 += WaveGetLaneCount();
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    comp_main();
}
