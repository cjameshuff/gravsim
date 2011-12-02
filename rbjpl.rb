#!/usr/bin/env ruby

require 'pty'
require 'pp'

def strip_escapes(str)
    escaped = false
    out_str = ""
    str.each_char {|ch|
        if(ch == "\e")
            escaped = true
        elsif(escaped)
            if("=<>".include?(ch) || ('a'..'z').include?(ch) || ('A'..'Z').include?(ch))
                escaped = false
            end
        else
            out_str += ch
        end
    }
    out_str
end

# pp strip_escapes("\e[K\e[?1l\e>Horizons> ")
# exit

def wait_prompt(pty_out, prompts)
    buffer = ""
    line_buffer = ""
    line_buffer_stripped_old = ""
    prompt = nil
    prompt_proc = nil
    # \r characters are ignored, \n starts a new line, all escape characters are ignored in checking against prompt
    # until(prompt != nil)
    loop do
        ch = pty_out.getc.chr
        # pp ch
        # puts strip_escapes(line_buffer)
        if(ch == "\r")
            next
        end
        
        line_buffer += ch
        line_buffer_stripped = strip_escapes(line_buffer)
        
        if(line_buffer_stripped_old == line_buffer_stripped)
            next
        end
        line_buffer_stripped_old = line_buffer_stripped
        
        # $stdout.write(ch)
        # puts line_buffer_stripped
        
        # A matchable change has occurred
        if(ch == "\n")
            buffer += line_buffer
            $stdout.write(line_buffer)
            line_buffer = ""
        else
            prompt = prompts.keys.find_index {|p|
                if(p.is_a? String)
                    if(line_buffer_stripped == p)
                        prompt_proc = prompts[p]
                        p
                    else
                        nil
                    end
                else
                    if(line_buffer_stripped =~ p)
                        prompt_proc = prompts[p]
                        p
                    else
                        nil
                    end
                end
            }
            if(prompt)
                buffer += line_buffer
                $stdout.write(line_buffer)
                line_buffer = ""
                if(prompt_proc)
                    if(!prompt_proc.call(buffer, prompt))
                        break # have handler, cancel exit
                    end
                else
                    break
                end
            end
        end
    end # until(prompt != nil)
    [buffer, prompt]
end

$hz_base_handlers = {
     /Horizons> / => ->(buffer, prompt){false},
    " Select ... [F]tp, [M]ail, [R]edisplay, ?, <cr>: " =>
        ->(buffer, prompt){$hz_in.puts ""; true},
    "Continue [ <cr>=yes, n=no, ? ] : " =>
        ->(buffer, prompt){$hz_in.puts ""; true},
    / < Scroll & Page: space, <cr>, <b>ack, OR arrow keys. <q> ends display. > .*%/ =>
        ->(buffer, prompt){$hz_in.puts " "; true}
}

def wait_hz_prompt()
    resp, prompt = wait_prompt($hz_out, $hz_base_handlers)
    # puts "Received prompt: #{prompt}"
    [resp, prompt]
end

