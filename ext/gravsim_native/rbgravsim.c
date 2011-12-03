
#include "ruby.h"
#include "gravsim.h"

static void gravsim_free(void * p) {GRAVSIM_FreeSystem(p);}

static VALUE gravsim_initialize(VALUE self)
{
    return self;
}

static VALUE gravsim_new(VALUE self)
{
    struct System * sys = GRAVSIM_NewSystem();
    VALUE rb_sys = Data_Wrap_Struct(self, 0, gravsim_free, sys);
    rb_obj_call_init(rb_sys, 0, NULL);
    return rb_sys;
}

static VALUE gravsim_copy_bodies_from(VALUE self, VALUE rhs)
{
    struct System * sysDst, * sysSrc;
    Data_Get_Struct(self, struct System, sysDst);
    Data_Get_Struct(rhs, struct System, sysSrc);
    GRAVSIM_CopyBodies(sysDst, sysSrc);
    return self;
}

static VALUE gravsim_copy_particles_from(VALUE self, VALUE rhs)
{
    struct System * sysDst, * sysSrc;
    Data_Get_Struct(self, struct System, sysDst);
    Data_Get_Struct(rhs, struct System, sysSrc);
    GRAVSIM_CopyParticles(sysDst, sysSrc);
    return self;
}

static VALUE gravsim_copy_parameters_from(VALUE self, VALUE rhs)
{
    struct System * sysDst, * sysSrc;
    Data_Get_Struct(self, struct System, sysDst);
    Data_Get_Struct(rhs, struct System, sysSrc);
    GRAVSIM_CopyParameters(sysDst, sysSrc);
    return self;
}

static VALUE gravsim_get_position(VALUE self, VALUE rb_body_id)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
    VALUE rb_x = rb_float_new(body->p[0]);
    VALUE rb_y = rb_float_new(body->p[1]);
    VALUE rb_z = rb_float_new(body->p[2]);
    return rb_ary_new3(3, rb_x, rb_y, rb_z);
}

static VALUE gravsim_set_position(VALUE self, VALUE rb_body_id, VALUE rb_pos)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
    body->p[0] = NUM2DBL(rb_ary_entry(rb_pos, 0));
    body->p[1] = NUM2DBL(rb_ary_entry(rb_pos, 1));
    body->p[2] = NUM2DBL(rb_ary_entry(rb_pos, 2));
    return Qnil;
}

static VALUE gravsim_get_velocity(VALUE self, VALUE rb_body_id)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
    VALUE rb_x = rb_float_new(body->v[0]);
    VALUE rb_y = rb_float_new(body->v[1]);
    VALUE rb_z = rb_float_new(body->v[2]);
    return rb_ary_new3(3, rb_x, rb_y, rb_z);
}

static VALUE gravsim_set_velocity(VALUE self, VALUE rb_body_id, VALUE rb_vel)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
    body->v[0] = NUM2DBL(rb_ary_entry(rb_vel, 0));
    body->v[1] = NUM2DBL(rb_ary_entry(rb_vel, 1));
    body->v[2] = NUM2DBL(rb_ary_entry(rb_vel, 2));
    return Qnil;
}

// static VALUE gravsim_get_acceleration(VALUE self, VALUE rb_body_id)
// {
//     struct System * sys;
//     Data_Get_Struct(self, struct System, sys);
//     struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
//     VALUE rb_x = rb_float_new(body->a[0]);
//     VALUE rb_y = rb_float_new(body->a[1]);
//     VALUE rb_z = rb_float_new(body->a[2]);
//     return rb_ary_new3(3, rb_x, rb_y, rb_z);
// }
// 
// static VALUE gravsim_set_acceleration(VALUE self, VALUE rb_body_id, VALUE rb_accel)
// {
//     struct System * sys;
//     Data_Get_Struct(self, struct System, sys);
//     struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
//     body->a[0] = NUM2DBL(rb_ary_entry(rb_accel, 0));
//     body->a[1] = NUM2DBL(rb_ary_entry(rb_accel, 1));
//     body->a[2] = NUM2DBL(rb_ary_entry(rb_accel, 2));
//     return Qnil;
// }

static VALUE gravsim_get_mass(VALUE self, VALUE rb_body_id)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
    return rb_float_new(body->mass);
}

