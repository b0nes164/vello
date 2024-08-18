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

static const uint3 gl_WorkGroupSize = uint3(512u, 1u, 1u);

static const Monoid _203 = { 0u };

globallycoherent RWByteAddressBuffer _74 : register(u2);
ByteAddressBuffer _98 : register(t0);
RWByteAddressBuffer _423 : register(u1);

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
    local[0].element = _102.element;
    Monoid param_1;
    for (uint i = 1u; i < 16u; i++)
    {
        Monoid param = local[i - 1u];
        Monoid _125;
        _125.element = _98.Load((ix + i) * 4 + 0);
        param_1.element = _125.element;
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
        uint _434;
        _74.InterlockedExchange(part_ix * 16 + 4, split_agg.x | 2147483648u, _434);
        uint _435;
        _74.InterlockedExchange(part_ix * 16 + 8, split_agg.y | 2147483648u, _435);
    }
    Monoid exclusive = _203;
    if (part_ix != 0u)
    {
        uint look_back_ix = part_ix - 1u;
        uint their_ix = 0u;
        Monoid their_agg;
        Monoid m;
        while (true)
        {
            if (gl_LocalInvocationID.x == 511u)
            {
                uint _226;
                _74.InterlockedAdd(look_back_ix * 16 + 4, 0, _226);
                uint sc_0 = _226;
                uint _230;
                _74.InterlockedAdd(look_back_ix * 16 + 8, 0, _230);
                uint sc_1 = _230;
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
                        uint _264;
                        _74.InterlockedAdd(look_back_ix * 16 + 12, 0, _264);
                        uint sc_0_1 = _264;
                        uint _269;
                        _74.InterlockedAdd(look_back_ix * 16 + 16, 0, _269);
                        uint sc_1_1 = _269;
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
                Monoid _317;
                _317.element = _98.Load(((look_back_ix * 8192u) + their_ix) * 4 + 0);
                m.element = _317.element;
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
            uint _436;
            _74.InterlockedExchange(part_ix * 16 + 12, split_inclusive.x | 2147483648u, _436);
            uint _437;
            _74.InterlockedExchange(part_ix * 16 + 16, split_inclusive.y | 2147483648u, _437);
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
        _423.Store((ix + i_2) * 4 + 0, m_1.element);
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    comp_main();
}
