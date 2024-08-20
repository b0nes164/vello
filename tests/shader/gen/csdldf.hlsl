static const uint3 gl_WorkGroupSize = uint3(512u, 1u, 1u);

globallycoherent RWByteAddressBuffer _23 : register(u2, space0);
ByteAddressBuffer _62 : register(t0, space0);
RWByteAddressBuffer _391 : register(u1, space0);

static uint3 gl_LocalInvocationID;
struct SPIRV_Cross_Input
{
    uint3 gl_LocalInvocationID : SV_GroupThreadID;
};

groupshared uint s_broadcast;
groupshared uint s_lock;
groupshared uint s_reduce[512];
groupshared uint s_fallback[512];

void comp_main()
{
    if (gl_LocalInvocationID.x == 0u)
    {
        uint _29;
        _23.InterlockedAdd(0, 1u, _29);
        s_broadcast = _29;
        s_lock = 1u;
    }
    GroupMemoryBarrierWithGroupSync();
    uint part_id = s_broadcast;
    uint red = 0u;
    uint threadOffset = (gl_LocalInvocationID.x * 4u) + (part_id * 2048u);
    uint4 t_scan[4];
    for (uint i = 0u; i < 4u; i++)
    {
        t_scan[i] = _62.Load4((i + threadOffset) * 16 + 0);
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
        _23.InterlockedExchange(part_id * 4 + 4, (red << uint(2)) | uint((part_id != 0u) ? 1 : 2), _406);
    }
    if (part_id != 0u)
    {
        uint prev_reduction = 0u;
        uint lookback_id = part_id - 1u;
        while (s_lock == 1u)
        {
            GroupMemoryBarrierWithGroupSync();
            if (gl_LocalInvocationID.x == 511u)
            {
                uint spin_count = 0u;
                while (spin_count < 4u)
                {
                    uint _194;
                    _23.InterlockedAdd(lookback_id * 4 + 4, 0, _194);
                    uint flag_payload = _194;
                    if ((flag_payload & 3u) > 0u)
                    {
                        prev_reduction += (flag_payload >> uint(2));
                        if ((flag_payload & 3u) == 2u)
                        {
                            _23.InterlockedExchange(part_id * 4 + 4, ((red + prev_reduction) << uint(2)) | 2u, _407);
                            s_broadcast = prev_reduction;
                            s_lock = 0u;
                            break;
                        }
                        if ((flag_payload & 3u) == 1u)
                        {
                            lookback_id--;
                        }
                    }
                    else
                    {
                        spin_count++;
                    }
                }
                if (s_lock == 1u)
                {
                    s_broadcast = lookback_id;
                }
            }
            GroupMemoryBarrierWithGroupSync();
            if (s_lock == 1u)
            {
                uint fallback_id = s_broadcast;
                uint f_end = (fallback_id + 1u) * 2048u;
                uint f_red = 0u;
                uint _249 = gl_LocalInvocationID.x + (fallback_id * 2048u);
                for (uint i_2 = _249; i_2 < f_end; i_2 += 512u)
                {
                    uint4 t = _62.Load4(i_2 * 16 + 0);
                    f_red += (((t.x + t.y) + t.z) + t.w);
                }
                s_fallback[gl_LocalInvocationID.x] = f_red;
                for (uint i_3 = 0u; i_3 < 9u; i_3++)
                {
                    GroupMemoryBarrierWithGroupSync();
                    if (gl_LocalInvocationID.x >= (1u << i_3))
                    {
                        f_red += s_fallback[gl_LocalInvocationID.x - (1u << i_3)];
                    }
                    GroupMemoryBarrierWithGroupSync();
                    s_fallback[gl_LocalInvocationID.x] = f_red;
                }
                if (gl_LocalInvocationID.x == 511u)
                {
                    uint flag_payload_1 = (f_red << uint(2)) | uint((fallback_id != 0u) ? 1 : 2);
                    uint _329;
                    _23.InterlockedCompareExchange(fallback_id * 4 + 4, 0u, flag_payload_1, _329);
                    uint prev_payload = _329;
                    if (prev_payload == 0u)
                    {
                        prev_reduction += f_red;
                    }
                    else
                    {
                        prev_reduction += (prev_payload >> uint(2));
                    }
                    bool _343 = fallback_id == 0u;
                    bool _350;
                    if (!_343)
                    {
                        _350 = (prev_payload & 3u) == 2u;
                    }
                    else
                    {
                        _350 = _343;
                    }
                    if (_350)
                    {
                        _23.InterlockedExchange(part_id * 4 + 4, ((red + prev_reduction) << uint(2)) | 2u, _408);
                        s_broadcast = prev_reduction;
                        s_lock = 0u;
                    }
                    else
                    {
                        lookback_id--;
                    }
                }
                GroupMemoryBarrierWithGroupSync();
            }
        }
    }
    GroupMemoryBarrierWithGroupSync();
    uint _368;
    if (gl_LocalInvocationID.x != 0u)
    {
        _368 = s_reduce[gl_LocalInvocationID.x - 1u];
    }
    else
    {
        _368 = 0u;
    }
    uint prev = _368 + s_broadcast;
    for (uint i_4 = 0u; i_4 < 4u; i_4++)
    {
        _391.Store4((i_4 + threadOffset) * 16 + 0, t_scan[i_4] + WaveActiveSum(prev).xxxx);
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    comp_main();
}
