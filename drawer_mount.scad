// =====================================================================
//  BR-20/15 electromagnet - FLAT DRAWER MOUNT (zero extra height)
// ---------------------------------------------------------------------
//  Screws flat onto the cabinet side panel in the gap beside a drawer.
//  NOTHING of the mount is taller than the magnet itself: all material
//  stays inside the 20 mm vertical envelope of the magnet. The magnet is
//  held by two side cradles (towards the wall and towards the drawer),
//  a back plate with the M3 rear screw, and a mounting tab that runs
//  along the wall behind the magnet.
//
//  The lead exits towards the WALL into a channel cut through the
//  wall-side cradle, bends 90 deg there, passes through a notch in the
//  back plate and runs in a groove on the wall side of the mounting tab
//  towards the back of the cabinet.
//
//  Coordinates (as installed):
//    X = away from the cabinet side panel (panel is the plane X = 0)
//    Y = into the cabinet (magnet face towards -Y)
//    Z = up, magnet axis at Z = 0
//
//  Default = wall on the LEFT of the magnet when viewed from the front
//  (as in the photo). Set mirror_for_right_wall = true for the other side.
// =====================================================================

/* [Output] */
part = "print";                 // ["model", "print"]  print = lying on its flat side, no supports
mirror_for_right_wall = false;  // true -> mount for the right-hand cabinet wall
show_magnet = false;            // ghost magnet + lead for preview (model view only)

/* [Magnet - BR-20/15] */
magnet_d = 20;                  // body diameter
magnet_h = 15;                  // body length
fit = 0.3;                      // radial clearance of the cradle
face_protrusion = 1;            // magnet face sticks out past the mount front by this much
rear_screw_d = 3.4;             // through hole for the M3 screw in the back of the magnet
cable_from_back = 3.5;          // where the lead leaves the body, measured from the magnet back face

/* [Cable] */
cable_d = 4;                    // notch / groove width (lead + heat shrink)
wall_gap = 7;                   // space between magnet and wall for the 90 deg bend of the lead
groove_depth = 3;               // cable groove depth in the mounting tab (wall side)

/* [Body] */
bite = 3;                       // how deep each side cradle wraps around the magnet (at Z = 0)
side_t = 2.5;                   // material left on the drawer side of the magnet
back_t = 4;                     // back plate thickness (M3 screw length = back_t + thread depth)

/* [Mounting tab] */
tab_len = 30;                   // length of the tab behind the back plate
tab_t = 5;                      // tab thickness (must be > groove_depth)
wood_screw_d = 3.4;             // clearance hole for 3 mm wood screws
wood_screw_head_d = 6.5;        // countersink diameter

/* [Fillets] */
fillet_r = 3;                   // inner corner radius: tab and cradles to back plate (0 = sharp, > 3.5 reaches the screw heads)

$fn = 96;

// ---------------------------------------------------------------- derived
R  = magnet_d / 2;
Rp = R + fit;                   // cradle radius
cx = wall_gap + fit + R;        // magnet centre X
y_front   = face_protrusion;                       // mount front face
y_cable   = magnet_h - cable_from_back;            // lead exit (Y)
y_back    = magnet_h + fit;                        // back plate front face
y_tab     = y_back + back_t;                       // tab starts here
x_far     = cx + Rp + side_t;                      // overall width
screw_z   = R - wood_screw_head_d / 2 - 0.5;       // screws above/below the cable groove
eps = 0.01;

echo(str("Drawer mount: ", x_far, " wide, ", magnet_d, " tall, ", y_tab + tab_len, " deep. ",
         "Rear M3 screw must be ", back_t, " mm + thread depth long."));

// ---------------------------------------------------------------- helpers
// Countersunk hole, head at origin, shank going down -Z through length l.
module csk_hole(d, head_d, l) {
    cone_h = (head_d - d) / 2;                       // 90 deg countersink
    translate([0, 0, -l - eps]) cylinder(d = d, h = l + 2 * eps);
    translate([0, 0, -cone_h]) cylinder(d1 = d, d2 = head_d, h = cone_h + eps);
    cylinder(d = head_d, h = 20);                    // clearance above the head
}

