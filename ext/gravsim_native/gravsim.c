/*******************************************************************************
# Copyright (c) 2011 Christopher James Huff
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#******************************************************************************/

#include "gravsim.h"


struct System * GRAVSIM_NewSystem(void)
{
    struct System * sys = (struct System *)malloc(sizeof(struct System));
    sys->maxbodies = 0;
    sys->nbodies = 0;
    sys->bodies = NULL;
    
    sys->maxparticles = 0;
    sys->nparticles = 0;
    sys->particles = NULL;
}

void GRAVSIM_FreeSystem(struct System * sys)
{
    if(sys->bodies)
        free(sys->bodies);
    if(sys->particles)
        free(sys->particles);
    free(sys);
}

void GRAVSIM_CopyBodies(struct System * sysDst, struct System * sysSrc)
{
    if(sysDst->nbodies != sysSrc->nbodies)
    {
        if(sysDst->bodies)
            free(sysDst->bodies);
        sysDst->maxbodies = sysSrc->nbodies;
        sysDst->nbodies = sysSrc->nbodies;
        sysDst->bodies = (struct Body *)malloc(sizeof(struct Body)*sysSrc->nbodies);
    }
    memcpy(sysDst->bodies, sysSrc->bodies, sizeof(struct Body)*sysSrc->nbodies);
}

void GRAVSIM_CopyParticles(struct System * sysDst, struct System * sysSrc)
{
    if(sysDst->nparticles != sysSrc->nparticles)
    {
        if(sysDst->particles)
            free(sysDst->particles);
        sysDst->maxparticles = sysSrc->nparticles;
        sysDst->nparticles = sysSrc->nparticles;
        sysDst->particles = (struct Body *)malloc(sizeof(struct Body)*sysSrc->nparticles);
    }
    memcpy(sysDst->particles, sysSrc->particles, sizeof(struct Body)*sysSrc->nparticles);
}

body_id_t GRAVSIM_AddBody(struct System * sys, struct Body * body)
{
    if(sys->nbodies == sys->maxbodies)
    {
        sys->maxbodies += 256;
        struct Body * tmp = (struct Body *)malloc(sizeof(struct Body)*sys->maxbodies);
        memcpy(tmp, sys->bodies, sizeof(struct Body)*sys->nbodies);
        free(sys->bodies);
        sys->bodies = tmp;
    }
    sys->bodies[sys->nbodies] = *body;
    return sys->nbodies++;
}

struct Body * GRAVSIM_GetBody(struct System * sys, body_id_t bid)
{
    if(bid < 0)
        return sys->particles - bid;
    else
        return sys->bodies + bid;
}

body_id_t GRAVSIM_AddParticle(struct System * sys, struct Body * part)
{
    if(sys->nparticles == sys->maxparticles)
    {
        sys->maxparticles += 256;
        struct Body * tmp = (struct Body *)malloc(sizeof(struct Body)*sys->maxparticles);
        memcpy(tmp, sys->particles, sizeof(struct Body)*sys->nparticles);
        free(sys->particles);
        sys->particles = tmp;
    }
    sys->particles[sys->nparticles] = *part;
    return -(sys->nparticles++);
}

struct Body * GRAVSIM_GetParticle(struct System * sys, body_id_t pid)
{
    return sys->particles - pid;
}

// Compute gravitational *acceleration* at estimated system state (p)
// This could be done faster, at the cost of more memory, by storing accumulated force on a
// per-body basis. The same gravitational force applies to each body of a pair, in opposite
// directions.
// Could premultiply gm by G for gravitation-only simulations. This would then have to be
// taken into account for additional forces...the benefit may be worthwhile.
void GRAVSIM_CompGravAt(struct System * sys, double pt[3], double a[3], struct Body * ignoreBody)
{
    for(int j = 0; j < 3; ++j)
        a[j] = 0;
    
    struct Body * b, * end = sys->bodies + sys->nbodies;
    for(b = sys->bodies; b != end; ++b)
    {
        if(b == ignoreBody)
            continue;
        
        double d0 = b->p[0] - pt[0];
        double d1 = b->p[1] - pt[1];
        double d2 = b->p[2] - pt[2];
        double r2 = (d0*d0 + d1*d1 + d2*d2);
        double r = sqrt(r2);
        double scl = b->gm/r2/r;
        // printf("r = %f, b->gm %f\n", r, b->gm);
        a[0] += d0*scl;
        a[1] += d1*scl;
        a[2] += d2*scl;
    }
    // printf("a = <%e, %e, %e>\n", a[0], a[1], a[2]);
}

