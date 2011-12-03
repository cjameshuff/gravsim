
#ifndef GRAVSIM_H
#define GRAVSIM_H

#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

typedef int32_t body_id_t;

struct Body {
    double p[3];// position
    double v[3];// velocity
    double f[3];// total forces
    double g[3];// gradient of forces^2
    double mass;
};

struct System {
    // Bodies are objects large enough to have significant gravitation.
    // Particles are test bodies that have no influence on the primary bodies, but
    // are influenced by them.
    struct Body * bodies;
    size_t nbodies, maxbodies;
    
    struct Body * particles;
    size_t nparticles, maxparticles;
    
    double sim_time;
    double G;
    int sign;
};

static inline void VSet(double v[3], double x, double y, double z) {v[0] = x; v[1] = y; v[2] = z;}
static inline void VCpy(double v[3], double rhs[3]) {v[0] = rhs[0]; v[1] = rhs[1]; v[2] = rhs[2];}

struct System * GRAVSIM_NewSystem(void);
void GRAVSIM_FreeSystem(struct System * sys);
void GRAVSIM_CopyBodies(struct System * sysDst, struct System * sysSrc);
void GRAVSIM_CopyParticles(struct System * sysDst, struct System * sysSrc);
void GRAVSIM_CopyParameters(struct System * sysDst, struct System * sysSrc);

body_id_t GRAVSIM_AddBody(struct System * sys, struct Body * body);
struct Body * GRAVSIM_GetBody(struct System * sys, body_id_t bid);
body_id_t GRAVSIM_AddParticle(struct System * sys, struct Body * part);
struct Body * GRAVSIM_GetParticle(struct System * sys, body_id_t pid);

// void GRAVSIM_CompGravAt(struct System * sys, double p0[3], double f[3], struct Body * ignoreBody);

void GRAVSIM_Reverse(struct System * sys);

void GRAVSIM_Step(struct System * sys, double tstep);

#endif // GRAVSIM_H
