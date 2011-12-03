#!/usr/bin/env ruby

require 'pp'
require 'gravsim'
require 'gravsim/jpl'

require 'ffi-opengl'
include FFI, GL, GLU, GLUT

include JPL_Horizons

UNIT_m = 1.0
UNIT_km = 1000.0*UNIT_m
UNIT_AU = 149598000*UNIT_km
UNIT_kg = 1.0
UNIT_s = 1.0
UNIT_min = 60.0*UNIT_s
UNIT_hour = 60.0*UNIT_min
UNIT_day = 24.0*UNIT_hour
UNIT_year = 365.0*UNIT_day
UNIT_c = 299792458*UNIT_m/UNIT_s

def vmag(v)
    Math.sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])
end

def load_majorbody_ephemeris(jpl_id)
    body = {}
    File.open("data/major_bodies/#{jpl_id}_info.txt").lines {|line|
        match = /Mass.*\(?10\^(\d+)\s*kg\s*\)?\s*=\s*(\d+.?\d*)/.match(line)
        if(match)
            match = match.to_a
            match.shift
            puts "#{jpl_id} mass: #{match[1]}e#{match[0]}"
            body[:mass] = "#{match[1]}e#{match[0]}".to_f*UNIT_kg
            puts "#{jpl_id} mass: #{body[:mass]}"
        end
    }
    
    if(body[:mass])
        puts "#{jpl_id} mass: #{body[:mass]}"
    else
        puts "Could not find mass for #{jpl_id}"
        body[:mass] = 1*UNIT_kg
    end
    File.open("data/major_bodies/#{jpl_id}_ephemeris.txt") {|fin|
        line = fin.lines
        while(line.next.chomp != '$$SOE')
        end
        body[:time] = line.next.split(' ')[0].to_f
        body[:position] = line.next.split(' ').map{|x| x.to_f*UNIT_AU}
        body[:velocity] = line.next.split(' ').map{|x| x.to_f*UNIT_AU/UNIT_day}
        # puts "posmag: #{vmag(body[:position])}"
        # puts "velmag: #{vmag(body[:velocity])}"
    }
    body
end

# body_ids = [HZ_SUN_ID] + HZ_PLANET_IDS
# body_ids += HZ_DWARF_PLANET_IDS
# body_ids += HZ_MAJOR_MOON_IDS



# (Mass,?\s*)\(?(10\^\d+\s*kg)\s*\(?\s*=\s*(\d+.?\d*)
# Mass,?\s*\(?(10\^\d+\s*kg)\s*\(?\s*=\s*(\d+.?\d*)
# Mass,?\s*\(?(10\^\d+\s*kg)\s*\)?\s*=\s*(\d+.?\d*)

# Mean radius, km          = 6371.01+-0.02   Mass, 10^24 kg = 5.9736
# Mass (10^23 kg )      =    6.4185       Flattening, f         =  1/154.409
#  Mass Pluto (10^22 kg) =   1.314+-0.018  Density Pluto:
# Mass (10^20 kg )        =                 Geometric Albedo    =  0.06 

# body_ids.each {|jpl_id|
#     mass = nil
#     File.open("data/major_bodies/#{jpl_id}_info.txt").lines {|line|
#         match = /Mass.*\(?10\^(\d+)\s*kg\s*\)?\s*=\s*(\d+.?\d*)/.match(line)
#         if(match)
#             match = match.to_a
#             match.shift
#             mass = "#{match[1]}e#{match[0]}".to_f
#         end
#     }
#     
#     if(mass)
#         puts "#{jpl_id}: #{mass} kg"
#     else
#         puts "Could not match mass for #{jpl_id}"
#     end
# }