// Compute gravitation and gradient of the gravitation^2
void GRAVSIM_CompGravGradAt(struct System * sys, double pt[3],
    double a[3], double g[3], struct Body * ignoreBody)
{
    for(int j = 0; j < 3; ++j) {
        a[j] = 0;
        g[j] = 0;
    }
    
    struct Body * b, * end = sys->bodies + sys->nbodies;
    for(b = sys->bodies; b != end; ++b)
    {
        if(b == ignoreBody)
            continue;
        
        double d0 = b->p[0] - pt[0];
        double d1 = b->p[1] - pt[1];
        double d2 = b->p[2] - pt[2];
        double r2 = (d0*d0 + d1*d1 + d2*d2);
        double r = sqrt(r2);
        double scl = b->gm/r2/r;
        // printf("r = %f, b->gm %f\n", r, b->gm);
        a[0] += d0*scl;
        a[1] += d1*scl;
        a[2] += d2*scl;
        
        // Calculate grad(|F|^2) = grad((b->gm/r2)^2)
        scl = b->gm*4.0/(r2*r2)/r;
        g[0] += d0*scl;
        g[1] += d1*scl;
        g[2] += d2*scl;
    }
    // printf("a = <%e, %e, %e>\n", a[0], a[1], a[2]);
}

void GRAVSIM_Step(struct System * sys, double tstep)
{
    // Chin's Algorithm C, a fourth-order, single-step, symplectic (energy-conserving) method.
    // http://arxiv.org/pdf/physics/0006082
    // p1 = p0 + 1/6*e*v0
    // v1 = v0 + 3/8*e*F(p1)
    // p2 = p1 + 1/3*e*v1
    // v2 = v1 + 1/4*e*(F(p2) + 1/48*e^2*grad(F(p2))^2)
    // p3 = p2 + 1/3*e*v2
    // v3 = v2 + 3/8*e*F(p3)
    // p4 = p3 + 1/6*e*v3
    // p0 = p4; v0 = v3 ?
    
    // Particles do not contribute to forces, and can have their positions and velocities
    // updated in the same pass.
    
    struct Body * b;
    struct Body * bend = sys->bodies + sys->nbodies;
    struct Body * pend = sys->particles + sys->nparticles;
    
    double ts_6 = tstep/6.0;
    double ts_4 = tstep/4.0;
    double ts_3 = tstep/3.0;
    double ts3_8 = tstep*3.0/8.0;
    double tsts_48 = tstep*tstep/48.0;
    double a[3], g[3];
    
    // p1 = p0 + 1/6*e*v0
    // v1 = v0 + 3/8*e*F(p1)
    for(b = sys->bodies; b != bend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_6*b->v[j];
    }
    for(b = sys->bodies; b != bend; ++b) {
        GRAVSIM_CompGravAt(sys, b->p, a, b);
        for(int j = 0; j < 3; ++j)
            b->v[j] += ts3_8*a[j];
    }
    for(b = sys->particles; b != pend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_6*b->v[j];
        
        GRAVSIM_CompGravAt(sys, b->p, a, b);
        for(int j = 0; j < 3; ++j)
            b->v[j] += ts3_8*a[j];
    }
    
    // p2 = p1 + 1/3*e*v1
    // v2 = v1 + 1/4*e*(F(p2) + 1/48*e^2*grad(F(p2))^2)
    for(b = sys->bodies; b != bend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_3*b->v[j];
    }
    for(b = sys->bodies; b != bend; ++b) {
        GRAVSIM_CompGravGradAt(sys, b->p, a, g, b);
        for(int j = 0; j < 3; ++j)
            b->v[j] += ts_4*(a[j] + tsts_48*g[j]);
    }
    for(b = sys->particles; b != pend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_3*b->v[j];
        
        GRAVSIM_CompGravGradAt(sys, b->p, a, g, b);
        for(int j = 0; j < 3; ++j)
            b->v[j] += ts_4*(a[j] + tsts_48*g[j]);
    }
    
    // p3 = p2 + 1/3*e*v2
    // v3 = v2 + 3/8*e*F(p3)
    for(b = sys->bodies; b != bend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_3*b->v[j];
    }
    for(b = sys->bodies; b != bend; ++b) {
        GRAVSIM_CompGravAt(sys, b->p, a, b);
        for(int j = 0; j < 3; ++j)
            b->v[j] += ts3_8*a[j];
    }
    for(b = sys->particles; b != pend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_3*b->v[j];
        
        GRAVSIM_CompGravAt(sys, b->p, a, b);
        for(int j = 0; j < 3; ++j)
            b->v[j] += ts3_8*a[j];
    }
    
    // p4 = p3 + 1/6*e*v3
    for(b = sys->bodies; b != bend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_6*b->v[j];
    }
    for(b = sys->particles; b != pend; ++b) {
        for(int j = 0; j < 3; ++j)
            b->p[j] += ts_6*b->v[j];
    }
}
