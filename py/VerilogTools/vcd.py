import datetime


def dump_vcd(f, data, timescale="1ps"):
    """Dumps waveforms in dictionary 'data' to open file f in VCD format
    for viewing in a waveform viewer such as GTKWave. 'data' should be
    a dict where keys are the names of the wave forms and the values
    are dicts with keys 'bit_depth' and 'data'. 'bit_depth' is the
    number of bits in the samples and data is an iterable with the
    data. Data should be sampled at regular sampling rate.

    """
    
    # header section
    f.write("$date\n  " + str(datetime.datetime.now()) + "\n$end\n")
    f.write("$version\n  Brooksee Verilog Tools\n$end\n")
    f.write("$comment\n  dump_vcd()\n$end\n")
    f.write("$timescale " + str(timescale) + " $end\n")

    #variable definition section
    keys = data.keys()
    
    for idx, key in enumerate(keys):
        val = data[key]
        k = chr(idx+33)
        val["_symbol"] = k
        f.write("$var wire " + str(val["bit_depth"]) + " " + k + " " + key + " $end\n")

    f.write("$enddefinitions $end\n")

    def get_val(val, name, bit_depth):
        if bit_depth == 1:
            return str(val) + name
        else:
            return bin(val)[1:] + " " + name
        
    
    # dump vars section
    f.write("$dumpvars\n")
    for idx, key in enumerate(keys):
        val = data[key]
        init = val["data"][0]
        f.write(get_val(init, val["_symbol"], val["bit_depth"] ) + "\n")
        val["state"] = ""
    f.write("$end\n")

    pos = 0
    try:
        while True:
            dumpedTime = False
            for idx, key in enumerate(keys):
                val = data[key]
                v = val["data"][pos]
                if val["state"] != v:
                    if not(dumpedTime):
                        f.write("#"+str(pos)+"\n")
                        dumpedTime = True
                    f.write(get_val(v, val["_symbol"], val["bit_depth"] ) + "\n")
                    val["state"] = v
            pos += 1
    except IndexError:
        pass

        
    f.close()
    