static VALUE gravsim_set_mass(VALUE self, VALUE rb_body_id, VALUE rb_mass)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body * body = GRAVSIM_GetBody(sys, NUM2LONG(rb_body_id));
    body->mass = NUM2DBL(rb_mass);
    return Qnil;
}

static VALUE gravsim_add_body(VALUE self, VALUE rb_pos, VALUE rb_vel, VALUE rb_mass)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body body;
    body.p[0] = NUM2DBL(rb_ary_entry(rb_pos, 0));
    body.p[1] = NUM2DBL(rb_ary_entry(rb_pos, 1));
    body.p[2] = NUM2DBL(rb_ary_entry(rb_pos, 2));
    body.v[0] = NUM2DBL(rb_ary_entry(rb_vel, 0));
    body.v[1] = NUM2DBL(rb_ary_entry(rb_vel, 1));
    body.v[2] = NUM2DBL(rb_ary_entry(rb_vel, 2));
    body.mass = NUM2DBL(rb_mass);
    VALUE rb_body_id = INT2FIX(GRAVSIM_AddBody(sys, &body));
    return rb_body_id;
}

static VALUE gravsim_add_particle(VALUE self, VALUE rb_pos, VALUE rb_vel)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    struct Body body;
    body.p[0] = NUM2DBL(rb_ary_entry(rb_pos, 0));
    body.p[1] = NUM2DBL(rb_ary_entry(rb_pos, 1));
    body.p[2] = NUM2DBL(rb_ary_entry(rb_pos, 2));
    body.v[0] = NUM2DBL(rb_ary_entry(rb_vel, 0));
    body.v[1] = NUM2DBL(rb_ary_entry(rb_vel, 1));
    body.v[2] = NUM2DBL(rb_ary_entry(rb_vel, 2));
    body.mass = 0;
    VALUE rb_body_id = GRAVSIM_AddParticle(sys, &body);
    return rb_body_id;
}

static VALUE gravsim_get_g(VALUE self)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    return rb_float_new(sys->G);
}

static VALUE gravsim_set_g(VALUE self, VALUE rb_g)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    sys->G = NUM2DBL(rb_g);
    return Qnil;
}

static VALUE gravsim_run(VALUE self, VALUE rb_time, VALUE rb_max_tstep)
{
    struct System * sys;
    Data_Get_Struct(self, struct System, sys);
    double runTime = NUM2DBL(rb_time);
    int n = ceil(runTime/NUM2DBL(rb_max_tstep));
    double tstep = runTime/n;
    for(int j = 0; j < n; ++j)
        GRAVSIM_Step(sys, tstep);
    return Qnil;
}

void Init_gravsim_native(void)
{
    VALUE c_GravSim = rb_define_class("GravSim", rb_cObject);
    
    rb_define_singleton_method(c_GravSim, "new", gravsim_new, 0);
    rb_define_method(c_GravSim, "initialize", gravsim_initialize, 0);
    
    rb_define_method(c_GravSim, "add_body", gravsim_add_body, 3);
    rb_define_method(c_GravSim, "add_particle", gravsim_add_particle, 2);
    
    rb_define_method(c_GravSim, "g", gravsim_get_g, 0);
    rb_define_method(c_GravSim, "g=", gravsim_set_g, 1);
    
    rb_define_method(c_GravSim, "copy_bodies_from", gravsim_copy_bodies_from, 1);
    rb_define_method(c_GravSim, "copy_particles_from", gravsim_copy_particles_from, 1);
    rb_define_method(c_GravSim, "copy_parameters_from", gravsim_copy_parameters_from, 1);
    
    rb_define_method(c_GravSim, "get_position", gravsim_get_position, 1);
    rb_define_method(c_GravSim, "set_position", gravsim_set_position, 2);
    rb_define_method(c_GravSim, "get_velocity", gravsim_get_velocity, 1);
    rb_define_method(c_GravSim, "set_velocity", gravsim_set_velocity, 2);
    // rb_define_method(c_GravSim, "get_acceleration", gravsim_get_acceleration, 1);
    // rb_define_method(c_GravSim, "set_acceleration", gravsim_set_acceleration, 2);
    rb_define_method(c_GravSim, "get_mass", gravsim_get_mass, 1);
    rb_define_method(c_GravSim, "set_mass", gravsim_set_mass, 2);
    
    rb_define_method(c_GravSim, "run", gravsim_run, 2);
}

