// =====================================================================
//  BR-20/15 electromagnet - LOW PROFILE CORNER MOUNT (rear-mounted)
// ---------------------------------------------------------------------
//  Same job as corner_mount.scad but with the smallest possible front:
//  seen from the door you only see the magnet and a 2.5 mm shell around
//  it. There are no side flanges. Instead two tabs run along the wall and
//  the shelf BEHIND the back plate (like the drawer mount) and take the
//  wood screws. The tabs stop short of the corner, leaving a channel
//  along the corner for the lead.
//
//  Coordinates (as installed):
//    X = away from the vertical wall      (wall is the plane X = 0)
//    Z = up from the shelf                (shelf is the plane Z = 0)
//    Y = into the cabinet                 (magnet face at Y = -face_protrusion)
//
//  Symmetric about the X=Z diagonal: one part fits all four corners.
// =====================================================================

/* [Output] */
part = "print";          // ["model", "print"]  print = front face on bed, tabs up
show_magnet = false;     // ghost magnet + bent lead for preview (model view only)

/* [Magnet - BR-20/15] */
magnet_d = 20;           // body diameter
magnet_h = 15;           // body length
fit = 0.3;               // radial clearance of the pocket
face_protrusion = 1;     // magnet face sticks out past the mount front by this much
rear_screw_d = 3.4;      // through hole for the M3 screw in the back of the magnet
cable_from_back = 3.5;   // where the lead leaves the body, measured from the magnet back face

/* [Cable] */
cable_d = 4;             // slot width and size of the open corner channel (lead + heat shrink)

/* [Body] */
wall_t = 2.5;            // shell between magnet and the two panels (more = gentler cable bend)
outer_t = 2.5;           // shell on the two open sides
back_t = 4;              // back plate thickness (M3 screw length = back_t + thread depth)

/* [Rear tabs] */
tab_len = 30;            // tab length behind the back plate
tab_t = 4.5;             // tab thickness. Make it thicker than cable_d so the two tabs merge into one L
tab_round = 3;           // corner radius at the tab ends
wood_screw_d = 3.4;      // clearance hole for 3 mm wood screws
wood_screw_head_d = 6.5; // countersink diameter
screws_per_tab = 2;      // 1 or 2

$fn = 96;

// ---------------------------------------------------------------- derived
R   = magnet_d / 2;
Rp  = R + fit;                       // pocket radius
Ro  = Rp + outer_t;                  // outer radius of the shell
cx  = wall_t + Rp;                   // magnet centre
cz  = cx;
W   = cx + Ro;                       // front profile is W x W (one corner rounded)
pocket_depth = magnet_h - face_protrusion;
y_back  = pocket_depth;              // back plate front face
y_tab   = y_back + back_t;           // tabs start here
y_cable = pocket_depth - cable_from_back;
tab_w   = W - cable_d;               // tab width (from the corner channel to the body edge)
eps = 0.01;

assert(abs(tab_t - cable_d) > 0.2,
       "tab_t must differ from cable_d by at least 0.2 mm (thicker merges the two tabs, thinner separates them)");

echo(str("Low profile corner mount: front ", W, " x ", W, " mm, ", y_tab + tab_len, " mm deep incl. tabs. ",
         "Rear M3 screw must be ", back_t, " mm + thread depth long."));

// ---------------------------------------------------------------- helpers
// Countersunk hole, head at origin, shank going down -Z through length l.
module csk_hole(d, head_d, l) {
    cone_h = (head_d - d) / 2;                       // 90 deg countersink
    translate([0, 0, -l - eps]) cylinder(d = d, h = l + 2 * eps);
    translate([0, 0, -cone_h]) cylinder(d1 = d, d2 = head_d, h = cone_h + eps);
    cylinder(d = head_d, h = 20);                    // clearance above the head
}

// ---------------------------------------------------------------- 2D profiles (XZ plane)
// Square W x W sitting in the corner, far corner rounded around the magnet.
module body_profile() {
    hull() {
        translate([cx, cz]) circle(r = Ro);
        square([W, cz]);
        square([cx, W]);
    }
}

