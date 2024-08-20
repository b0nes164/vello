static const uint3 gl_WorkGroupSize = uint3(512u, 1u, 1u);

ByteAddressBuffer _15 : register(t0, space0);
RWByteAddressBuffer _19 : register(u1, space0);
globallycoherent RWByteAddressBuffer _23 : register(u2, space0);

groupshared uint s_broadcast;
groupshared uint s_lock;
groupshared uint s_reduce[128];
groupshared uint s_fallback[128];

void comp_main()
{
}

[numthreads(512, 1, 1)]
void main()
{
    comp_main();
}