// Box spanning the full magnet height (Z from -R to +R) - nothing is ever taller.
module slab(x0, x1, y0, y1) { translate([x0, y0, -R]) cube([x1 - x0, y1 - y0, magnet_d]); }

// Quarter round filling the corner between the +X and +Y axes (overlaps both by eps).
module fillet2d(r) { difference() { translate([-eps, -eps]) square(r + eps); translate([r, r]) circle(r = r); } }

// ---------------------------------------------------------------- solids
module wall_cradle() { slab(0, wall_gap + bite, y_front, y_back); }          // wall side, split by the cable channel
module far_cradle()  { slab(cx + Rp - bite, x_far, y_front, y_back); }       // drawer side, full length
module back_plate()  { slab(0, x_far, y_back, y_tab); }

module tab() {                                                                // along the wall, behind the back plate
    rr = 4;
    hull() {
        slab(0, tab_t, y_tab - eps, y_tab + tab_len - rr);
        for (z = [-R + rr, R - rr])
            translate([0, y_tab + tab_len - rr, z]) rotate([0, 90, 0]) cylinder(r = rr, h = tab_t);
    }
}

// Inner corners against the back plate, full height. The pocket cut trims the
// cradle ones down to what is left above and below the magnet.
module fillets() {
    if (fillet_r > 0) translate([0, 0, -R]) linear_extrude(magnet_d) {
        translate([tab_t, y_tab]) fillet2d(fillet_r);                            // tab
        translate([wall_gap + bite, y_back]) mirror([0, 1]) fillet2d(fillet_r);  // wall cradle
        translate([cx + Rp - bite, y_back]) rotate(180) fillet2d(fillet_r);      // drawer-side cradle
    }
}

// ---------------------------------------------------------------- cuts
module pocket()     { rotate([-90, 0, 0]) translate([cx, 0, -1]) cylinder(r = Rp, h = y_back + 1); }
module rear_hole()  { rotate([-90, 0, 0]) translate([cx, 0, y_back - 1]) cylinder(d = rear_screw_d, h = back_t + 2); }
// Channel at magnet-axis height through the whole wall-side cradle: the lead
// leaves the magnet here and bends backwards inside it.
module wall_channel() { translate([-1, y_front - 1, -cable_d / 2]) cube([wall_gap + 2, y_back - y_front + 2, cable_d]); }
module back_notch() { translate([-1, y_back - 1, -cable_d / 2]) cube([cable_d + 2, back_t + 2, cable_d]); }
module tab_groove() { translate([-1, y_tab - 1, -cable_d / 2]) cube([groove_depth + 1, tab_len + 2, cable_d]); }

module tab_screws() {
    for (p = [[y_tab + 7, screw_z], [y_tab + tab_len - 7, -screw_z]])
        translate([tab_t, p[0], p[1]]) rotate([0, 90, 0])
            csk_hole(wood_screw_d, wood_screw_head_d, tab_t);
}

module drawer_mount() {
    difference() {
        union() { wall_cradle(); far_cradle(); back_plate(); tab(); fillets(); }
        pocket();
        rear_hole();
        wall_channel();
        back_notch();
        tab_groove();
        tab_screws();
    }
}

// ---------------------------------------------------------------- preview ghost
module ghost() {
    x_e = cx - R;                          // lead exit on the magnet surface (wall side)
    r_b = x_e - groove_depth / 2;          // bend radius that lands the lead in the groove
    %color("silver", 0.5) rotate([-90, 0, 0]) translate([cx, 0, 0]) cylinder(r = R, h = magnet_h);
    %color("red", 0.7) {
        translate([x_e, y_cable + r_b, 0]) rotate([0, 0, 180])
            rotate_extrude(angle = 90) translate([r_b, 0]) circle(d = 3.5);
        translate([groove_depth / 2, y_cable + r_b, 0]) rotate([-90, 0, 0])
            cylinder(d = 3.5, h = y_tab + tab_len - (y_cable + r_b));
    }
}

// ---------------------------------------------------------------- output
module oriented() { mirror([mirror_for_right_wall ? 1 : 0, 0, 0]) children(); }

if (part == "model") {
    oriented() { drawer_mount(); if (show_magnet) ghost(); }
} else {
    // lying on its flat side: every feature is a vertical wall or a <= 45 deg curve
    translate([0, 0, R]) oriented() drawer_mount();
}