def get_major_body(body)
    if(!File.directory?("data"))
        Dir.mkdir("data")
    end
    if(!File.directory?("data/major_bodies"))
        Dir.mkdir("data/major_bodies")
    end
    if(File.exists?("data/major_bodies/#{body}_info.txt"))
        return
    end
    $hz_in.puts body
    resp, prompt = wait_prompt($hz_out, $hz_base_handlers.merge({
        " Select ... [E]phemeris, [F]tp, [M]ail, [R]edisplay, ?, <cr>: " =>
            ->(buffer, prompt){
                File.open("data/major_bodies/#{body}_info.txt", "w") {|fout|
                    lines = buffer.lines.to_a
                    lines.shift(1)
                    lines.pop(1)
                    lines.each {|line| fout.puts(strip_escapes(line.chomp))}
                }
                $hz_in.puts "E"; true
            },
        " Observe, Elements, Vectors  [o,e,v,?] : " =>
            ->(buffer, prompt){$hz_in.puts "v"; true},
        " Coordinate center [ <id>,coord,geo  ] : " =>
            ->(buffer, prompt){$hz_in.puts "500@0"; true},
        " Use previous center  [ cr=(y), n, ? ] : " =>
            ->(buffer, prompt){$hz_in.puts "y"; true},
        " Confirm selected station    [ y/n ] --> " =>
            ->(buffer, prompt){$hz_in.puts "y"; true},
        " Reference plane [eclip, frame, body ] : " =>
            ->(buffer, prompt){$hz_in.puts "frame"; true},
        / Starting CT  .* : / =>
            ->(buffer, prompt){$hz_in.puts "2001-JAN-1 10:00"; true},
        / Ending   CT  .* : / =>
            ->(buffer, prompt){$hz_in.puts "2001-JAN-2"; true},
        " Output interval [ex: 10m, 1h, 1d, ? ] : " =>
            ->(buffer, prompt){$hz_in.puts "1h"; true},
        " Accept default output [ cr=(y), n, ?] : " =>
            ->(buffer, prompt){
                buffer.clear; $hz_in.puts "y"; true},
        " >>> Select... [A]gain, [N]ew-case, [F]tp, [K]ermit, [M]ail, [R]edisplay, ? : " =>
            ->(buffer, prompt){
                File.open("data/major_bodies/#{body}_ephemeris.txt", "w") {|fout|
                    lines = buffer.lines.to_a
                    lines.shift(2)
                    lines.pop(1)
                    lines.each {|line| fout.puts(strip_escapes(line.chomp))}
                }
                $hz_in.puts "N"; true
            }
    }))
end # get_major_body()

def get_minor_body(body)
    if(!File.directory?("data"))
        Dir.mkdir("data")
    end
    if(!File.directory?("data/minor_bodies"))
        Dir.mkdir("data/minor_bodies")
    end
    if(File.exists?("data/minor_bodies/#{body}_info.txt"))
        return
    end
    $hz_in.puts "#{body};"
    resp, prompt = wait_prompt($hz_out, $hz_base_handlers.merge({
        " Select ... [E]phemeris, [F]tp, [M]ail, [R]edisplay, ?, <cr>: " =>
            ->(buffer, prompt){
                File.open("data/#{body}_info.txt", "w") {|fout|
                    lines = buffer.lines.to_a
                    lines.shift(1)
                    lines.pop(1)
                    lines.each {|line| fout.puts(strip_escapes(line.chomp))}
                }
                $hz_in.puts "E"; true
            },
        " Observe, Elements, Vectors  [o,e,v,?] : " =>
            ->(buffer, prompt){$hz_in.puts "v"; true},
        " Coordinate center [ <id>,coord,geo  ] : " =>
            ->(buffer, prompt){$hz_in.puts "500@0"; true},
        " Use previous center  [ cr=(y), n, ? ] : " =>
            ->(buffer, prompt){$hz_in.puts "y"; true},
        " Confirm selected station    [ y/n ] --> " =>
            ->(buffer, prompt){$hz_in.puts "y"; true},
        " Reference plane [eclip, frame, body ] : " =>
            ->(buffer, prompt){$hz_in.puts "frame"; true},
        / Starting CT  .* : / =>
            ->(buffer, prompt){$hz_in.puts "2001-JAN-1 10:00"; true},
        / Ending   CT  .* : / =>
            ->(buffer, prompt){$hz_in.puts "2001-JAN-2"; true},
        " Output interval [ex: 10m, 1h, 1d, ? ] : " =>
            ->(buffer, prompt){$hz_in.puts "1h"; true},
        " Accept default output [ cr=(y), n, ?] : " =>
            ->(buffer, prompt){
                buffer.clear; $hz_in.puts "y"; true},
        " >>> Select... [A]gain, [N]ew-case, [F]tp, [K]ermit, [M]ail, [R]edisplay, ? : " =>
            ->(buffer, prompt){
                File.open("data/#{body}_ephemeris.txt", "w") {|fout|
                    lines = buffer.lines.to_a
                    lines.shift(2)
                    lines.pop(1)
                    lines.each {|line| fout.puts(strip_escapes(line.chomp))}
                }
                $hz_in.puts "N"; true
            }
    }))