$glcolors = {
    red:   FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [1.0, 0.0, 0.0, 1.0]),
    green: FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.0, 1.0, 0.0, 1.0]),
    blue:  FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.0, 0.0, 1.0, 1.0]),
    cyan:    FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.0, 1.0, 1.0, 1.0]),
    yellow:  FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [1.0, 1.0, 0.0, 1.0]),
    magenta: FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [1.0, 0.0, 1.0, 1.0]),
    
    dred:   FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.5, 0.0, 0.0, 1.0]),
    dgreen: FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.0, 0.5, 0.0, 1.0]),
    dblue:  FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.0, 0.0, 0.5, 1.0]),
    dcyan:    FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.0, 0.5, 0.5, 1.0]),
    dyellow:  FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.5, 0.5, 0.0, 1.0]),
    dmagenta: FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.5, 0.0, 0.5, 1.0]),
    
    lred:   FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [1.0, 0.5, 0.5, 1.0]),
    lgreen: FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.5, 1.0, 0.5, 1.0]),
    lblue:  FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.5, 0.5, 1.0, 1.0]),
    lcyan:    FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.5, 1.0, 1.0, 1.0]),
    lyellow:  FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [1.0, 1.0, 0.5, 1.0]),
    lmagenta: FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [1.0, 0.5, 1.0, 1.0]),
    
    white:   FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [1.0, 1.0, 1.0, 1.0]),
    gray50:  FFI::MemoryPointer.new(:float, 4).put_array_of_float(0, [0.5, 0.5, 0.5, 1.0])
}


class Tracker
    SIZE_POINT = 3*FFI::type_size(:float)
    def initialize(sim, body, max_points)
        @sim = sim
        @body = body
        @scale = 1.0/(1.0*UNIT_AU)
        @max_points = max_points
        @interval = 1*UNIT_day
        @last_update = 0
        @last_eval = 0
        @npoints = 0
        @points = FFI::MemoryPointer.new(:float, 3*max_points)
    end
    
    # discard every other point and double the interval to get a longer estimate
    def stretch()
        @npoints = @npoints/2
        @npoints.times {|j|
            pt = @points.get_array_of_float(j*2*SIZE_POINT, 3)
            @points.put_array_of_float(j*SIZE_POINT, pt)
        }
        @interval = @interval*2
    end
    
    def insert_pt()
        if(@npoints < @max_points)
            pt = @sim.get_position(@body).map{|x| x*@scale}
            @points.put_array_of_float(@npoints*SIZE_POINT, pt)
            @npoints += 1
        else
            stretch()
        end
    end
    
    def evaluate()
        # Re-estimate period, determine primary and orbital parameters, etc
        
    end
    
    def update(time)
        if(time > @last_update + @interval)
            insert_pt()
            @last_update = time
            @last_eval = time
        end
        
        if(time > @last_eval + @max_points*@interval)
            evaluate()
        end
    end
    
    def draw()
        glColor3fv($glcolors[:dgreen])
        glBegin(GL_LINE_STRIP)
        @npoints.times {|j|
            glVertex3f(*@points.get_array_of_float(j*SIZE_POINT, 3))
        }
        glEnd()
        # glEnableClientState(GL_VERTEX_ARRAY)
        # glVertexPointer(3, GL_FLOAT, 0, @points)
        # glDrawArrays(GL_LINE_STRIP, 0, @npoints)
        # glDisableClientState(GL_VERTEX_ARRAY)
    end
end


