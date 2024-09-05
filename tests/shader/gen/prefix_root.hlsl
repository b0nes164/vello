struct Monoid
{
    uint element;
};

static const Monoid _129 = { 0u };

RWByteAddressBuffer _42 : register(u0, space0);

static uint3 gl_LocalInvocationID;
static uint3 gl_GlobalInvocationID;
struct SPIRV_Cross_Input
{
    uint3 gl_LocalInvocationID : SV_GroupThreadID;
    uint3 gl_GlobalInvocationID : SV_DispatchThreadID;
};

groupshared Monoid sh_scratch[512];

Monoid combine_monoid(Monoid a, Monoid b)
{
    Monoid _22 = { a.element + b.element };
    return _22;
}

void comp_main()
{
    uint ix = gl_GlobalInvocationID.x * 8u;
    Monoid _46;
    _46.element = _42.Load(ix * 4 + 0);
    Monoid local[8];
    Monoid _48;
    _48.element = _46.element;
    local[0] = _48;
    for (uint i = 1u; i < 8u; i++)
    {
        Monoid param = local[i - 1u];
        Monoid _70;
        _70.element = _42.Load((ix + i) * 4 + 0);
        Monoid _71;
        _71.element = _70.element;
        Monoid param_1 = _71;
        local[i] = combine_monoid(param, param_1);
    }
    Monoid agg = local[7];
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
    GroupMemoryBarrierWithGroupSync();
    Monoid row = _129;
    if (gl_LocalInvocationID.x > 0u)
    {
        row = sh_scratch[gl_LocalInvocationID.x - 1u];
    }
    for (uint i_2 = 0u; i_2 < 8u; i_2++)
    {
        Monoid param_4 = row;
        Monoid param_5 = local[i_2];
        Monoid m = combine_monoid(param_4, param_5);
        uint _158 = ix + i_2;
        Monoid _161;
        _161.element = m.element;
        _42.Store(_158 * 4 + 0, _161.element);
    }
}

[numthreads(512, 1, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;
    gl_GlobalInvocationID = stage_input.gl_GlobalInvocationID;
    comp_main();
}