end # get_major_body()

def connect()
    $hz_out, $hz_in, $hz_pid = PTY.spawn({
            "TERM" => "no-resize-vt100"# Cancel terminal negotiation (Horizons specific) (doesn't seem to work)
        },
        "telnet ssd.jpl.nasa.gov 6775")
    at_exit {$hz_in.puts "X"}
    resp, prompt = wait_hz_prompt()
end

# Generate a hash from the major bodies listing
def proc_major_bodies_listing()
    if(!File.directory?("data"))
        Dir.mkdir("data")
    end
    if(!File.directory?("data/major_bodies.txt"))
        download_response("*", "data/major_bodies.txt")
    end
    records = {}
    started = false
    File.open("data/asteroid_list.txt").lines {|line|
        line = strip_escapes(line.chomp)
        if(line == "  -------  ---------------------------------- -----------  ------------------- ")
            started = true
        elsif(started && line == " ")
            break
        elsif(started)
            record = {}
            record[:id] = line[0, 9].strip
            record[:name] = line[11, 34].strip
            record[:designation] = line[46, 11].strip
            record[:other] = line[59, 20].strip
            if(record[:name] == '')
                record[:name] = (record[:designation] == '')? "JPLH#{record[:id]}" : record[:designation]
            end
            records[record[:id]] = record
        end
    }
    records
end # get_listing()

# Generate a hash from the asteroids listing
# Listing is generated with search query "H > -10.;", and contains these fields:
#    Record #  Epoch-yr  Primary Desig  Name                      H      
#          1     2010    (undefined)     Ceres                     3.34
def proc_asteroid_listing()
    records = {}
    started = false
    File.open("data/asteroid_list.txt").lines {|line|
        line = strip_escapes(line.chomp)
        if(line == "    --------  --------  -------------  ------------------------- -----  ")
            started = true
        elsif(started && line == "")
            break
        elsif(started)
            record = {}
            record[:num] = line[0, 11].strip
            record[:epoch] = line[16, 4].strip
            record[:designation] = line[24, 13].strip
            record[:name] = line[39, 25].strip
            record[:H] = line[65, 5].strip
            if(record[:designation] == '')
                record[:designation] = record[:name]
            end
            records[record[:id]] = record
        end
    }
    records
end # proc_asteroid_listing()

# Remove barycenters, test bodies, etc.
def filter_mb_listing(listing)
    [
        # Barycenters
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        # Earth-moon L1, L2, L4, and L5
        '391', '392', '394', '395',
        '-555' # test entry
    ].each {|b| listing.delete(b)}
    listing
end


def download_response(cmd, fname)
    $hz_in.puts cmd
    resp, prompt = wait_hz_prompt() # FIXME: can break on falsely-detected prompt
    File.open(fname, "w") {|fout|
        resp.lines {|line|
            line = strip_escapes(line.chomp)
            fout.puts(line)
        }
    }
end

def download_full_help()
    download_response("?!", "longhelp.txt")
end

connect()

# puts resp
# $hz_in.puts "?"
# $hz_in.puts "*"
# get_major_body("10") # Sun
# HZ_PLANET_IDS.each {|b| get_major_body(b)}
# HZ_MAJOR_MOON_IDS.each {|b| get_major_body(b)}
# HZ_DWARF_PLANET_IDS.each {|b| get_major_body(b)}

# download_response("H > -10;", "asteroids.txt")
# download_response("*", "data/major_bodies.txt")
# download_response("AST;", "data/asteroids.txt")
# download_response("COM;", "data/comets.txt")

