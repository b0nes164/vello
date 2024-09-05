struct Monoid
{
    uint element;
};

struct State
{
    uint local_0;
    uint local_1;
    uint global_0;
    uint global_1;
};

static const Monoid _201 = { 0u };

globallycoherent RWByteAddressBuffer _74 : register(u2, space0);
ByteAddressBuffer _98 : register(t0, space0);
RWByteAddressBuffer _420 : register(u1, space0);

static uint3 gl_LocalInvocationID;
struct SPIRV_Cross_Input
{
    uint3 gl_LocalInvocationID : SV_GroupThreadID;
};

groupshared uint sh_part_ix;
groupshared Monoid sh_scratch[512];
groupshared uint2 sh_local_split;
groupshared uint2 sh_global_split;
groupshared Monoid sh_prefix;

Monoid combine_monoid(Monoid a, Monoid b)
{
    Monoid _32 = { a.element + b.element };
    return _32;
}

uint2 split_monoid(Monoid m)
{
    return uint2(m.element & 65535u, m.element >> uint(16));
}

Monoid join_monoid(uint2 pieces)
{
    Monoid _55 = { (pieces.x & 65535u) + (pieces.y << uint(16)) };
    return _55;
}

void comp_main()
{
    if (gl_LocalInvocationID.x == 0u)
    {
        uint _77;
        _74.InterlockedAdd(0, 1u, _77);
        sh_part_ix = _77;
    }
    GroupMemoryBarrierWithGroupSync();
    uint part_ix = sh_part_ix;
    uint ix = (part_ix * 8192u) + (gl_LocalInvocationID.x * 16u);
    Monoid _102;
    _102.element = _98.Load(ix * 4 + 0);
    Monoid local[16];
    Monoid _104;
    _104.element = _102.element;
    local[0] = _104;
    for (uint i = 1u; i < 16u; i++)
    {
        Monoid param = local[i - 1u];
        Monoid _124;
        _124.element = _98.Load((ix + i) * 4 + 0);
        Monoid _125;
        _125.element = _124.element;
        Monoid param_1 = _125;
        local[i] = combine_monoid(param, param_1);
    }
    Monoid agg = local[15];
    sh_scratch[gl_LocalInvocationID.x] = agg;
    for (uint i_1 = 0u; i_1 < 9u; i_1++)
    {
        GroupMemoryBarrierWithGroupSync();
        if (gl_LocalInvocationID.x >= (1u << i_1))
        {
            Monoid other = sh_scratch[gl_LocalInvocationID.x - (1u << i_1)];
            Monoid param_2 = other;
            Monoid param_3 = agg;
            agg = combine_monoid(param_2, param_3);
        }
        GroupMemoryBarrierWithGroupSync();
        sh_scratch[gl_LocalInvocationID.x] = agg;
    }
    if (gl_LocalInvocationID.x == 511u)
    {
        Monoid param_4 = agg;
        uint2 split_agg = split_monoid(param_4);
        _74.InterlockedExchange(part_ix * 16 + 4, split_agg.x | 2147483648u, _434);
        _74.InterlockedExchange(part_ix * 16 + 8, split_agg.y | 2147483648u, _435);
    }
    Monoid exclusive = _201;
    if (part_ix != 0u)
    {
        uint look_back_ix = part_ix - 1u;
        uint their_ix = 0u;
        Monoid their_agg;
        while (true)
        {
            if (gl_LocalInvocationID.x == 511u)
            {
                uint _224;
                _74.InterlockedAdd(look_back_ix * 16 + 4, 0, _224);
                uint sc_0 = _224;
                uint _228;
                _74.InterlockedAdd(look_back_ix * 16 + 8, 0, _228);
                uint sc_1 = _228;
                sh_local_split = uint2(sc_0, sc_1);
            }
            GroupMemoryBarrierWithGroupSync();
            uint2 split = sh_local_split;
            if (((split.x & split.y) & 2147483648u) != 0u)
            {
                uint2 param_5 = split;
                their_agg = join_monoid(param_5);
                if (look_back_ix != 0u)
                {
                    if (gl_LocalInvocationID.x == 511u)
                    {
                        uint _262;
                        _74.InterlockedAdd(look_back_ix * 16 + 12, 0, _262);
                        uint sc_0_1 = _262;
                        uint _267;
                        _74.InterlockedAdd(look_back_ix * 16 + 16, 0, _267);
                        uint sc_1_1 = _267;
                        sh_global_split = uint2(sc_0_1, sc_1_1);
                    }
                    GroupMemoryBarrierWithGroupSync();
                    split = sh_global_split;
                    if (((split.x & split.y) & 2147483648u) != 0u)
                    {
                        uint2 param_6 = split;
                        their_agg = join_monoid(param_6);
                    }
                }
                Monoid param_7 = their_agg;
                Monoid param_8 = exclusive;
                exclusive = combine_monoid(param_7, param_8);
                if (((split.x & split.y) & 2147483648u) != 0u)
                {
                    break;
                }
                else
                {
                    look_back_ix--;
                    their_ix = 0u;
                    continue;
                }
            }
            if (gl_LocalInvocationID.x == 511u)
            {
                Monoid _315;
                _315.element = _98.Load(((look_back_ix * 8192u) + their_ix) * 4 + 0);
                Monoid _316;
                _316.element = _315.element;
                Monoid m = _316;
                if (their_ix == 0u)
                {
                    their_agg = m;
                }
                else
                {
                    Monoid param_9 = their_agg;
                    Monoid param_10 = m;
                    their_agg = combine_monoid(param_9, param_10);
                }
                if (their_ix == 8191u)
                {
                    Monoid param_11 = their_agg;
                    Monoid param_12 = exclusive;
                    exclusive = combine_monoid(param_11, param_12);
                }
            }
            their_ix++;
            if (their_ix == 8192u)
            {
                if (look_back_ix == 0u)
                {
                    break;
                }
                look_back_ix--;
                their_ix = 0u;
            }
            GroupMemoryBarrierWithGroupSync();
        }
        if (gl_LocalInvocationID.x == 511u)
        {
            Monoid param_13 = exclusive;
            Monoid param_14 = agg;
            Monoid inclusive_prefix = combine_monoid(param_13, param_14);
            sh_prefix = exclusive;
            Monoid param_15 = inclusive_prefix;
            uint2 split_inclusive = split_monoid(param_15);
            _74.InterlockedExchange(part_ix * 16 + 12, split_inclusive.x | 2147483648u, _438);
            _74.InterlockedExchange(part_ix * 16 + 16, split_inclusive.y | 2147483648u, _439);
        }
    }
    GroupMemoryBarrierWithGroupSync();
    if (part_ix != 0u)
    {
        exclusive = sh_prefix;
    }
    Monoid row = exclusive;
    if (gl_LocalInvocationID.x > 0u)
    {
        Monoid other_1 = sh_scratch[gl_LocalInvocationID.x - 1u];
        Monoid param_16 = row;
        Monoid param_17 = other_1;
        row = combine_monoid(param_16, param_17);
    }
    for (uint i_2 = 0u; i_2 < 16u; i_2++)
    {
        Monoid param_18 = row;
        Monoid param_19 = local[i_2];
        Monoid m_1 = combine_monoid(param_18, param_19);
        uint _423 = ix + i_2;
        Monoid _426;
        _426.element = m_1.element;
        _420.Store(_423 * 4 + 0, _426.element);
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    comp_main();
}
