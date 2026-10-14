// =====================================================================
//  BR-20/15 electromagnet - CORNER MOUNT for campervan cabinet doors
// ---------------------------------------------------------------------
//  Sits in the inside corner between a vertical side panel and a
//  horizontal shelf/top panel. The magnet face points towards the door.
//  The cable slot points into the corner, so the lead bends 90 deg and
//  runs along the corner towards the back of the cabinet.
//
//  Coordinates (as installed):
//    X = away from the vertical wall      (wall is the plane X = 0)
//    Z = up from the shelf                (shelf is the plane Z = 0)
//    Y = into the cabinet                 (magnet face at Y = -face_protrusion)
//
//  The part is symmetric about the X=Z diagonal, so ONE part fits all
//  four corners of a door opening (just rotate it).
// =====================================================================

/* [Output] */
part = "print";          // ["model", "print"]  model = installed orientation, print = back face on bed
show_magnet = false;     // ghost magnet for preview (model view only)

/* [Magnet - BR-20/15] */
magnet_d = 20;           // body diameter
magnet_h = 15;           // body length
fit = 0.3;               // radial clearance of the pocket (0.2 snug .. 0.4 loose)
face_protrusion = 1;     // magnet face sticks out past the mount front by this much
rear_screw_d = 3.4;      // through hole for the M3 screw in the back of the magnet

/* [Cable] */
cable_d = 4;             // width of the cable slot (lead + heat shrink)

/* [Body] */
wall_t = 3;              // shell between magnet and the two panels (also outer shell)
back_t = 4;              // back plate thickness (M3 screw length = back_t + thread depth)

/* [Mounting flanges] */
flange_t = 3.5;          // flange thickness
flange_len = 14;         // how far each flange extends past the body
flange_round = 3;        // corner radius of the flange ends
wood_screw_d = 4.2;      // clearance hole for 3.5-4 mm wood screws
wood_screw_head_d = 8;   // countersink diameter

/* [Fillets] */
fillet_r = 3;            // inner corner radius where the flanges meet the body (0 = sharp, > 4 reaches the screw heads)

$fn = 96;

// ---------------------------------------------------------------- derived
R   = magnet_d / 2;
Rp  = R + fit;           // pocket radius
Ro  = Rp + wall_t;       // outer body radius
cx  = Ro;                // magnet centre (body tangent to wall and shelf)
cz  = Ro;
pocket_depth = magnet_h - face_protrusion;
depth = pocket_depth + back_t;             // total Y size
x_end = cx + Ro + flange_len;              // shelf flange end
z_end = cz + Ro + flange_len;              // wall flange end
eps = 0.01;

echo(str("Corner mount: ", x_end, " x ", z_end, " mm footprint, ", depth, " mm deep. ",
         "Rear M3 screw must be ", back_t, " mm + thread depth long."));

// ---------------------------------------------------------------- helpers
// Countersunk hole, head at origin, shank going down -Z through length l.
module csk_hole(d, head_d, l) {
    cone_h = (head_d - d) / 2;                       // 90 deg countersink
    translate([0, 0, -l - eps]) cylinder(d = d, h = l + 2 * eps);
    translate([0, 0, -cone_h]) cylinder(d1 = d, d2 = head_d, h = cone_h + eps);
    cylinder(d = head_d, h = 20);                    // clearance above the head
}

// ---------------------------------------------------------------- 2D profile (XZ plane)
// Body plus flange stubs (the full flanges are added in 3D below), with the
// inner corners between body and flanges rounded to fillet_r.
module body_profile() {
    stub = x_end - flange_round;                     // stays clear of the rounded flange ends
    offset(r = -fillet_r) offset(delta = fillet_r) union() {
        hull() {
            translate([cx, cz]) circle(r = Ro);
            square([cx, cz]);                        // fills the corner to the walls
        }
        square([stub, flange_t]);
        square([flange_t, stub]);
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
module body() {
    // profile is drawn in XZ; extrude along +Y
    rotate([90, 0, 0]) mirror([0, 0, 1])
        linear_extrude(depth) body_profile();
}

module shelf_flange() {                              // lies flat on the shelf, extends +X
    hull() {
        cube([x_end - flange_round, depth, flange_t]);
        for (y = [flange_round, depth - flange_round])
            translate([x_end - flange_round, y, 0]) cylinder(r = flange_round, h = flange_t);
    }
}

module wall_flange() {                               // lies flat on the wall, extends +Z
    hull() {
        cube([flange_t, depth, z_end - flange_round]);
        for (y = [flange_round, depth - flange_round])
            translate([0, y, z_end - flange_round]) rotate([0, 90, 0])
                cylinder(r = flange_round, h = flange_t);
    }
}

module pocket()      { rotate([-90, 0, 0]) translate([cx, -cz, -1]) cylinder(r = Rp, h = pocket_depth + 1); }
module rear_hole()   { rotate([-90, 0, 0]) translate([cx, -cz, -1]) cylinder(d = rear_screw_d, h = depth + 2); }
module cable_slot()  { rotate([90, 0, 0]) mirror([0, 0, 1]) translate([0, 0, -1]) linear_extrude(depth + 2) cable_slot_profile(); }

module corner_mount() {
    difference() {
        union() { body(); shelf_flange(); wall_flange(); }
        pocket();
        rear_hole();
        cable_slot();
        // shelf flange screw: head on top, screw goes down into the shelf
        translate([x_end - flange_len / 2, depth / 2, flange_t])
            csk_hole(wood_screw_d, wood_screw_head_d, flange_t);
        // wall flange screw: head on the room side, screw goes into the wall (-X)
        translate([flange_t, depth / 2, z_end - flange_len / 2]) rotate([0, 90, 0])
            csk_hole(wood_screw_d, wood_screw_head_d, flange_t);
    }
}

module ghost_magnet() {
    %color("silver", 0.5) rotate([-90, 0, 0])
        translate([cx, -cz, -face_protrusion]) cylinder(r = R, h = magnet_h);
    // lead stub towards the corner
    %color("red", 0.6) translate([cx, magnet_h - face_protrusion - 3.5, cz])
        rotate([0, -135, 0]) cylinder(d = 3.5, h = R + 6);
}

// ---------------------------------------------------------------- output
if (part == "model") {
    corner_mount();
    if (show_magnet) ghost_magnet();
} else {
    // back face down on the bed, pocket opening up: no supports needed
    translate([0, 0, depth]) rotate([-90, 0, 0]) corner_mount();
}
