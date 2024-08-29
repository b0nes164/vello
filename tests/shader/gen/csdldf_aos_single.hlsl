static const uint3 gl_WorkGroupSize = uint3(512u, 1u, 1u);

globallycoherent RWByteAddressBuffer _24 : register(u2, space0);
ByteAddressBuffer _69 : register(t0, space0);
RWByteAddressBuffer _541 : register(u1, space0);

static uint3 gl_LocalInvocationID;
struct SPIRV_Cross_Input
{
    uint3 gl_LocalInvocationID : SV_GroupThreadID;
};

groupshared uint s_broadcast;
groupshared uint s_lock;
groupshared uint s_reduce[128];
groupshared uint s_stateBroadcast[4];
groupshared uint s_fallback[128];

void comp_main()
{
    if (gl_LocalInvocationID.x == 0u)
    {
        uint _30;
        _24.InterlockedAdd(0, 1u, _30);
        s_broadcast = _30;
        s_lock = 0u;
    }
    GroupMemoryBarrierWithGroupSync();
    uint part_id = s_broadcast;
    uint offset = (WaveGetLaneIndex() + (((gl_LocalInvocationID.x / WaveGetLaneCount()) * WaveGetLaneCount()) * 4u)) + (part_id * 2048u);
    uint4 t_scan[4];
    for (uint i = 0u; i < 4u; i++)
    {
        t_scan[i] = _69.Load4(offset * 16 + 0);
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
        uint _170;
        if (pred)
        {
            _170 = s_reduce[gl_LocalInvocationID.x];
        }
        else
        {
            _170 = 0u;
        }
        wg_red = WavePrefixSum(_170) + _170;
        if (pred)
        {
            s_reduce[gl_LocalInvocationID.x] = wg_red;
        }
        wg_red = WaveReadLaneAt(wg_red, (512u / WaveGetLaneCount()) - 1u);
    }
    if (gl_LocalInvocationID.x == 0u)
    {
        if (part_id != 0u)
        {
            _24.InterlockedExchange(part_id * 16 + 16, (wg_red << uint(2)) | 1u, _557);
            _24.InterlockedExchange(part_id * 16 + 20, (wg_red << uint(2)) | 1u, _558);
            _24.InterlockedExchange(part_id * 16 + 24, (wg_red << uint(2)) | 1u, _559);
            _24.InterlockedExchange(part_id * 16 + 28, (wg_red << uint(2)) | 1u, _560);
        }
        else
        {
            _24.InterlockedExchange(part_id * 16 + 16, (wg_red << uint(2)) | 2u, _561);
            _24.InterlockedExchange(part_id * 16 + 20, (wg_red << uint(2)) | 2u, _562);
            _24.InterlockedExchange(part_id * 16 + 24, (wg_red << uint(2)) | 2u, _563);
            _24.InterlockedExchange(part_id * 16 + 28, (wg_red << uint(2)) | 2u, _564);
        }
    }
    if (part_id != 0u)
    {
        uint lookback_id = part_id - 1u;
        uint prev_reduction_0 = 0u;
        uint prev_reduction_1 = 0u;
        uint prev_reduction_2 = 0u;
        uint prev_reduction_3 = 0u;
        bool s_0_inc = false;
        bool s_1_inc = false;
        bool s_2_inc = false;
        bool s_3_inc = false;
        uint flag_payload;
        uint flag_value;
        while (s_lock == 0u)
        {
            GroupMemoryBarrierWithGroupSync();
            bool s_0_red = false;
            bool s_1_red = false;
            bool s_2_red = false;
            bool s_3_red = false;
            if (gl_LocalInvocationID.x == 0u)
            {
                uint spin_count = 0u;
                while (spin_count < 1000u)
                {
                    if ((!s_0_inc) || (!s_0_red))
                    {
                        uint _294;
                        _24.InterlockedAdd(lookback_id * 16 + 16, 0, _294);
                        flag_payload = _294;
                        flag_value = flag_payload & 3u;
                        if (flag_value == 1u)
                        {
                            spin_count = 0u;
                            prev_reduction_0 += (flag_payload >> uint(2));
                            s_0_red = true;
                        }
                        else
                        {
                            if (flag_value == 2u)
                            {
                                spin_count = 0u;
                                prev_reduction_0 += (flag_payload >> uint(2));
                                _24.InterlockedExchange(part_id * 16 + 16, ((wg_red + prev_reduction_0) << uint(2)) | 2u, _565);
                                s_stateBroadcast[0] = prev_reduction_0;
                                s_0_inc = true;
                            }
                        }
                    }
                    if ((!s_1_inc) || (!s_1_red))
                    {
                        uint _337;
                        _24.InterlockedAdd(lookback_id * 16 + 20, 0, _337);
                        flag_payload = _337;
                        flag_value = flag_payload & 3u;
                        if (flag_value == 1u)
                        {
                            spin_count = 0u;
                            prev_reduction_1 += (flag_payload >> uint(2));
                            s_1_red = true;
                        }
                        else
                        {
                            if (flag_value == 2u)
                            {
                                spin_count = 0u;
                                prev_reduction_1 += (flag_payload >> uint(2));
                                _24.InterlockedExchange(part_id * 16 + 20, ((wg_red + prev_reduction_1) << uint(2)) | 2u, _566);
                                s_stateBroadcast[1] = prev_reduction_1;
                                s_1_inc = true;
                            }
                        }
                    }
                    if ((!s_2_inc) || (!s_2_red))
                    {
                        uint _375;
                        _24.InterlockedAdd(lookback_id * 16 + 24, 0, _375);
                        flag_payload = _375;
                        flag_value = flag_payload & 3u;
                        if (flag_value == 1u)
                        {
                            spin_count = 0u;
                            prev_reduction_2 += (flag_payload >> uint(2));
                            s_2_red = true;
                        }
                        else
                        {
                            if (flag_value == 2u)
                            {
                                spin_count = 0u;
                                prev_reduction_2 += (flag_payload >> uint(2));
                                _24.InterlockedExchange(part_id * 16 + 24, ((wg_red + prev_reduction_2) << uint(2)) | 2u, _567);
                                s_stateBroadcast[2] = prev_reduction_2;
                                s_2_inc = true;
                            }
                        }
                    }
                    if ((!s_3_inc) || (!s_3_red))
                    {
                        uint _413;
                        _24.InterlockedAdd(lookback_id * 16 + 28, 0, _413);
                        flag_payload = _413;
                        flag_value = flag_payload & 3u;
                        if (flag_value == 1u)
                        {
                            spin_count = 0u;
                            prev_reduction_3 += (flag_payload >> uint(2));
                            s_3_red = true;
                        }
                        else
                        {
                            if (flag_value == 2u)
                            {
                                spin_count = 0u;
                                prev_reduction_3 += (flag_payload >> uint(2));
                                _24.InterlockedExchange(part_id * 16 + 28, ((wg_red + prev_reduction_3) << uint(2)) | 2u, _568);
                                s_stateBroadcast[3] = prev_reduction_3;
                                s_3_inc = true;
                            }
                        }
                    }
                    bool _445 = s_0_inc || s_0_red;
                    bool _451;
                    if (_445)
                    {
                        _451 = s_1_inc || s_1_red;
                    }
                    else
                    {
                        _451 = _445;
                    }
                    bool _457;
                    if (_451)
                    {
                        _457 = s_2_inc || s_2_red;
                    }
                    else
                    {
                        _457 = _451;
                    }
                    bool _463;
                    if (_457)
                    {
                        _463 = s_3_inc || s_3_red;
                    }
                    else
                    {
                        _463 = _457;
                    }
                    if (_463)
                    {
                        if (((s_0_inc && s_1_inc) && s_2_inc) && s_3_inc)
                        {
                            s_lock = 1u;
                            break;
                        }
                        else
                        {
                            lookback_id--;
                        }
                    }
                    else
                    {
                        spin_count++;
                    }
                }
                if (s_lock == 0u)
                {
                    s_broadcast = lookback_id;
                }
            }
            GroupMemoryBarrierWithGroupSync();
        }
    }
    GroupMemoryBarrierWithGroupSync();
    uint _490;
    if (part_id != 0u)
    {
        _490 = s_stateBroadcast[0];
    }
    else
    {
        _490 = 0u;
    }
    uint regenerateState = _490;
    uint _503;
    if ((gl_LocalInvocationID.x / WaveGetLaneCount()) != 0u)
    {
        _503 = s_reduce[(gl_LocalInvocationID.x / WaveGetLaneCount()) - 1u];
    }
    else
    {
        _503 = 0u;
    }
    uint prev_1 = _503 + regenerateState;
    uint offset_1 = (WaveGetLaneIndex() + (((gl_LocalInvocationID.x / WaveGetLaneCount()) * WaveGetLaneCount()) * 4u)) + (part_id * 2048u);
    for (uint i_2 = 0u; i_2 < 4u; i_2++)
    {
        _541.Store4(offset_1 * 16 + 0, t_scan[i_2] + prev_1.xxxx);
        offset_1 += WaveGetLaneCount();
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    comp_main();
}