// Strip of width cable_d along the diagonal, from just inside the pocket
// edge out past the corner (0,0).
module cable_slot_profile() {
    L = sqrt(cx * cx + cz * cz) + 5;
    translate([cx, cz]) rotate(225)
        translate([Rp - 0.5, -cable_d / 2]) square([L, cable_d]);
}

// ---------------------------------------------------------------- 3D parts
module body() {                                      // shell + back plate, Y from 0 to y_tab
    rotate([90, 0, 0]) mirror([0, 0, 1]) linear_extrude(y_tab) body_profile();
}

// Tab lying against the wall (X = 0), behind the back plate, from Z = cable_d up to W.
module wall_tab() {
    hull() {
        translate([0, y_tab - eps, cable_d]) cube([tab_t, tab_len - tab_round + eps, tab_w]);
        for (z = [cable_d + tab_round, W - tab_round])
            translate([0, y_tab + tab_len - tab_round, z]) rotate([0, 90, 0])
                cylinder(r = tab_round, h = tab_t);
    }
}

// The shelf tab is the wall tab mirrored across the X=Z diagonal.
module shelf_tab() { multmatrix([[0, 0, 1, 0], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]]) wall_tab(); }

module pocket()     { rotate([-90, 0, 0]) translate([cx, -cz, -1]) cylinder(r = Rp, h = pocket_depth + 1); }
module rear_hole()  { rotate([-90, 0, 0]) translate([cx, -cz, -1]) cylinder(d = rear_screw_d, h = y_tab + 2); }
module cable_slot() { rotate([90, 0, 0]) mirror([0, 0, 1]) translate([0, 0, -1]) linear_extrude(y_tab + 2) cable_slot_profile(); }

module wall_tab_screws() {
    zc = cable_d + tab_w / 2;                        // centre line of the tab
    for (y = screws_per_tab == 1 ? [y_tab + tab_len / 2] : [y_tab + 7, y_tab + tab_len - 7])
        translate([tab_t, y, zc]) rotate([0, 90, 0]) csk_hole(wood_screw_d, wood_screw_head_d, tab_t);
}
module shelf_tab_screws() { multmatrix([[0, 0, 1, 0], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]]) wall_tab_screws(); }

module corner_mount_lp() {
    difference() {
        union() { body(); wall_tab(); shelf_tab(); }
        pocket();
        rear_hole();
        cable_slot();
        wall_tab_screws();
        shelf_tab_screws();
    }
}

// ---------------------------------------------------------------- preview ghost
module ghost() {
    s   = 1 / sqrt(2);
    E   = [cx - R * s, y_cable, cz - R * s];         // lead exit on the magnet, towards the corner
    d_E = cx * sqrt(2) - R;                          // diagonal distance exit -> corner
    c_f = cable_d / 2 - 0.25;                        // final run: lead centre this far from both panels
    r_b = d_E - c_f * sqrt(2);                       // bend radius that lands the lead in the corner
    M   = [[-s, 0,  s, E[0]],                        // local X = towards corner, local Y = +Y
           [ 0, 1,  0, E[1]],
           [-s, 0, -s, E[2]],
           [ 0, 0,  0, 1]];
    %color("silver", 0.5) rotate([-90, 0, 0]) translate([cx, -cz, -face_protrusion]) cylinder(r = R, h = magnet_h);
    %color("red", 0.7) {
        multmatrix(M) translate([0, r_b, 0]) rotate([0, 0, -90])
            rotate_extrude(angle = 90) translate([r_b, 0]) circle(d = 3.5);
        translate([c_f, y_cable + r_b, c_f]) rotate([-90, 0, 0])
            cylinder(d = 3.5, h = y_tab + tab_len + 5 - (y_cable + r_b));
    }
    echo(str("Lead bend radius with these settings: ", r_b, " mm"));
}

// ---------------------------------------------------------------- output
if (part == "model") {
    corner_mount_lp();
    if (show_magnet) ghost();
} else {
    // front face on the bed, tabs pointing up. Only the pocket bottom is a bridge (20.6 mm).
    rotate([90, 0, 0]) corner_mount_lp();
}
