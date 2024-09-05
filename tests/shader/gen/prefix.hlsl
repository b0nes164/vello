struct Monoid
{
    uint element;
};

struct State
{
    uint flag;
    Monoid aggregate;
    Monoid prefix;
};

static const Monoid _181 = { 0u };

globallycoherent RWByteAddressBuffer _43 : register(u2, space0);
ByteAddressBuffer _67 : register(t0, space0);
RWByteAddressBuffer _364 : register(u1, space0);

static uint3 gl_LocalInvocationID;
struct SPIRV_Cross_Input
{
    uint3 gl_LocalInvocationID : SV_GroupThreadID;
};

groupshared uint sh_part_ix;
groupshared Monoid sh_scratch[512];
groupshared uint sh_flag;
groupshared Monoid sh_prefix;

Monoid combine_monoid(Monoid a, Monoid b)
{
    Monoid _22 = { a.element + b.element };
    return _22;
}

void comp_main()
{
    if (gl_LocalInvocationID.x == 0u)
    {
        uint _47;
        _43.InterlockedAdd(0, 1u, _47);
        sh_part_ix = _47;
    }
    GroupMemoryBarrierWithGroupSync();
    uint part_ix = sh_part_ix;
    uint ix = (part_ix * 8192u) + (gl_LocalInvocationID.x * 16u);
    Monoid _71;
    _71.element = _67.Load(ix * 4 + 0);
    Monoid local[16];
    Monoid _73;
    _73.element = _71.element;
    local[0] = _73;
    for (uint i = 1u; i < 16u; i++)
    {
        Monoid param = local[i - 1u];
        Monoid _93;
        _93.element = _67.Load((ix + i) * 4 + 0);
        Monoid _94;
        _94.element = _93.element;
        Monoid param_1 = _94;
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
        Monoid _157;
        _157.element = agg.element;
        _43.Store(part_ix * 12 + 8, _157.element);
        if (part_ix == 0u)
        {
            Monoid _165;
            _165.element = agg.element;
            _43.Store(12, _165.element);
        }
    }
    DeviceMemoryBarrier();
    if (gl_LocalInvocationID.x == 511u)
    {
        uint flag = 1u;
        if (part_ix == 0u)
        {
            flag = 2u;
        }
        _43.Store(part_ix * 12 + 4, flag);
    }
    Monoid exclusive = _181;
    if (part_ix != 0u)
    {
        uint look_back_ix = part_ix - 1u;
        uint their_ix = 0u;
        Monoid their_agg;
        while (true)
        {
            if (gl_LocalInvocationID.x == 511u)
            {
                sh_flag = _43.Load(look_back_ix * 12 + 4);
            }
            GroupMemoryBarrierWithGroupSync();
            DeviceMemoryBarrier();
            uint flag_1 = sh_flag;
            GroupMemoryBarrierWithGroupSync();
            if (flag_1 == 2u)
            {
                if (gl_LocalInvocationID.x == 511u)
                {
                    Monoid _219;
                    _219.element = _43.Load(look_back_ix * 12 + 12);
                    Monoid _220;
                    _220.element = _219.element;
                    Monoid their_prefix = _220;
                    Monoid param_4 = their_prefix;
                    Monoid param_5 = exclusive;
                    exclusive = combine_monoid(param_4, param_5);
                }
                break;
            }
            else
            {
                if (flag_1 == 1u)
                {
                    if (gl_LocalInvocationID.x == 511u)
                    {
                        Monoid _240;
                        _240.element = _43.Load(look_back_ix * 12 + 8);
                        Monoid _241;
                        _241.element = _240.element;
                        their_agg = _241;
                        Monoid param_6 = their_agg;
                        Monoid param_7 = exclusive;
                        exclusive = combine_monoid(param_6, param_7);
                    }
                    look_back_ix--;
                    their_ix = 0u;
                    continue;
                }
            }
            if (gl_LocalInvocationID.x == 511u)
            {
                Monoid _261;
                _261.element = _67.Load(((look_back_ix * 8192u) + their_ix) * 4 + 0);
                Monoid _262;
                _262.element = _261.element;
                Monoid m = _262;
                if (their_ix == 0u)
                {
                    their_agg = m;
                }
                else
                {
                    Monoid param_8 = their_agg;
                    Monoid param_9 = m;
                    their_agg = combine_monoid(param_8, param_9);
                }
                their_ix++;
                if (their_ix == 8192u)
                {
                    Monoid param_10 = their_agg;
                    Monoid param_11 = exclusive;
                    exclusive = combine_monoid(param_10, param_11);
                    if (look_back_ix == 0u)
                    {
                        sh_flag = 2u;
                    }
                    else
                    {
                        look_back_ix--;
                        their_ix = 0u;
                    }
                }
            }
            GroupMemoryBarrierWithGroupSync();
            flag_1 = sh_flag;
            GroupMemoryBarrierWithGroupSync();
            if (flag_1 == 2u)
            {
                break;
            }
        }
        if (gl_LocalInvocationID.x == 511u)
        {
            Monoid param_12 = exclusive;
            Monoid param_13 = agg;
            Monoid inclusive_prefix = combine_monoid(param_12, param_13);
            sh_prefix = exclusive;
            Monoid _314;
            _314.element = inclusive_prefix.element;
            _43.Store(part_ix * 12 + 12, _314.element);
        }
        DeviceMemoryBarrier();
        if (gl_LocalInvocationID.x == 511u)
        {
            _43.Store(part_ix * 12 + 4, 2u);
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
        Monoid param_14 = row;
        Monoid param_15 = other_1;
        row = combine_monoid(param_14, param_15);
    }
    for (uint i_2 = 0u; i_2 < 16u; i_2++)
    {
        Monoid param_16 = row;
        Monoid param_17 = local[i_2];
        Monoid m_1 = combine_monoid(param_16, param_17);
        uint _367 = ix + i_2;
        Monoid _370;
        _370.element = m_1.element;
        _364.Store(_367 * 4 + 0, _370.element);
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    comp_main();
}
