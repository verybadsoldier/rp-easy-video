#!/usr/bin/python

import os, sys

indir = sys.argv[1]
outdir = sys.argv[2]

_tags_keep = ['video_shader', 'video_shader_enable', 
              'input_overlay', 'input_overlay_enable', 'input_overlay_opacity', 'input_overlay_scale',
              'custom_viewport_width', 'custom_viewport_height', 'custom_viewport_x', 'custom_viewport_y',
              'aspect_ratio_index', 'video_scale_integer']

def read_tag_value(line):
    toks = line.split(" = ")
    if (len(toks) != 2):
        raise Exception("Unexpexted token count in line: " + line)
    return toks[0], toks[1]

def filename_from_value(value):
    value = value.strip("\"':")
    value = value.replace("\\", "/")
    value = os.path.basename(value)
    return os.path.splitext(value)[0]

def adapt_tags(tags, filename):
    if ("video_shader" in tags):
        tags["video_shader"] = '"/opt/retropie/emulators/retroarch/shader/easy-video/john.merrit/%s.glslp"\n' % (filename_from_value(tags["video_shader"]))

    if ("input_overlay" in tags):
        tags["input_overlay"] = '"/opt/retropie/emulators/retroarch/overlays/easy-video/john.merrit/%s.cfg"\n' % (filename_from_value(tags["input_overlay"]))    
    
for filename in os.listdir(indir):
    print "Processing file: " + filename
    tags = {}
    with open(os.path.join(indir,filename), 'r') as f:
        lines = f.readlines()
        for line in lines:
            if (line.startswith("#")):
                continue
                
            tag, value = read_tag_value(line)
            if (tag not in _tags_keep or tag in tags):
                continue
            tags[tag] = value
        
        adapt_tags(tags, filename)
        
        split = os.path.splitext(filename)
        dest_file = os.path.join(outdir, split[0] + ".zip.cfg")
        print "Writing file: " + dest_file
        with open(dest_file, "w") as fo:
            for k, v in tags.iteritems():
                fo.write("%s = %s" % (k, v))

