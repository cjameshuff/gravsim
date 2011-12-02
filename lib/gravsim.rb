# require 'ffi'
# # require 'inline'
# 
# module GravSim
#     extend FFI::Library
#     # ffi_lib "orbsim_native"
#     # ffi_lib "orbsim_native/orbsim_native"
#     # ffi_lib "orbsim_native/orbsim_native.bundle"
#     # ffi_lib File.dirname(__FILE__) + "/orbsim_native/orbsim_native"
#     # There must be a better way...
#     if(FFI::Platform.mac?)
#         ffi_lib File.dirname(__FILE__) + "/orbsim_native/orbsim_native.bundle"
#     elsif(FFI::Platform.unix?)
#         ffi_lib File.dirname(__FILE__) + "/orbsim_native/orbsim_native.so"
#     elsif(FFI::Platform.windows?)
#         ffi_lib File.dirname(__FILE__) + "/orbsim_native/orbsim_native.dll"
#     else
#         ffi_lib File.dirname(__FILE__) + "/orbsim_native/orbsim_native.so"
#     end
#     
#     typedef :int32, :body_id
#     typedef :pointer, :sys_ptr
#     typedef :pointer, :bdy_ptr
#     
#     class Body < FFI::Struct
#         layout :p0x, :double,  :p0y, :double,  :p0z, :double
#         layout :px, :double,  :py, :double,  :pz, :double
#         layout :vx, :double,  :vy, :double,  :vz, :double
#         layout :k1x, :double,  :k1y, :double,  :k1z, :double
#         layout :k2x, :double,  :k2y, :double,  :k2z, :double
#         layout :k3x, :double,  :k3y, :double,  :k3z, :double
#         layout :k4x, :double,  :k4y, :double,  :k4z, :double
#         layout :thrustx, :double,  :thrusty, :double,  :thrustz, :double
#         layout :mass, :double
#     end
#     
#     attach_function 'ORBSIM_NewSystem', [ ], :sys_ptr
#     
#     attach_function 'test_function', [ :int ], :int
# end

require 'gravsim_native/gravsim_native'

G = 6.673e-11 # m^3/kg/s^2