class GravSimWindow
    include FFI, GL, GLU, GLUT, Math
    POS = MemoryPointer.new(:float, 4).put_array_of_float(0, [5.0, 5.0, 10.0, 0.0])
    
    include Math
    def draw
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        
        glPushMatrix()
        glRotatef(@view_rotx, 1.0, 0.0, 0.0)
        glRotatef(@view_roty, 0.0, 1.0, 0.0)
        glRotatef(@view_rotz, 0.0, 0.0, 1.0)
        
        glColor3fv($glcolors[:red])
        glBegin(GL_LINE_STRIP)
            glVertex3f(0, 0, 0)
            glVertex3f(1, 0, 0)
        glEnd()
        glColor3fv($glcolors[:green])
        glBegin(GL_LINE_STRIP)
            glVertex3f(0, 0, 0)
            glVertex3f(0, 1, 0)
        glEnd()
        glColor3fv($glcolors[:blue])
        glBegin(GL_LINE_STRIP)
            glVertex3f(0, 0, 0)
            glVertex3f(0, 0, 1)
        glEnd()
        glColor3fv($glcolors[:dgreen])
        @tracks.each {|sim_id, track| track.draw()}
        
        glPopMatrix()
        glutSwapBuffers()
    end
    
    def key(k, x, y)
        case k
        when ?z.ord
            @view_rotz += 5.0
        when ?Z.ord
            @view_rotz -= 5.0
        when ' '.ord
            @paused = !@paused
            if(@paused)
                glutIdleFunc(nil)
            else
                glutIdleFunc(make_callback(:idle))
            end
        when 27 # Escape
            exit
        end
        glutPostRedisplay()
    end
    
    def special(k, x, y)
        case k
        when GLUT_KEY_UP
            @view_rotx += 5.0
        when GLUT_KEY_DOWN
            @view_rotx -= 5.0
        when GLUT_KEY_LEFT
            @view_roty += 5.0
        when GLUT_KEY_RIGHT
            @view_roty -= 5.0
        end
        glutPostRedisplay()
    end
    
    def reshape(width, height)
        h = height.to_f/width.to_f
        glViewport(0, 0, width, height)
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        glFrustum(-1.0, 1.0, -h, h, 5.0, 60.0)
        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity()
        glTranslatef(0.0, 0.0, -40.0)
    end
    
    def mouse(button, state, x, y)
        @mouse = state
        @x0, @y0 = x, y
    end
    
    def motion(x, y)
        if(@mouse == GLUT_DOWN) then
            @view_roty += @x0 - x
            @view_rotx += @y0 - y
        end
        @x0, @y0 = x, y
    end
    
    def idle
        t = glutGet(GLUT_ELAPSED_TIME)/1000.0
        @sim.run(1.0*UNIT_day, 1.0*UNIT_hour)
        @sim_time += 1.0*UNIT_day
        @sim_ids.values.each {|id| @tracks[id].update(@sim_time)}
        @frame += 1
        $stdout.write "#{@frame}\r"
        glutPostRedisplay()
    end
    
    def make_callback(sym)
        if(@callbacks == nil)
            @callbacks = {}
        end
        if(@callbacks[sym] == nil)
            @callbacks[sym] = method(sym).to_proc
        end
        @callbacks[sym]
    end
    
    def initialize
        # argc, argv parameters
        glutInit(MemoryPointer.new(:int, 1).put_int(0, 0), 
                 MemoryPointer.new(:pointer, 1).put_pointer(0, nil))
        glutInitDisplayMode(GLUT_RGB | GLUT_DEPTH | GLUT_DOUBLE)
        
        glutInitWindowPosition(0, 0)
        glutInitWindowSize(800, 600)
        glutCreateWindow('GravSim')
        @view_rotx, @view_roty, @view_rotz = 20.0, 30.0, 0.0
        
        @sim_time = 0
        @frame = 0
        @paused = false
        
        @sim = GravSim.new
        @sim_ids = {}
        @tracks = {}
        body_ids = [HZ_SUN_ID] + HZ_PLANET_IDS
        body_ids += HZ_DWARF_PLANET_IDS
        # body_ids += HZ_MAJOR_MOON_IDS
        
        body_ids.each {|jpl_id|
            body = load_majorbody_ephemeris(jpl_id)
            sim_id = @sim.add_body(body[:position], body[:velocity], body[:mass])
            @sim_ids[jpl_id] = sim_id
            @tracks[sim_id] = Tracker.new(@sim, sim_id, 360)
        }
        # @sim.add_particle(rb_pos, rb_vel, rb_mass)
        puts "sim_ids: #{@sim_ids}"
        
        # glLightfv(GL_LIGHT0, GL_POSITION, POS)
        # glEnable(GL_CULL_FACE)
        # glEnable(GL_LIGHTING)
        # glEnable(GL_LIGHT0)
        # glEnable(GL_DEPTH_TEST)

        # @gear1 = glGenLists(1)
        # glNewList(@gear1, GL_COMPILE)
        # glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, RED)
        # gear(1.0, 4.0, 1.0, 20, 0.7)
        # glEndList()
        
        # glEnable(GL_NORMALIZE)
        
        glutDisplayFunc(make_callback(:draw))
        glutReshapeFunc(make_callback(:reshape))
        glutKeyboardFunc(make_callback(:key))
        glutSpecialFunc(make_callback(:special))
        glutIdleFunc(make_callback(:idle))
        glutMouseFunc(make_callback(:mouse))
        glutMotionFunc(make_callback(:motion))
    end
    
    def start
        glutMainLoop()
    end
end # GravSimWindow

GravSimWindow.new.start

