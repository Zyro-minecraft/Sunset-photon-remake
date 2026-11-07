#!/usr/bin/env python3
"""Generate the tiny per-dimension wrapper programs. Bodies live in shaders/program/."""
import os
ROOT = os.path.join(os.path.dirname(__file__), '..', 'shaders')
DIMS = {'': 'DIM_OVERWORLD', 'world-1': 'DIM_NETHER', 'world1': 'DIM_END'}
# program: (vsh body, fsh body, extra define)
PROGRAMS = {
    'gbuffers_terrain':     ('geom.vsh', 'geom.fsh', 'G_TERRAIN'),
    'gbuffers_water':       ('geom.vsh', 'geom.fsh', 'G_WATER'),
    'gbuffers_textured':    ('geom.vsh', 'geom.fsh', 'G_TEXTURED'),
    'gbuffers_entities':    ('geom.vsh', 'geom.fsh', 'G_ENTITIES'),
    'gbuffers_hand':        ('geom.vsh', 'geom.fsh', 'G_HAND'),
    'gbuffers_block':       ('geom.vsh', 'geom.fsh', 'G_BLOCK'),
    'gbuffers_spidereyes':  ('simple.vsh', 'emissive.fsh', None),
    'gbuffers_beaconbeam':  ('simple.vsh', 'emissive.fsh', None),
    'gbuffers_armor_glint': ('simple.vsh', 'glint.fsh', None),
    'gbuffers_weather':     ('simple.vsh', 'weather.fsh', None),
    'gbuffers_skybasic':    ('sky_discard.vsh', 'sky_discard.fsh', None),
    'gbuffers_skytextured': ('sky_discard.vsh', 'sky_discard.fsh', None),
    'shadow':               ('shadow.vsh', 'shadow.fsh', None),
    'composite':            ('fullscreen.vsh', 'composite.fsh', None),
    'composite1':           ('fullscreen.vsh', 'composite1.fsh', None),
    'final':                ('fullscreen.vsh', 'final.fsh', None),
}
for folder, dim in DIMS.items():
    d = os.path.join(ROOT, folder)
    os.makedirs(d, exist_ok=True)
    for prog, (vsh, fsh, extra) in PROGRAMS.items():
        for ext, body in (('vsh', vsh), ('fsh', fsh)):
            lines = ['#version 330 compatibility', f'#define {dim}']
            if extra: lines.append(f'#define {extra}')
            lines.append(f'#include "/program/{body}"')
            with open(os.path.join(d, f'{prog}.{ext}'), 'w') as f:
                f.write('\n'.join(lines) + '\n')
print('generated', len(PROGRAMS) * 2 * len(DIMS), 'wrappers')
